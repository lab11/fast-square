
#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include "harmonic_extractor_impl.h"
#include <gnuradio/io_signature.h>
#include <volk/volk.h>
#include <cstdio>
#include <string>
#include <fstream>

namespace gr {
namespace fast_square {

harmonic_extractor::sptr harmonic_extractor::make(int fft_size, int nthreads, const std::string &prf_tag_name, const std::string &phasor_tag_name, const std::string &hfreq_abs_tag_name, const std::string &hfreq_tag_name){
	return gnuradio::get_initial_sptr
		(new harmonic_extractor_impl(fft_size, nthreads, prf_tag_name, phasor_tag_name, hfreq_abs_tag_name, hfreq_tag_name));
}

harmonic_extractor_impl::harmonic_extractor_impl(int fft_size, int nthreads, const std::string &prf_tag_name, const std::string &phasor_tag_name, const std::string &hfreq_abs_tag_name, const std::string &hfreq_tag_name)
	: sync_block("harmonic_extractor",
			io_signature::make(4, 4, POW2_CEIL(NUM_STEPS*FFT_SIZE)*sizeof(gr_complex)),
			io_signature::make(4, 4, POW2_CEIL(NUM_STEPS*FFT_SIZE)*sizeof(gr_complex))),
	d_fft_size(fft_size)
{
	d_prf_key = pmt::string_to_symbol(prf_tag_name);
	d_phasor_key = pmt::string_to_symbol(phasor_tag_name);
	d_hfreq_abs_key = pmt::string_to_symbol(hfreq_abs_tag_name);
	d_hfreq_key = pmt::string_to_symbol(hfreq_tag_name);

	std::stringstream id;
	id << name() << unique_id();
	d_me = pmt::string_to_symbol(id.str());

	d_fft = new fft::fft_complex(d_fft_size, true, nthreads);
	
	const int alignment_multiple =
		volk_get_alignment() / sizeof(gr_complex);
	set_alignment(std::max(1, alignment_multiple));
	harmonicExtraction_bjt_init();
}

harmonic_extractor_impl::~harmonic_extractor_impl(){
}

void harmonic_extractor_impl::harmonicExtraction_bjt_init(){
	//Initialize temporary harmonic_nums vector
	std::vector<float> harmonic_nums;
	for(float cur_harmonic_num = -1.0*NUM_HARMONICS_PER_STEP/2+.5; cur_harmonic_num <= 1.0*NUM_HARMONICS_PER_STEP/2-.5; cur_harmonic_num++)
		harmonic_nums.push_back(cur_harmonic_num);

	//d_sp_idx indexes the harmonics from the FFT once it's corrected for any frequency offsets
	d_sp_idxs.clear();
	for(int ii=0; ii < harmonic_nums.size(); ii++){
		int cur_sp_idx = (int)(round(1.0*FFT_SIZE*harmonic_nums[ii]*PRF/(SAMPLE_RATE/DECIM_FACTOR))) % FFT_SIZE;
		if(cur_sp_idx < 0)
			cur_sp_idx += FFT_SIZE;
		d_sp_idxs.push_back(cur_sp_idx);
	}

	//Also need to know the actual harmonic number at each frequency step in order to later determine frequency offset at each harmonic
	d_harmonic_nums_abs.resize(NUM_STEPS);
	for(int ii=0; ii < NUM_STEPS; ii++){
		d_harmonic_nums_abs[ii].clear();
		float center_freq_harmonic_num = calculateCenterFreqHarmonicNum(ii);
		for(int jj=0; jj < harmonic_nums.size(); jj++){
			int cur_harmonic_num = center_freq_harmonic_num+harmonic_nums[jj];
			d_harmonic_nums_abs[ii].push_back(cur_harmonic_num);
		}
	}

	//Initialize space to contain NCO data
	nco_array = new gr_complex[d_fft_size];

	//Set anything past FFT_SIZE to zero
	memset(d_fft->get_inbuf()+FFT_SIZE, 0, d_fft_size-FFT_SIZE);
}

float harmonic_extractor_impl::calculateCenterFreqHarmonicNum(int step_num){
	float ret;
	if(USE_IMAGE)
		ret = ((START_LO_FREQ-IF_FREQ+STEP_FREQ*step_num)/PRF);
	else
		ret = ((START_LO_FREQ+IF_FREQ+STEP_FREQ*step_num)/PRF);
	return ret;
}

void harmonic_extractor_impl::harmonicExtraction_bjt_fast(const gr_complex *data){
	//%Subtract any frequency offset including tune offset and prf-induced offset at each snapshot
	//if(use_image)
	//	freq_offs = 2*pi*((prf_est-prf)*((start_lo_freq-if_freq+step_freq*(0:num_steps-1))/prf)-tune_offset)/(sample_rate/decim_factor);
	//else
	//	freq_offs = 2*pi*((prf_est-prf)*((start_lo_freq+if_freq+step_freq*(0:num_steps-1))/prf)-tune_offset)/(sample_rate/decim_factor);
	//end
	//cur_iq_data = cur_iq_data.*exp(-1i*he_idxs(:,:,:,1).*repmat(freq_offs,[size(cur_iq_data,1),1,size(cur_iq_data,3)]));
	//
	//cur_iq_data_fft = fft(cur_iq_data,[],3);
	//square_phasors = cur_iq_data_fft(:,:,sp_idxs);
	//
	//harmonic_freqs = harmonic_nums_abs.*prf_est;

	//Initialize frequency offset array
	std::vector<float> freq_offs;
	for(int ii=0; ii < NUM_STEPS; ii++)
		freq_offs.push_back(2.0*M_PI*((d_prf_est-PRF)*((START_LO_FREQ-IF_FREQ+STEP_FREQ*ii)/PRF)-TUNE_OFFSET)/(SAMPLE_RATE/DECIM_FACTOR));

	d_harmonic_phasors.clear();
	d_harmonic_freqs_abs.clear();
	for(int ii=0; ii < NUM_STEPS; ii++){
		float center_freq_harmonic_num = calculateCenterFreqHarmonicNum(ii);

		//Apply frequency offset to all the raw data
		d_nco.set_freq(freq_offs[ii]);
		d_nco.sincos(nco_array, FFT_SIZE, 1.0);
		volk_32fc_x2_multiply_32fc(d_fft->get_inbuf(), nco_array, data, FFT_SIZE);
		
		//Take FFT and extract corresponding harmonics
		d_fft->execute();

		//Extract harmonics based on indices computed previously
		for(int jj=0; jj < d_sp_idxs.size(); jj++){
			d_harmonic_phasors.push_back(d_fft->get_outbuf()[d_sp_idxs[jj]]);
			d_harmonic_freqs_abs.push_back(d_harmonic_nums_abs[ii][jj]*d_prf_est);
			d_harmonic_freqs.push_back((d_harmonic_nums_abs[ii][jj]-center_freq_harmonic_num)*d_prf_est);
		}

		data += FFT_SIZE;
	}
}

int harmonic_extractor_impl::work(int noutput_items,
		gr_vector_const_void_star &input_items,
		gr_vector_void_star &output_items){


	std::vector<tag_t> tags;
	const gr_complex *in = (const gr_complex *) input_items[0];
	gr_complex *out = (gr_complex *) output_items[0];
	int count=0;
	int out_count = 0;

	const uint64_t nread = nitems_read(0);
	uint64_t abs_out_sample_cnt = nitems_written(0);

	while(count < noutput_items){
		//Extract PRF estimate from tag
		get_tags_in_range(tags, 0, nread+count, nread+count+1);
		for(unsigned ii=0; ii < tags.size(); ii++){
			if(tags[ii].key == d_prf_key)
				d_prf_est = (float)pmt::to_double(tags[ii].value);
		}

		//Run harmonic extraction logic
		harmonicExtraction_bjt_fast((const gr_complex *) input_items[count]);

		//Add new phasors and computed frequencies as tags to data stream
		add_item_tag(0,
			abs_out_sample_cnt + count,
			d_phasor_key,
			pmt::init_c32vector(d_harmonic_phasors.size(), &d_harmonic_phasors[0]),
			d_me
		);
		add_item_tag(0,
			abs_out_sample_cnt + count,
			d_hfreq_abs_key,
			pmt::init_f32vector(d_harmonic_freqs_abs.size(), &d_harmonic_freqs_abs[0]),
			d_me
		);
		add_item_tag(0,
			abs_out_sample_cnt + count,
			d_hfreq_key,
			pmt::init_f32vector(d_harmonic_freqs.size(), &d_harmonic_freqs[0]),
			d_me
		);

		count++;
	}   // while

	return noutput_items;
}

} /* namespace fast_square */
} /* namespace gr */
