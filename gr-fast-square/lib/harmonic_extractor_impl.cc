
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

harmonic_extractor::sptr harmonic_extractor::make(int fft_size, int nthreads, const std::string &prf_tag_name, const std::string &phasor_tag_name, const std::string &hfreq_tag_name, const std::string &seq_num_tag_name){
	return gnuradio::get_initial_sptr
		(new harmonic_extractor_impl(fft_size, nthreads, prf_tag_name, phasor_tag_name, hfreq_tag_name, seq_num_tag_name));
}

harmonic_extractor_impl::harmonic_extractor_impl(int fft_size, int nthreads, const std::string &prf_tag_name, const std::string &phasor_tag_name, const std::string &hfreq_tag_name, const std::string &seq_num_tag_name)
	: sync_block("harmonic_extractor",
			io_signature::make(4, 4, POW2_CEIL(NUM_STEPS*FFT_SIZE)*sizeof(gr_complex)),
			io_signature::make(4, 4, POW2_CEIL(NUM_STEPS*FFT_SIZE)*sizeof(gr_complex))),
	d_fft_size(fft_size), d_abs_count(0)
{
	d_prf_key = pmt::string_to_symbol(prf_tag_name);
	d_phasor_key = pmt::string_to_symbol(phasor_tag_name);
	d_hfreq_key = pmt::string_to_symbol(hfreq_tag_name);
	d_seq_num_key = pmt::string_to_symbol(seq_num_tag_name);

	std::stringstream id;
	id << name() << unique_id();
	d_me = pmt::string_to_symbol(id.str());

	const int alignment_multiple =
		volk_get_alignment() / sizeof(gr_complex);
	set_alignment(std::max(1, alignment_multiple));
	harmonicExtraction_bjt_init();
}

harmonic_extractor_impl::~harmonic_extractor_impl(){
}

void harmonic_extractor_impl::harmonicExtraction_bjt_init(){
	//Initialize temporary d_harmonic_nums vector
	d_harmonic_nums.clear();
	for(float cur_harmonic_num = -1.0*NUM_HARMONICS_PER_STEP/2+.5; cur_harmonic_num <= 1.0*NUM_HARMONICS_PER_STEP/2-.5; cur_harmonic_num++){
		d_harmonic_nums.push_back(cur_harmonic_num);
	}

	//Initialize space to contain NCO data
	nco_array = new gr_complex[d_fft_size];

	//recreate harmonic mixing arrays depending on prf estimate
	d_harm_mix.clear();
	for(int ii=0; ii < d_harmonic_nums.size(); ii++){
		gr_complex *new_harm_mix = new gr_complex[FFT_SIZE];
		d_harm_mix.push_back(new_harm_mix);
	}
}

float harmonic_extractor_impl::calculateCenterFreqHarmonicNum(int step_num){
	float ret;
	if(USE_IMAGE)
		ret = ((START_LO_FREQ-IF_FREQ+STEP_FREQ*step_num)/PRF);
	else
		ret = ((START_LO_FREQ+IF_FREQ+STEP_FREQ*step_num)/PRF);
	return ret;
}

