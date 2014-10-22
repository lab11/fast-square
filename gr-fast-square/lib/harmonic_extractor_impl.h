
#ifndef INCLUDED_FAST_SQUARE_HARMONIC_EXTRACTOR_IMPL_H
#define INCLUDED_FAST_SQUARE_HARMONIC_EXTRACTOR_IMPL_H

#include <fast_square/harmonic_extractor.h>
#include <fast_square/defines.h>
#include <gnuradio/fft/fft.h>
#include <gnuradio/fxpt_nco.h>

namespace gr {
namespace fast_square {

class harmonic_extractor_impl : public harmonic_extractor
{
private:
	fft::fft_complex *d_fft;
	int d_fft_size;
	int d_abs_count;
	std::vector<float> d_freq_offs;
	std::vector<int> d_sp_idxs;
	std::vector<std::vector<int> > d_harmonic_nums_abs;
	std::vector<gr_complex> d_harmonic_phasors;
	std::vector<float> d_harmonic_freqs_abs;
	std::vector<float> d_harmonic_freqs;
	pmt::pmt_t d_prf_key, d_phasor_key, d_hfreq_key, d_hfreq_abs_key, d_me;
	double d_prf_est;

	gr::fxpt_nco d_nco;
	gr_complex *nco_array;

	void harmonicExtraction_bjt_init();
	void harmonicExtraction_bjt_reset();
	void harmonicExtraction_bjt_fast(const gr_complex *data);
	float calculateCenterFreqHarmonicNum(int step_num);

protected:

public:
	harmonic_extractor_impl(int fft_size, int nthreads, const std::string &prf_tag_name, const std::string &phasor_tag_name, const std::string &hfreq_abs_tag_name, const std::string &hfreq_tag_name);
	~harmonic_extractor_impl();

	int work(int noutput_items,
			gr_vector_const_void_star &input_items,
			gr_vector_void_star &output_items);
};

} /* namespace fast_square */
} /* namespace gr */

#endif /* INCLUDED_FAST_SQUARE_HARMONIC_EXTRACTOR_IMPL_H */
