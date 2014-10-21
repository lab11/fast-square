
#ifndef INCLUDED_FAST_SQUARE_PRF_ESTIMATOR_IMPL_H
#define INCLUDED_FAST_SQUARE_PRF_ESTIMATOR_IMPL_H

#include <fast_square/prf_estimator.h>
#include <fast_square/defines.h>
#include <gnuradio/fft/fft.h>
#include <queue>

namespace gr {
namespace fast_square {

class prf_estimator_impl : public prf_estimator
{
private:
	int d_fft_size;
	fft::fft_complex *d_fft;
	bool d_forward;
	bool d_shift;
	int d_counter;
	std::vector<float> d_window;
	void inSequenceMsg(pmt::pmt_t msg);
	std::queue<std::vector<std::vector<gr_complex> > > d_message_queue;
	float *d_abs_array;

	pmt::pmt_t d_key, d_me;

	std::vector<double> cand_freqs;
	std::vector<std::vector<int> > cand_peaks;

	void prfSearch_init();
	double prfSearch_fast(float *data_fft_abs);
	float calculateCenterFreqHarmonicNum(int step_num);
	
protected:

public:
	prf_estimator_impl(int fft_size, bool forward, const std::vector<float> &window, bool shift, int nthreads, const std::string &tag_name);
	~prf_estimator_impl();

	void set_nthreads(int n);
	int nthreads() const;
	bool set_window(const std::vector<float> &window);
  
	int work(int noutput_items,
			gr_vector_const_void_star &input_items,
			gr_vector_void_star &output_items);
};

} /* namespace fast_square */
} /* namespace gr */

#endif /* INCLUDED_FAST_SQUARE_PRF_ESTIMATOR_IMPL_H */
