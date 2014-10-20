
#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include "prf_estimator_impl.h"
#include <gnuradio/io_signature.h>
#include <volk/volk.h>
#include <cstdio>
#include <string>
#include <fstream>

namespace gr {
namespace fast_square {

prf_estimator::sptr prf_estimator::make(int prf_fft_size, bool forward, const std::vector<float> &window, bool shift, int nthreads, const std::string &tag_name){
	return gnuradio::get_initial_sptr
		(new prf_estimator_impl(prf_fft_size, forward, window, shift, nthreads, tag_name));
}

prf_estimator_impl::prf_estimator_impl(int prf_fft_size, bool forward, const std::vector<float> &window, bool shift, int nthreads, const std::string &tag_name)
	: sync_block("prf_estimator",
			io_signature::make(4, 4, POW2_CEIL(NUM_STEPS * FFT_SIZE) * sizeof(gr_complex)),
			io_signature::make(4, 4, POW2_CEIL(NUM_STEPS * FFT_SIZE) * sizeof(gr_complex))),
	d_fft_size(prf_fft_size), d_forward(forward), d_shift(shift)
{
	d_fft = new fft::fft_complex(d_fft_size, forward, nthreads);
	if(!set_window(window))
		throw std::runtime_error("fft_vcc: window not the same length as fft_size\n");

	d_abs_array = new float[d_fft_size*NUM_STEPS];
	prfSearch_init();

	std::stringstream str;
	str << name() << unique_id();
	d_me = pmt::string_to_symbol(str.str());
	d_key = pmt::string_to_symbol(tag_name);

	const int alignment_multiple =
		volk_get_alignment() / sizeof(float);
	set_alignment(std::max(1,alignment_multiple));
}

prf_estimator_impl::~prf_estimator_impl(){
	delete d_fft;
	delete d_abs_array;
}

void prf_estimator_impl::set_nthreads(int n){
	d_fft->set_nthreads(n);
}

int prf_estimator_impl::nthreads() const{
	return d_fft->nthreads();
}

bool prf_estimator_impl::set_window(const std::vector<float> &window){
	if(window.size()==0 || window.size()==d_fft_size) {
		d_window=window;
		return true;
	}
	else return false;
}

void prf_estimator_impl::prfSearch_init(){

	//Reset estimated freq and indexing arrays
	cand_peaks.clear();
	cand_freqs.clear();

	//Initialize freq array
	float cur_cand_freq = 1.0*PRF*(1-PRF_ACCURACY);
	while(cur_cand_freq <= 1.0*PRF*(1+PRF_ACCURACY)){
		cand_freqs.push_back(cur_cand_freq);
		cur_cand_freq += 1.0*PRF*COARSE_PRECISION;
	}

	//Initialize cand_peaks with appropriate indices based on each frequency
	std::vector<int> cur_peak_array;
	for(int ii=0; ii < cand_freqs.size(); ii++){
		cur_peak_array.clear();
		for(int jj=0; jj < NUM_STEPS; jj++){
			float center_freq_harmonic_num = calculateCenterFreqHarmonicNum(jj);
			for(float harmonic_num = -NUM_HARMONICS_PER_STEP/4+.5; harmonic_num <= NUM_HARMONICS_PER_STEP/4-.5; harmonic_num++){
				float cur_peak_idx = d_fft_size*(
						cand_freqs[ii]*harmonic_num+
						(cand_freqs[ii]-PRF)*center_freq_harmonic_num-
						TUNE_OFFSET
					)/(SAMPLE_RATE/DECIM_FACTOR);
				int cur_peak_idx_int = ((int)(round(cur_peak_idx)) % d_fft_size) + (jj*d_fft_size);
				cur_peak_array.push_back(cur_peak_idx_int);
			}
		}
		cand_peaks.push_back(cur_peak_array);
	}

	//Set anything past FFT_SIZE to zero
	memset(d_fft->get_inbuf()+FFT_SIZE, 0, d_fft_size-FFT_SIZE);

}

float prf_estimator_impl::calculateCenterFreqHarmonicNum(int step_num){
	float ret;
	if(USE_IMAGE)
		ret = ((START_LO_FREQ-IF_FREQ+STEP_FREQ*step_num)/PRF);
	else
		ret = ((START_LO_FREQ+IF_FREQ+STEP_FREQ*step_num)/PRF);
	return ret;
}

float prf_estimator_impl::prfSearch_fast(float *data_fft_abs){

	float max_prf_sum = 0.0;
	int max_prf_sum_idx = 0;
	for(int ii=0; ii < cand_peaks.size(); ii++){
		float cur_prf_sum = 0.0;
		for(int jj=0; jj < cand_peaks[ii].size(); jj++)
			cur_prf_sum += data_fft_abs[cand_peaks[ii][jj]];
		if(cur_prf_sum > max_prf_sum){
			max_prf_sum = cur_prf_sum;
			max_prf_sum_idx = ii;
		}
	}

	return cand_freqs[max_prf_sum_idx];
}

int prf_estimator_impl::work(int noutput_items,
		gr_vector_const_void_star &input_items,
		gr_vector_void_star &output_items){


	signed int input_data_size = FFT_SIZE*sizeof(gr_complex);
	signed int output_data_size = output_signature()->sizeof_stream_item (0);

	int count = 0;
	uint64_t abs_out_sample_cnt = nitems_written(0);

	//PRF estimation logic
	while(count < noutput_items) {
		for(int ii = 0; ii < NUM_STEPS; ii++){
			gr_complex *in = ((gr_complex *) input_items[PRF_EST_ANCHOR]) + ii*FFT_SIZE;
			// copy input into optimally aligned buffer
			if(d_window.size()) {
				gr_complex *dst = d_fft->get_inbuf();
				if(!d_forward && d_shift) {
					unsigned int offset = (!d_forward && d_shift)?(d_fft_size/2):0;
					int fft_m_offset = d_fft_size - offset;
					for(unsigned int i = 0; i < offset; i++)		// apply window
						dst[i+fft_m_offset] = in[i] * d_window[i];
					for(unsigned int i = offset; i < d_fft_size; i++)	// apply window
						dst[i-offset] = in[i] * d_window[i];
				} 
				else {
					for(unsigned int i = 0; i < d_fft_size; i++)		// apply window
						dst[i] = in[i] * d_window[i];
				}
			}
			else {
				if(!d_forward && d_shift) {  // apply an ifft shift on the data
					gr_complex *dst = d_fft->get_inbuf();
					unsigned int len = (unsigned int)(floor(d_fft_size/2.0)); // half length of complex array
					memcpy(&dst[0], &in[len], sizeof(gr_complex)*(d_fft_size - len));
					memcpy(&dst[d_fft_size - len], &in[0], sizeof(gr_complex)*len);
				}
				else {
					memcpy(d_fft->get_inbuf(), in, input_data_size);
				}
			}

			// compute the fft
			d_fft->execute();

			// turned out to be faster than aligned/unaligned switching
			volk_32fc_magnitude_32f_u(&d_abs_array[ii*d_fft_size], d_fft->get_outbuf(), d_fft_size);

			in  += FFT_SIZE;
		}

		//Perform PRF estimation
		float prf_est = prfSearch_fast(d_abs_array);

		std::cout << "lowest freq = " << cand_freqs[0] << " highest freq = " << cand_freqs[cand_freqs.size()-1] << " prf_est = " << prf_est << std::endl;
	
		//Attach tag to the data stream with the derived PRF estimate
		add_item_tag(0, //stream ID
			abs_out_sample_cnt + count, //sample
			d_key,      //frame info
			pmt::from_double((double)prf_est), //data (unused)
			d_me        //block src id
			);

		count++;
	}

	//Copy in to out since that's how you have to do things in GNU Radio...
	for(int ii=0; ii < output_items.size(); ii++){
		gr_complex *in = (gr_complex *) input_items[ii];
		gr_complex *out = (gr_complex *) output_items[ii];

		memcpy(out, in, output_data_size*noutput_items);
	}

	return noutput_items;
}

} /* namespace fast_square */
} /* namespace gr */
