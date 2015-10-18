
#ifndef INCLUDED_FAST_SQUARE_HARMONIC_LOCALIZER_IMPL_H
#define INCLUDED_FAST_SQUARE_HARMONIC_LOCALIZER_IMPL_H

#include <fast_square/harmonic_localizer.h>
#include <fast_square/defines.h>
#include <gnuradio/fft/fft.h>
#include <boost/asio.hpp>

namespace gr {
namespace fast_square {

typedef struct {
        double *toas;
	double *toa_errors;
        double *anchor_positions_x;
        double *anchor_positions_y;
        double *anchor_positions_z;
} my_function_data;


class harmonic_localizer_impl : public harmonic_localizer
{
private:
	fft::fft_complex *d_fft;
	pmt::pmt_t d_phasor_key, d_hfreq_key, d_prf_key;
	std::vector<gr_complex> d_harmonic_phasors;
	std::vector<double> d_harmonic_freqs;
	std::vector<std::vector<float> > d_poss_steps;
	std::vector<std::vector<double> > d_anchor_pos;
	std::vector<float> d_harmonic_freqs_f;
	std::vector<float> d_time_delay_in_samples;
	std::vector<float> d_fft_window;
	std::vector<double> d_toa_errors;
	std::vector<gr_complex> d_actual_fft;
	float d_prf_est;
	int d_abs_count;
	gr_complex d_i;
	std::string d_gatd_id;
	clock_t d_start_time;
	my_function_data d_objective_data;

	void readToAErrors();
	void readActualFFT();
	std::vector<float> tdoa4(std::vector<double> toas);
	std::vector<float> tdoa_newton(my_function_data &objective_data);
	std::vector<float> tdoa4_slow(std::vector<double> &toas);
	void genFFTWindow();
	gr_complex polyval(std::vector<float> &p, gr_complex x);
	std::vector<gr_complex> freqz(std::vector<float> &b, std::vector<float> &a, std::vector<float> &w);
	std::vector<gr_complex> freqs(std::vector<float> &b, std::vector<float> &a, std::vector<float> &w);
	std::vector<int> extractToAs(std::vector<gr_complex> hp_rearranged, float *imp_thresholds);
	void sendToGATD(std::vector<float> &positions);
	void sendRawSingle(std::vector<float> &position);
	void correctCOMBPhase();
	void compensateRCLP();
	void compensateRCHP();
	void compensateStepTime();
	void harmonicLocalization();

protected:

public:
	harmonic_localizer_impl(const std::string &phasor_tag_name, const std::string &hfreq_tag_name, const std::string &prf_tag_name, const std::string &gatd_id, int nthreads);
	~harmonic_localizer_impl();

	int work(int noutput_items,
			gr_vector_const_void_star &input_items,
			gr_vector_void_star &output_items);
};

} /* namespace fast_square */
} /* namespace gr */

#endif /* INCLUDED_FAST_SQUARE_HARMONIC_LOCALIZER_IMPL_H */
