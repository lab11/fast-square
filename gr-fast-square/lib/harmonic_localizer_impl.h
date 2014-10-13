
#ifndef INCLUDED_FAST_SQUARE_HARMONIC_LOCALIZER_IMPL_H
#define INCLUDED_FAST_SQUARE_HARMONIC_LOCALIZER_IMPL_H

#include <fast_square/harmonic_localizer.h>

namespace gr {
namespace fast_square {

class harmonic_localizer_impl : public harmonic_localizer
{
private:
	fft_complex *d_fft;
	pmt::pmt_t d_phasor_key, d_hfreq_key;
	std::vector<gr_complex> d_harmonic_phasors;
	std::vector<float> d_harmonic_freqs;
	std::vector<float> d_time_delay_in_samples;
	std::vector<float> d_fft_window;
	gr_complex d_i;

	void genFFTWindow();
	gr_complex polyval(std::vector<gr_complex> &p, gr_complex x);
	std::vector<gr_complex> freqz(std::vector<gr_complex> &b, std::vector<gr_complex> &a, std::vector<float> &w);
	std::vector<gr_complex> freqs(std::vector<gr_complex> &b, std::vector<gr_complex> &a, std::vector<float> &w);
	std::vector<int> extractToAs(std::vector<gr_complex> hp_rearranged, float *imp_thresholds);
	void correctCOMBPhase();
	void compensateRCLP();
	void compensateRCHP();
	void compensateStepTime();
	void harmonicLocalization();

protected:

public:
	harmonic_localizer_impl(const std::string &phasor_tag_name, const std::string &hfreq_tag_name, int nthreads);
	~harmonic_localizer_impl();

	int work(int noutput_items,
			gr_vector_const_void_star &input_items,
			gr_vector_void_star &output_items);
};

} /* namespace fast_square */
} /* namespace gr */

#endif /* INCLUDED_FAST_SQUARE_HARMONIC_LOCALIZER_IMPL_H */
