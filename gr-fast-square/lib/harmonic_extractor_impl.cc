
#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include "harmonic_extractor_impl.h"
#include <gnuradio/io_signature.h>
#include <cstdio>
#include <string>
#include <fstream>

namespace gr {
namespace fast_square {

harmonic_extractor::sptr harmonic_extractor::make(){
	return gnuradio::get_initial_sptr
		(new harmonic_extractor_impl());
}

harmonic_extractor_impl::harmonic_extractor_impl(int fft_size)
	: sync_block("harmonic_extractor",
			io_signature::make(1, 1, sizeof(gr_complex)),
			io_signature::make(0, 1, sizeof(gr_complex))),
	d_fft_size(fft_size)
{
	harmonicExtraction_bjt_init();
}

harmonic_extractor_impl::~harmonic_extractor_impl(){
}

void harmonic_extractor_impl::harmonicExtraction_bjt_init(){
	//Initialize temporary harmonic_nums vector
	std::vector<float> harmonic_nums;
	for(float cur_harmonic_num = -1.0*NUM_HARMONICS_PRESENT/2+.5; cur_harmonic_num <= 1.0*NUM_HARMONICS_PRESENT/2-.5; cur_harmonic_num++)
		harmonic_nums.push_back(cur_harmonic_num);

	//d_sp_idx indexes the harmonics from the FFT once it's corrected for any frequency offsets
	d_sp_idxs.clear();
	for(int ii=0; ii < harmonic_nums.size(); ii++){
		int cur_sp_idx = round(1.0*d_fft_size*harmonic_nums[ii]*PRF/(SAMPLE_RATE/DECIM_FACTOR)) % fft_len;
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
}

void harmonic_extractor_impl::harmonicExtraction_bjt_fast(float prf_est){
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
		freq_offs.push_back(2.0*M_PI*((prf_est-PRF)*((START_LO_FREQ-IF_FREQ+STEP_FREQ*ii)/PRF)-TUNE_OFFSET)/(SAMPLE_RATE/DECIM_FACTOR));

	//Apply frequency offset to all the raw data


	//Take FFT and extract corresponding harmonics
	
}

int harmonic_extractor_impl::work(int noutput_items,
		gr_vector_const_void_star &input_items,
		gr_vector_void_star &output_items){

	const gr_complex *in = (const gr_complex *) input_items[0];
	gr_complex *out = (gr_complex *) output_items[0];
	int count=0;
	int out_count = 0;

	while(count < noutput_items){
	}   // while

	return noutput_items;
}

} /* namespace fast_square */
} /* namespace gr */
