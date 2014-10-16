
#ifndef INCLUDED_FAST_SQUARE_HARMONIC_LOCALIZER_IMPL_H
#define INCLUDED_FAST_SQUARE_HARMONIC_LOCALIZER_IMPL_H

#include <fast_square/harmonic_localizer.h>
#include <fast_square/defines.h>
#include <gnuradio/fft/fft.h>
#include <boost/asio.hpp>

namespace gr {
namespace fast_square {

class harmonic_localizer_impl : public harmonic_localizer
{
private:
	fft::fft_complex *d_fft;
	pmt::pmt_t d_phasor_key, d_hfreq_key, d_hfreq_abs_key, d_prf_key;
	std::vector<gr_complex> d_harmonic_phasors;
	std::vector<float> d_harmonic_freqs;
	std::vector<float> d_harmonic_abs_freqs;
	std::vector<float> d_time_delay_in_samples;
	std::vector<float> d_fft_window;
	std::vector<gr_complex> d_actual_fft;
	float d_prf_est;
	gr_complex d_i;
	std::string d_gatd_id;

	//UDP stuff
	bool   d_connected;       // are we connected?
	gr::thread::mutex  d_mutex;    // protects d_socket and d_connected
	
	boost::asio::ip::udp::socket *d_socket;          // handle to socket
	boost::asio::ip::udp::endpoint d_endpoint;
	boost::asio::io_service d_io_service;

	void readActualFFT();
	std::vector<float> tdoa4(std::vector<float> toas);
	void genFFTWindow();
	gr_complex polyval(std::vector<float> &p, gr_complex x);
	std::vector<gr_complex> freqz(std::vector<float> &b, std::vector<float> &a, std::vector<float> &w);
	std::vector<gr_complex> freqs(std::vector<float> &b, std::vector<float> &a, std::vector<float> &w);
	std::vector<int> extractToAs(std::vector<gr_complex> hp_rearranged, float *imp_thresholds);
	void correctCOMBPhase();
	void compensateRCLP();
	void compensateRCHP();
	void compensateStepTime();
	void harmonicLocalization();

protected:

public:
	harmonic_localizer_impl(const std::string &phasor_tag_name, const std::string &hfreq_abs_tag_name, const std::string &hfreq_tag_name, const std::string &prf_tag_name, const std::string &gatd_host, int gatd_port, const std::string &gatd_id, int nthreads);
	~harmonic_localizer_impl();

	void gatd_connect(const std::string &host, int port);
	void gatd_disconnect();

	int work(int noutput_items,
			gr_vector_const_void_star &input_items,
			gr_vector_void_star &output_items);
};

} /* namespace fast_square */
} /* namespace gr */

#endif /* INCLUDED_FAST_SQUARE_HARMONIC_LOCALIZER_IMPL_H */