void harmonic_extractor_impl::harmonicExtraction_bjt_reset(){
	//Initialize frequency offset array
	d_freq_offs.clear();
	for(int ii=0; ii < NUM_STEPS; ii++)
		d_freq_offs.push_back(-2.0l*M_PI*((d_prf_est-PRF)*calculateCenterFreqHarmonicNum(ii)-TUNE_OFFSET)/(SAMPLE_RATE/DECIM_FACTOR));

	d_harmonic_phasors.clear();
	d_harmonic_freqs.clear();

	//recreate harmonic mixing arrays depending on prf estimate
	for(int ii=0; ii < d_harmonic_nums.size(); ii++){
		d_nco.set_freq(-2.0l*M_PI*d_harmonic_nums[ii]*d_prf_est/(SAMPLE_RATE/DECIM_FACTOR));
		d_nco.set_phase(0.0);
		d_nco.sincos(d_harm_mix[ii], FFT_SIZE, 1.0);
		//gr_complex_d d_i(0.0, 1.0);
		//double freq = -2.0l*M_PI*d_harmonic_nums[ii]*d_prf_est/(SAMPLE_RATE/DECIM_FACTOR);
		//for(int jj=0; jj < FFT_SIZE; jj++){
		//	d_harm_mix[ii][jj] = std::exp(d_i*gr_complex_d(freq*jj, 0.0));
		//}
	}

	//Prepare the harmonic frequency array from the received PRF estimate
	for(int ii=0; ii < NUM_STEPS; ii++){
		float center_freq_harmonic_num = calculateCenterFreqHarmonicNum(ii);
		for(int jj=0; jj < d_harmonic_nums.size(); jj++){
			//d_harmonic_freqs_abs.push_back(d_prf_est*d_harmonic_nums_abs[ii][jj]);
			double harmonic_freq = (d_prf_est*d_harmonic_nums[jj] + 
					(d_prf_est-PRF)*center_freq_harmonic_num - 
					TUNE_OFFSET);
			d_harmonic_freqs.push_back(harmonic_freq);//(d_harmonic_nums_abs[ii][jj]-center_freq_harmonic_num)*d_prf_est);
		}
	}

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

	gr_complex data_step_pre[FFT_SIZE];
	gr_complex data_step_post[FFT_SIZE];
	for(int ii=0; ii < NUM_STEPS; ii++){
		float center_freq_harmonic_num = calculateCenterFreqHarmonicNum(ii);

		//Apply frequency offset to all the raw data
		d_nco.set_freq(d_freq_offs[ii]);
		d_nco.set_phase(0.0);
		d_nco.sincos(nco_array, FFT_SIZE, 1.0);
		volk_32fc_x2_multiply_32fc(data_step_pre, nco_array, data+ii*FFT_SIZE, FFT_SIZE);

		//Calculate phasors through brute-force approach since FFT bins aren't close enough to where they should be
		for(int jj=0; jj < d_harmonic_nums.size(); jj++){
			volk_32fc_x2_multiply_32fc(data_step_post, d_harm_mix[jj], data_step_pre, FFT_SIZE);

			//Sum everything up to get resulting phasor
			gr_complex_d cur_phasor(0.0, 0.0);
			for(int kk=0; kk < FFT_SIZE; kk++){
				cur_phasor += data_step_post[kk];
			}
			d_harmonic_phasors.push_back(gr_complex(cur_phasor));
		}
		
	}
}

int harmonic_extractor_impl::work(int noutput_items,
		gr_vector_const_void_star &input_items,
		gr_vector_void_star &output_items){


	signed int input_data_size_padded = input_signature()->sizeof_stream_item(0)/sizeof(gr_complex);
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
				d_prf_est = pmt::to_double(tags[ii].value);
			if(tags[ii].key == d_seq_num_key)
				d_seq_num = (uint32_t)pmt::to_uint64(tags[ii].value);
		}

		//Run harmonic extraction logic
		harmonicExtraction_bjt_reset();
		for(int ii=0; ii < input_items.size(); ii++)
			harmonicExtraction_bjt_fast(((const gr_complex *) input_items[ii]) + count*input_data_size_padded);

		////DEBUG
		//if(d_seq_num == 15){
		//	std::cout << "start " << std::endl;
		//	//gr_complex *data = ((gr_complex *)input_items[0]) + count*input_data_size_padded;
		//	//for(int jj=0; jj < NUM_STEPS*FFT_SIZE; jj++)
		//	//	std::cout << data[jj].real()*32767 << " " << data[jj].imag()*32767 << std::endl;
		//	//printf("%0.15f\n", d_prf_est);
		//	std::cout << "start len = " << d_harmonic_freqs.size() << std::endl;
		//	for(int jj=0; jj < d_harmonic_phasors.size(); jj++){
		//		std::cout << d_harmonic_phasors[jj].real() << " " << d_harmonic_phasors[jj].imag() << std::endl;//printf("%0.15f", d_harmonic_freqs[jj]);
		//	}
		//}


		//Add new phasors and computed frequencies as tags to data stream
		add_item_tag(0,
			abs_out_sample_cnt + count,
			d_phasor_key,
			pmt::init_c32vector(d_harmonic_phasors.size(), &d_harmonic_phasors[0]),
			d_me
		);
		add_item_tag(0,
			abs_out_sample_cnt + count,
			d_hfreq_key,
			pmt::init_f64vector(d_harmonic_freqs.size(), &d_harmonic_freqs[0]),
			d_me
		);

		d_abs_count++;
		count++;
	}   // while

	return noutput_items;
}

} /* namespace fast_square */
} /* namespace gr */
