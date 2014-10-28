
#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include "harmonic_localizer_impl.h"
#include <gnuradio/io_signature.h>
#include <volk/volk.h>
#include <cstdio>
#include <string>
#include <fstream>

namespace gr {
namespace fast_square {

harmonic_localizer::sptr harmonic_localizer::make(const std::string &phasor_tag_name, const std::string &hfreq_tag_name, const std::string &prf_tag_name, const std::string &gatd_id, int nthreads){
	return gnuradio::get_initial_sptr
		(new harmonic_localizer_impl(phasor_tag_name, hfreq_tag_name, prf_tag_name, gatd_id, nthreads));
}

harmonic_localizer_impl::harmonic_localizer_impl(const std::string &phasor_tag_name, const std::string &hfreq_tag_name, const std::string &prf_tag_name, const std::string &gatd_id, int nthreads)
	: sync_block("harmonic_localizer",
			io_signature::make(4, 4, POW2_CEIL(NUM_STEPS*FFT_SIZE)*sizeof(gr_complex)),
			io_signature::make(0, 0, 0)),
	d_gatd_id(gatd_id), d_abs_count(0)
{
	d_phasor_key = pmt::string_to_symbol(phasor_tag_name);
	d_hfreq_key = pmt::string_to_symbol(hfreq_tag_name);
	d_prf_key = pmt::string_to_symbol(prf_tag_name);
	
	d_i = gr_complex(0, 1);

	readActualFFT();
	readToAErrors();

	//Pre-calculated vector generated for compensateStepTime step
	for(int ii=0; ii < NUM_ANCHORS * NUM_STEPS * NUM_HARMONICS_PER_STEP; ii++){
		d_time_delay_in_samples.push_back(((ii/NUM_HARMONICS_PER_STEP) % NUM_STEPS)*SAMPLES_PER_FREQ);
	}

	//Pre-compute hamming window for later use in super-resolution generation of impulse response plots
	genFFTWindow();

	d_fft = new fft::fft_complex(FFT_SIZE_POST*INTERP, true, nthreads);
	memset(d_fft->get_inbuf(), 0, FFT_SIZE_POST*INTERP*sizeof(gr_complex));
	
	const int alignment_multiple =
		volk_get_alignment() / sizeof(gr_complex);
	set_alignment(std::max(1, alignment_multiple));

	//Message port for UDP to GATD
	message_port_register_out(pmt::mp("frame_out"));

	//Populate antenna array
	float ax[4] = {2.405, 2.105, 4.108, 0.273};
	float ay[4] = {3.815, 0.034, 0.347, 0.343};
	float az[4] = {2.992, 2.494, 1.543, 1.560};
	d_anchor_pos.clear();
	std::vector<float> cur_anchor_pos(3);
	for(int ii=0; ii < 4; ii++){
		cur_anchor_pos[0] = ax[ii];
		cur_anchor_pos[1] = ay[ii];
		cur_anchor_pos[2] = az[ii];
		d_anchor_pos.push_back(cur_anchor_pos);
	}
	float poss_steps[81] = {-0.0100, -0.0100, -0.0100, -0.0100, -0.0100, 0, -0.0100, -0.0100, 0.0100, -0.0100, 0, -0.0100, -0.0100, 0, 0, -0.0100, 0, 0.0100, -0.0100, 0.0100, -0.0100, -0.0100, 0.0100, 0, -0.0100, 0.0100, 0.0100, 0, -0.0100, -0.0100, 0, -0.0100, 0, 0, -0.0100, 0.0100, 0, 0, -0.0100, 0, 0, 0, 0, 0, 0.0100, 0, 0.0100, -0.0100, 0, 0.0100, 0, 0, 0.0100, 0.0100, 0.0100, -0.0100, -0.0100, 0.0100, -0.0100, 0, 0.0100, -0.0100, 0.0100, 0.0100, 0, -0.0100, 0.0100, 0, 0, 0.0100, 0, 0.0100, 0.0100, 0.0100, -0.0100, 0.0100, 0.0100, 0, 0.0100, 0.0100, 0.0100};
	d_poss_steps.clear();
	std::vector<float> cur_poss_steps(3);
	for(int ii=0; ii < 27; ii++){
		cur_poss_steps[0] = poss_steps[ii*3+0];
		cur_poss_steps[1] = poss_steps[ii*3+1];
		cur_poss_steps[2] = poss_steps[ii*3+2];
		d_poss_steps.push_back(cur_poss_steps);
	}
}

harmonic_localizer_impl::~harmonic_localizer_impl(){
}

void harmonic_localizer_impl::readActualFFT(){
	//Open file for reading
	FILE *source = fopen("tx_phasors.dat", "r");
		
	//Read complex numbers in one at a time
	for(int ii=0; ii < NUM_ANCHORS*NUM_STEPS*NUM_HARM_PER_STEP_POST; ii++){
		float real, imag;
		fread((void*)(&real), sizeof(real), 1, source);
		fread((void*)(&imag), sizeof(imag), 1, source);
		gr_complex cur_phasor(real, imag);
		d_actual_fft.push_back(cur_phasor);
	}
	
	//Close file
	fclose(source);
}

void harmonic_localizer_impl::readToAErrors(){
	//MATLAB code to generate measured_toa_errors.dat
	//load temp.txt
	//	measured_toa_errors = zeros(length(temp),4);
	//for ii=1:length(temp)
	//	measured_toas = (temp(ii,:)).'/(prf_est*size(square_phasors_reshaped,2))/INTERP*3e8;
	//measured_toa_errors(ii,:) = calculateAnchorErrors(anchor_positions, res.toa_cal_location, measured_toas);
	//end
	//measured_toa_errors = median(measured_toa_errors,1)*(prf_est*size(square_phasors_reshaped,2))*INTERP/3e8;

	//Open file for reading
	FILE *source = fopen("measured_toa_errors.dat", "r");
		
	//Read complex numbers in one at a time
	for(int ii=0; ii < NUM_ANCHORS*NUM_STEPS*NUM_HARM_PER_STEP_POST; ii++){
		int cur_toa_error;
		fread((void*)(&cur_toa_error), sizeof(cur_toa_error), 1, source);
		d_toa_errors.push_back(cur_toa_error);
	}
	
	//Close file
	fclose(source);

}

std::vector<float> harmonic_localizer_impl::tdoa4_slow(std::vector<double> &toas){
	for(int ii=toas.size()-1; ii >= 0; ii--)
		toas[ii] -= toas[0];

	bool new_est = true;
	std::vector<float> est_position(3,0.0);
	std::vector<float> cand_position(3, 0.0);
	std::vector<float> cand_dist(toas.size(), 0.0);
	float best_error = INFINITY;
	while(new_est){
		float cur_best_error = best_error;
		int cur_best_error_idx = 0;
		for(int jj=0; jj < d_poss_steps.size(); jj++){
			for(int kk=0; kk < est_position.size(); kk++)
				cand_position[kk] = est_position[kk] + d_poss_steps[jj][kk];
			for(int ll=0; ll < d_anchor_pos.size(); ll++){
				float anchor_dist = 0.0;
				for(int kk=0; kk < est_position.size(); kk++){
					float sub_dist = d_anchor_pos[ll][kk]-cand_position[kk];
					anchor_dist += sub_dist*sub_dist;
				}
				if(ll > 0)
					cand_dist[ll] = sqrt(anchor_dist) - cand_dist[0];
				else
					cand_dist[ll] = sqrt(anchor_dist);
			}
			float error = 0.0;
			for(int kk=1; kk < d_anchor_pos.size(); kk++){
				float cur_error = cand_dist[kk]-toas[kk];
				error += cur_error*cur_error;
			}
			if(error < cur_best_error){
				cur_best_error = error;
				cur_best_error_idx = jj;
			}
		}

		if(cur_best_error < best_error){
			best_error = cur_best_error;
			for(int kk=0; kk < est_position.size(); kk++)
				est_position[kk] = est_position[kk] + d_poss_steps[cur_best_error_idx][kk];
			new_est = true;
		} else {
			new_est = false;
		}

		//Check to make sure we don't go too far
		float mag = 0.0;
		for(int ii=0; ii < est_position.size(); ii++)
			mag += est_position[ii]*est_position[ii];
		if(mag > 100.0){
			for(int ii=0; ii < est_position.size(); ii++)
				est_position[ii] = 0.0;
			break;
		}
	}

	return est_position;
}

std::vector<float> harmonic_localizer_impl::tdoa4(std::vector<double> toas){

	//double ti=67335898; double tk=86023981; double tj=78283279;  double tl=75092320;
	//double xi=0;        double xk=0;        double xj=-15338349; double xl=-18785564;
	//double yi=26566800; double yk=6380000;  double yj=15338349;  double yl=18785564;
	//double zi=0;        double zk=25789348; double zj=15338349;  double zl=0;
	//
	//cout<<"ti = "<<ti<<endl;  cout<<"tj = "<<tj<<endl;  cout<<"tk = "<<tk<<endl;
	//cout<<"tl = "<<tl<<endl;  cout<<"xi = "<<xi<<endl;  cout<<"xj = "<<xj<<endl;
	//cout<<"xk = "<<xk<<endl;  cout<<"xl = "<<xl<<endl;  cout<<"yi = "<<yi<<endl;
	//cout<<"yj = "<<yj<<endl;  cout<<"yk = "<<yk<<endl;  cout<<"yl = "<<yl<<endl;
	//cout<<"zi = "<<zi<<endl;  cout<<"zj = "<<zj<<endl;  cout<<"zk = "<<zk<<endl;
	//cout<<"zl = "<<zl<<endl;

	static double ax[4] = {2.405, 2.105, 4.108, 0.273};
	static double ay[4] = {3.815, 0.034, 0.347, 0.343};
	static double az[4] = {2.992, 2.494, 1.543, 1.560};
	
	double xji=ax[1]-ax[0]; double xki=ax[2]-ax[0]; double xjk=ax[1]-ax[2]; double xlk=ax[3]-ax[2];
	double xik=ax[0]-ax[2]; double yji=ay[1]-ay[0]; double yki=ay[2]-ay[0]; double yjk=ay[1]-ay[2];
	double ylk=ay[3]-ay[2]; double yik=ay[0]-ay[2]; double zji=az[1]-az[0]; double zki=az[2]-az[0];
	double zik=az[0]-az[2]; double zjk=az[1]-az[2]; double zlk=az[3]-az[2];
	
	double rij=fabs((100000.0l*(toas[0]-toas[1]))/333564); double rik=fabs((100000.0l*(toas[0]-toas[2]))/333564);
	double rkj=fabs((100000.0l*(toas[2]-toas[1]))/333564); double rkl=fabs((100000.0l*(toas[2]-toas[3]))/333564);

	//if(d_abs_count == 9){
	//	std::cout << xji << " " << xki << " " << xjk << " " << xlk << std::endl;
	//	std::cout << xik << " " << yji << " " << yki << " " << yjk << std::endl;
	//	std::cout << ylk << " " << yik << " " << zji << " " << zki << std::endl;
	//	std::cout << zik << " " << zjk << " " << zlk << std::endl;
	//	std::cout << rij << " " << rik << " " << rkj << " " << rkl << std::endl;
	//}
	
	double s9 =rik*xji-rij*xki; double s10=rij*yki-rik*yji; double s11=rik*zji-rij*zki;
	double s12=(rik*(rij*rij + ax[0]*ax[0] - ax[1]*ax[1] + ay[0]*ay[0] - ay[1]*ay[1] + az[0]*az[0] - az[1]*az[1])
	           -rij*(rik*rik + ax[0]*ax[0] - ax[2]*ax[2] + ay[0]*ay[0] - ay[2]*ay[2] + az[0]*az[0] - az[2]*az[2]))/2;
	
	double s13=rkl*xjk-rkj*xlk; double s14=rkj*ylk-rkl*yjk; double s15=rkl*zjk-rkj*zlk;
	double s16=(rkl*(rkj*rkj + ax[2]*ax[2] - ax[1]*ax[1] + ay[2]*ay[2] - ay[1]*ay[1] + az[2]*az[2] - az[1]*az[1])
	           -rkj*(rkl*rkl + ax[2]*ax[2] - ax[3]*ax[3] + ay[2]*ay[2] - ay[3]*ay[3] + az[2]*az[2] - az[3]*az[3]))/2;
	
	double a= s9/s10; double b=s11/s10; double c=s12/s10; double d=s13/s14;
	double e=s15/s14; double f=s16/s14; double g=(e-b)/(a-d); double h=(f-c)/(a-d);
	double i=(a*g)+b; double j=(a*h)+c;
	double k=rik*rik+ax[0]*ax[0]-ax[2]*ax[2]+ay[0]*ay[0]-ay[2]*ay[2]+az[0]*az[0]-az[2]*az[2]+2*h*xki+2*j*yki;
	double l=2*(g*xki+i*yki+zki);
	double m=4*rik*rik*(g*g+i*i+1)-l*l;
	double n=8*rik*rik*(g*(ax[0]-h)+i*(ay[0]-j)+az[0])+2*l*k;
	double o=4*rik*rik*((ax[0]-h)*(ax[0]-h)+(ay[0]-j)*(ay[0]-j)+az[0]*az[0])-k*k;
	double s28=n/(2*m);     double s29=(o/m);       double s30=(s28*s28)-s29;
	double root=sqrt(s30);

	if(d_abs_count == 1374){
		std::cout << xji << " " << xki << " " << xjk << " " << xlk << " " << xik << " " << yji << " " << yki << " " << yjk << " " << ylk << " " << yik << " " << zji << " " << zki << " " << zik << " " << zjk << " " << zlk << std::endl;
		std::cout << a << " " << b << " " << c << " " << d << " " << e << " " << f << " " << g << " " << h << " " << i << " " << j << " " << k << " " << l << " " << m << " " << n << " " << o << " " << s28 << " " << s29 << " " << s30 << " " << root << " " << s9 << " " << s10 << " " << s11 << " " << s12 << " " << s13 << " " << s14 << " " << s15 << " " << s16 << " " << rij << " " << rik << " " << rkj << " " << rkl << " " << s30 << " " << root << std::endl;
	}
	double z1=s28+root;
	double z2=s28-root;
	double x1=g*z1+h;
	double x2=g*z2+h;
	double y1=a*x1+b*z1+c;
	double y2=a*x2+b*z2+c;

	std::vector<float> ret;
	ret.push_back(x1);
	ret.push_back(y1);
	ret.push_back(z1);
	ret.push_back(x2);
	ret.push_back(y2);
	ret.push_back(z2);

	return ret;
}

void harmonic_localizer_impl::sendToGATD(std::vector<float> &positions){

	//std::cout << "positions" << std::endl;
	//for(int ii=0; ii < positions.size(); ii++)
	//	std::cout << positions[ii] << std::endl;

	//Construct outgoing packet
	//TODO: These magic numbers are kind of ugly...
	uint8_t outgoing_packet[10+24]; //24 = 6*4
	memcpy(&outgoing_packet[0], &d_gatd_id[0], d_gatd_id.size());
	memcpy(&outgoing_packet[10], &positions[0], positions.size()*sizeof(float));

	//Push to GATD
	pmt::pmt_t value = pmt::init_u8vector(34, outgoing_packet);
	pmt::pmt_t new_message = pmt::cons(pmt::PMT_NIL, value);
	message_port_pub(pmt::mp("frame_out"), new_message);
}

void harmonic_localizer_impl::genFFTWindow(){
	//For now, the FFT window will be a Hamming window
	float alpha = 0.54;
	float beta = 1.0-alpha;
	for(int ii=0; ii < FFT_SIZE_POST; ii++){
		float cur_window_val = alpha - beta*std::cos(2*M_PI*ii/(FFT_SIZE_POST-1));
		d_fft_window.push_back(cur_window_val);
	}

	//Apply fftshift to d_fft_window
	for(int ii=0; ii < FFT_SIZE_POST/2; ii++){
		d_fft_window.push_back(d_fft_window[ii]);
	}
	d_fft_window.erase(d_fft_window.begin(), d_fft_window.begin()+FFT_SIZE_POST/2);
}

gr_complex harmonic_localizer_impl::polyval(std::vector<float> &p, gr_complex x){
	//Use horner's method to quickly calculate polynomial at frequencies specified in w
	gr_complex out = p[0];
	for(int ii=1; ii < p.size(); ii++){
		out = p[ii] + x*out;
	}
	return out;
}

std::vector<gr_complex> harmonic_localizer_impl::freqz(std::vector<float> &b, std::vector<float> &a, std::vector<float> &w){
	//freqz(b,a,w) = polyval(b,exp(i*w))./polyval(a,exp(i*w))
	
	std::vector<gr_complex> out;
	for(int ii=0; ii < w.size(); ii++){
		gr_complex iw = std::exp(d_i*w[ii]);
		out.push_back(polyval(b,iw)/polyval(a,iw));
	}
	return out;
}

std::vector<gr_complex> harmonic_localizer_impl::freqs(std::vector<float> &b, std::vector<float> &a, std::vector<float> &w){
	//freqs(b,a,w) = polyval(b,i*w)./polyval(a,i*w)

	std::vector<gr_complex> out;
	for(int ii=0; ii < w.size(); ii++){
		gr_complex iw = d_i*w[ii];
		out.push_back(polyval(b,iw)/polyval(a,iw));
	}
	return out;
}

void harmonic_localizer_impl::correctCOMBPhase(){
	//%This reverses any phase imparted by the FPGA's comb filtering
	//%comb_h = freqz(1,[1,0,0,0,0,0,0,0,0.875],2*pi*harmonic_freqs(:)/sample_rate); %4 MHz oscillator: 
	//comb_h = freqz(1,[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.875],2*pi*harmonic_freqs(:)/sample_rate); %2 MHz oscillator
	//comb_h = reshape(comb_h,size(harmonic_freqs));
	//
	//%Factor of two comes from the two cascaded comb filters
	//square_phasors = square_phasors./repmat(shiftdim(comb_h.*comb_h,-1),[size(anchor_positions,1),1,1]);%.*exp(-1i*2*repmat(shiftdim(comb_phase,-1),[size(anchor_positions,1),1,1]));
	static float b[1] = {1};
	static std::vector<float> b_v(b, b+sizeof(b)/sizeof(float));
	
	static float a[17] = {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.875};
	static std::vector<float> a_v(a, a+sizeof(a)/sizeof(float));
	
	//Calculate phasor imparted by comb filter
	std::vector<float> w(d_harmonic_freqs_f);
	for(int ii=0; ii < w.size(); ii++)
		w[ii] = w[ii]/SAMPLE_RATE;
	std::vector<gr_complex> comb_h = freqz(b_v, a_v, w);

	//Correct any imparted amplitude/phase from the two cascaded COMB filters
	for(int ii=0; ii < d_harmonic_phasors.size(); ii++){
		d_harmonic_phasors[ii] = gr_complex(d_harmonic_phasors[ii])/comb_h[ii%comb_h.size()]/comb_h[ii%comb_h.size()];
	}
}

void harmonic_localizer_impl::compensateRCLP(){
	//%This reverses any phase imparted by the DBSRX2's RC lowpass filter
	//%rc_phase = freqs([200e6],[1,200e6],2*pi*harmonic_freqs(:));
	//rc_phase = freqs([80e6],[1,80e6],2*pi*harmonic_freqs(:));
	//rc_phase = reshape(rc_phase,size(harmonic_freqs));
	//
	//square_phasors = square_phasors./repmat(shiftdim(rc_phase,-1),[size(anchor_positions,1),1,1]);
	static float b[1] = {80e6};
	static std::vector<float> b_v(b, b+sizeof(b)/sizeof(float));
	
	static float a[2] = {1,80e6};
	static std::vector<float> a_v(a, a+sizeof(a)/sizeof(float));
	
	//Calculate phasor imparted by RC low-pass filter
	std::vector<gr_complex> rc_phase = freqs(b_v, a_v, d_harmonic_freqs_f);
	
	//Correct any imparted amplitude/phase from the RC low-pass filter
	for(int ii=0; ii < d_harmonic_phasors.size(); ii++){
		d_harmonic_phasors[ii] = gr_complex(d_harmonic_phasors[ii])/rc_phase[ii%rc_phase.size()];
	}
}

void harmonic_localizer_impl::compensateRCHP(){
	//%This reverses any phase imparted by the DBSRX2's RC highpass filter
	//rc_phase = freqs([19e-12, 0],[2.99e-11,3.03e-2],2*pi*(harmonic_freqs(:)+if_freq));
	//rc_phase = reshape(rc_phase,size(harmonic_freqs));
	//
	//square_phasors = square_phasors./repmat(shiftdim(rc_phase,-1),[size(anchor_positions,1),1,1]);
	static float b[2] = {19e-12l, 0};
	static std::vector<float> b_v(b, b+sizeof(b)/sizeof(float));
	
	static float a[2] = {2.99e-11l,3.03e-2l};
	static std::vector<float> a_v(a, a+sizeof(a)/sizeof(float));
	
	//Calculate phasor imparted by DBSRX2's RC highpass filter
	std::vector<float> w(d_harmonic_freqs_f);
	for(int ii=0; ii < w.size(); ii++)
		w[ii] = w[ii]+2.0*M_PI*IF_FREQ;
	std::vector<gr_complex> rc_phase = freqs(b_v, a_v, w);

	//Correct any imparted amplitude/phase from the RC high-pass filter
	for(int ii=0; ii < d_harmonic_phasors.size(); ii++){
		d_harmonic_phasors[ii] = gr_complex(d_harmonic_phasors[ii])/rc_phase[ii%rc_phase.size()];
	}
}

void harmonic_localizer_impl::compensateStepTime(){
	//%This script removes any induced phase offset from time delay to
	//%transform all calculated phases to original frequency step's time-base
	//
	//%Compute harmonic frequencies relative to start frequency
	//%harmonic_freqs_rel = harmonic_freqs + repmat(((0:num_steps-1).').*step_freq,[1,size(square_phasors,3)]);
	//
	//time_delay_in_samples = repmat(((0:num_steps-1).').*samples_per_freq,[1,size(square_phasors,3)]);
	//phase_corr_rep = repmat(shiftdim(harmonic_freqs.*time_delay_in_samples,-1),[size(square_phasors,1),1,1]);
	//square_phasors = square_phasors.*exp(-1i*phase_corr_rep./(sample_rate/decim_factor).*2*pi);


	//Correct any imparted phase from the time difference between observations
	//TODO: This could be simplified a bit since phase_corr doesn't need to be computed separately for each anchor
	int num_h = NUM_STEPS*NUM_HARMONICS_PER_STEP;
	for(int ii=0; ii < d_harmonic_phasors.size(); ii++){
		double phase_corr = (double)(d_time_delay_in_samples[ii])*d_harmonic_freqs[ii%num_h]/SAMPLE_RATE*DECIM_FACTOR;
		phase_corr = fmod(phase_corr, (2.0*M_PI));
		d_harmonic_phasors[ii] = d_harmonic_phasors[ii]*std::exp(-d_i*(float)(phase_corr));
	}
}

std::vector<int> harmonic_localizer_impl::extractToAs(std::vector<gr_complex> hp_rearranged, float *imp_thresholds){
	//INTERP = 64;
	//THRESH = 0.2;
	//
	//num_antennas = size(iq_fft,1);
	//num_timepoints = size(iq_fft,3);
	//
	//if (nargin < 4) || (skip_windowing == 0)
	//    ham = hamming(size(actual_fft,2));
	//else
	//    ham = ones(size(actual_fft,2),1);
	//end
	//ham = fftshift(ham);
	//
	//imp_toas = zeros(num_antennas, num_timepoints);
	//
	//for ii=1:num_timepoints
	//    imp_fft = iq_fft(:,:,ii).*repmat(shiftdim(ham,-1),[num_antennas,1])./actual_fft;%repmat(shiftdim(actual_fft,-1),[num_antennas,1]);
	//    
	//    %zero-pad
	//    imp_fft = [imp_fft(:,1:ceil(size(imp_fft,2)/2)),zeros(size(imp_fft,1),INTERP*size(imp_fft,2)),imp_fft(:,ceil(size(imp_fft,2)/2)+1:end)];
	//    imp = ifft(imp_fft,[],2);
	//
	//    %Find maxes for normalization
	//    [imp_maxes, imp_max_idxs] = max(imp,[],2);
	//    %keyboard;
	//    
	//    %Shift everything to the right as far as the latest max peak
	//    imp = circshift(imp,[0,-imp_max_idxs(1)]);
	//    %last_peak = max(imp_max_idxs);
	//    %if(last_peak > 3*size(imp,2)/4)
	//    %    imp = circshift(imp,[0,-floor(size(imp,2)/4)]);
	//    %    [~, imp_max_idxs] = max(imp,[],2);
	//    %    last_peak = max(imp_max_idxs);
	//    %end
	//    %imp = circshift(imp,[0,size(imp,2)-last_peak]);
	//    
	//    imp_norm = imp./repmat(imp_maxes,[1,size(imp,2)]);
	//
	//    %Find peak of first impulse and see if we need to rotate
	//    for jj=1:num_antennas
	//        gt_thresh = [0, find(abs(imp_norm(jj,:)) > thresh_in(jj))];
	//        gt_thresh_diff = diff(gt_thresh);
	//        [~,gt_thresh_diff_max] = max(gt_thresh_diff);
	//        imp_toas(jj,ii) = gt_thresh(gt_thresh_diff_max+1);
	//    end
	//    %keyboard;
	//    
	//%     num_backsearch = floor(size(imp,2))/4;
	//%     start_idx = toa1-num_backsearch+1;
	//%     if(start_idx < 1)
	//%         imp = circshift(imp,[0,floor(size(imp,2)/4)]);
	//%     end
	//%     for jj=1:num_antennas
	//%         imp_toas(jj,ii) = find(abs(imp(jj,:)) > THRESH,1);
	//%     end
	//    %ii
	//end

	static std::vector<gr_complex> fft_array(FFT_SIZE_POST*INTERP,0);
	std::vector<int> toas;

	for(int ii=0; ii < NUM_ANCHORS; ii++){
		int anchor_idx = ii*FFT_SIZE_POST;
		for(int jj=0; jj < NUM_STEPS; jj++){
			int step_idx = jj*NUM_HARM_PER_STEP_POST;
			for(int kk=0; kk < NUM_HARM_PER_STEP_POST; kk++){

				//Multiply phasors by a window for super-resolution purposes
				int cur_idx = anchor_idx + step_idx + kk;
				hp_rearranged[cur_idx] *= d_fft_window[step_idx + kk];
			
				//Divide by the expected phasors
				hp_rearranged[cur_idx] /= d_actual_fft[cur_idx];
			}
		}

		/*** Perform IFFT on zero-padded array to obtain super-resolution CIR ***/

		//Start by copying the current phasors into the appropriate array
		memcpy(d_fft->get_inbuf(), &hp_rearranged[anchor_idx], FFT_SIZE_POST/2*sizeof(gr_complex));
		memcpy(d_fft->get_inbuf() + FFT_SIZE_POST*INTERP - FFT_SIZE_POST/2, &hp_rearranged[anchor_idx + FFT_SIZE_POST/2], FFT_SIZE_POST/2*sizeof(gr_complex));

		//Then perform FFT
		d_fft->execute();

		//Get magnitude of CIR
		std::vector<float> cir_mag(fft_array.size(), 0);
		volk_32fc_magnitude_32f_u(&cir_mag[0], d_fft->get_outbuf(), fft_array.size());

		//if(d_abs_count == 9 || d_abs_count == 800){
		//	std::cout << "start" << std::endl;
		//	for(int jj=0; jj < fft_array.size(); jj++){
		//		std::cout << cir_mag[jj] << std::endl;
		//	}
		//}
		
		//NOTE: CIR is backwards because of the use of an FFT instead of IFFT
		//Iteratively find maximum peak
		float max_mag = 0.0;
		int max_mag_idx = 0;
		for(int jj=0; jj < FFT_SIZE_POST*INTERP; jj++){
			if(cir_mag[jj] > max_mag){
				max_mag = cir_mag[jj];
				max_mag_idx = jj;
			}
		}

		//Last step: Determine ToA based on passed thresholds
		int cur_idx = max_mag_idx;
		int cand_toa_idx = max_mag_idx;
		int below_threshold_count = 0;
		for(int jj=0; jj < FFT_SIZE_POST*INTERP; jj++){
			if(cir_mag[cur_idx]/max_mag < imp_thresholds[ii]){
				below_threshold_count++;
				if(below_threshold_count > FFT_SIZE_POST*INTERP/4) break;
			} else {
				cand_toa_idx = cur_idx;
				below_threshold_count = 0;
			}
			cur_idx++;
			if(cur_idx >= FFT_SIZE_POST*INTERP) cur_idx = 0;
		}

		//Must flip ToAs since not doing an FFT
		int res_toa = FFT_SIZE_POST*INTERP-cand_toa_idx;
		res_toa -= d_toa_errors[ii];
		res_toa %= FFT_SIZE_POST*INTERP;
		if(res_toa < 0) res_toa += FFT_SIZE_POST*INTERP;
		toas.push_back(res_toa);
	}

	//Rotate ToAs so that ToA of the first anchor ends up in the middle in order to avoid issues where ToAs span 
	int rotate_amount = (FFT_SIZE_POST*INTERP/2)-toas[0];
	for(int ii=0; ii < NUM_ANCHORS; ii++){
		toas[ii] += rotate_amount;
		if(toas[ii] < 0)
			toas[ii] += FFT_SIZE_POST*INTERP;
		else if(toas[ii] >= FFT_SIZE_POST*INTERP)
			toas[ii] -= FFT_SIZE_POST*INTERP;
	}
	//if(d_abs_count == 9){
	//	for(int jj=0; jj < toas.size(); jj++){
	//		std::cout << toas[jj] << " ";
	//	}
	//	std::cout << std::endl;
	//}

	return toas;
}

void harmonic_localizer_impl::harmonicLocalization(){
	//INTERP = 64;
	//
	//%This does localization via analysis of the impulse response at each antenna
	//square_phasors_reshaped = flipdim(square_phasors(:,:,5:12),2);
	//square_phasors_reshaped = permute(square_phasors_reshaped,[1,3,2]);
	//square_phasors_reshaped = reshape(square_phasors_reshaped,[size(square_phasors_reshaped,1),size(square_phasors_reshaped,2)*size(square_phasors_reshaped,3)]);
	//
	//%Rearrange so DC is at zero
	//square_phasors_reshaped = [square_phasors_reshaped(:,133:end),square_phasors_reshaped(:,1:132)];
	//
	//%Perform same rearrangements to tx_phasors_reshaped
	//tx_phasors_reshaped = flipdim(tx_phasors(:,:,5:12),2);
	//tx_phasors_reshaped = permute(tx_phasors_reshaped,[1,3,2]);
	//tx_phasors_reshaped = reshape(tx_phasors_reshaped,[size(tx_phasors_reshaped,1),size(tx_phasors_reshaped,2)*size(tx_phasors_reshaped,3)]);
	//tx_phasors_reshaped = [tx_phasors_reshaped(:,133:end),tx_phasors_reshaped(:,1:132)];
	//
	//%Calculate ToAs and the corresponding impulse response
	//[imp_toas, imp] = extractToAs(square_phasors_reshaped, tx_phasors_reshaped, [0.2, 0.2, 0.2, 0.2]);
	//
	//%Convert imp_toas to meters
	//imp_toas = imp_toas/(2*prf_est*size(square_phasors_reshaped,2))/INTERP*3e8;

	//Rearrange square phasors so they're in the expected shape/orientation for IFFT processing
	std::vector<gr_complex> hp_rearranged(NUM_ANCHORS*FFT_SIZE_POST,gr_complex(0.0, 0.0));
	for(int ii=0; ii < NUM_ANCHORS; ii++){
		int hp_idx = 0;
		for(int jj=0; jj < NUM_STEPS; jj++){
			for(int kk=HARMONIC_NON_OVERLAP_START; kk <= HARMONIC_NON_OVERLAP_END; kk++){
				int phasor_idx = ii*NUM_STEPS*NUM_HARMONICS_PER_STEP+(NUM_STEPS-jj-1)*NUM_HARMONICS_PER_STEP+kk;
				int res_idx = ii*FFT_SIZE_POST + ((hp_idx + FFT_SHIFT_POST) % FFT_SIZE_POST);
				hp_rearranged[res_idx] = d_harmonic_phasors[phasor_idx];
				hp_idx++;
			}
		}
	}
	//if(d_abs_count == 9){
	//	std::cout << "start" << std::endl;
	//	for(int ii=0; ii < hp_rearranged.size(); ii++){
	//		std::cout << hp_rearranged[ii].real() << " " << hp_rearranged[ii].imag() << std::endl;
	//	}
	//}

	//Calculate ToAs given phasors and expected phasors
	float imp_thresholds[4] = {0.2, 0.2, 0.2, 0.2};
	std::vector<int> imp_toas = extractToAs(hp_rearranged, imp_thresholds);
	std::vector<double> imp_in_ns;
	for(int ii=0; ii < imp_toas.size(); ii++){
		double cur_toa = (double)imp_toas[ii]/(d_prf_est*FFT_SIZE_POST)/INTERP*1e9;
		imp_in_ns.push_back(cur_toa);
	}
	std::vector<double> imp_in_m;
	for(int ii=0; ii < imp_toas.size(); ii++){
		double cur_toa = (double)imp_toas[ii]/(d_prf_est*FFT_SIZE_POST)/INTERP*3e8;
		imp_in_m.push_back(cur_toa);
	}
	//for(int ii=0; ii < imp_in_ns.size(); ii++){
	//	std::cout << imp_in_ns[ii] << " ";
	//}
	//std::cout << std::endl;
	
	//Finally, determine position based on calculated ToAs...
	//std::vector<float> positions = tdoa4(imp_in_ns);
	std::vector<float> positions = tdoa4_slow(imp_in_m);
	//if(positions[3] > 2.5){
	//	std::cout << d_abs_count << " ";
	//	for(int ii=0; ii < positions.size(); ii++){
	//		std::cout << positions[ii] << " ";
	//	}
	//	for(int ii=0; ii < imp_in_ns.size(); ii++){
	//		std::cout << imp_in_ns[ii] << " ";
	//	}
	//	std::cout << std::endl;
	//}
	//if(d_abs_count == 1374){
	for(int ii=0; ii < positions.size(); ii++){
		std::cout << positions[ii] << " ";
	}
	std::cout << std::endl;
	//}
	//sendToGATD(positions);
}

int harmonic_localizer_impl::work(int noutput_items,
		gr_vector_const_void_star &input_items,
		gr_vector_void_star &output_items){


	const gr_complex *in = (const gr_complex *) input_items[0];
	int count=0;
	int out_count = 0;
	std::vector<tag_t> tags;
	const uint64_t nread = nitems_read(0);

	while(count < noutput_items){
		//Extract PRF estimate from tag
		get_tags_in_range(tags, 0, nread+count, nread+count+1);
		for(unsigned ii=0; ii < tags.size(); ii++){
			if(tags[ii].key == d_phasor_key)
				d_harmonic_phasors = pmt::c32vector_elements(tags[ii].value);
			else if(tags[ii].key == d_hfreq_key)
				d_harmonic_freqs = pmt::f64vector_elements(tags[ii].value);
			else if(tags[ii].key == d_prf_key)
				d_prf_est = (float)pmt::to_double(tags[ii].value);
		}

		//Translate Hz to rad/sec
		for(int ii=0; ii < d_harmonic_freqs.size(); ii++)
			d_harmonic_freqs[ii] *= 2.0*M_PI;

		//Lower-fidelity harmonic freqs for most calculations
		d_harmonic_freqs_f.clear();
		for(int ii=0; ii < d_harmonic_freqs.size(); ii++)
			d_harmonic_freqs_f.push_back((float)d_harmonic_freqs[ii]);

		//Put the phasors through various calibration steps
		correctCOMBPhase();
		compensateRCLP();
		compensateRCHP();
		compensateStepTime();
		harmonicLocalization();
		//std::cout << d_abs_count << std::endl;
		//It is assumed that each dataset coming in has already populated d_harmonic_phasors and d_hfreq_key
		//if(d_abs_count == 9){
		//	std::cout << "start" << std::endl;
		//	for(int ii=0; ii < d_actual_fft.size(); ii++){
		//		std::cout << d_actual_fft[ii].real() << " " << d_actual_fft[ii].imag() << std::endl;
		//	}
		//}

		if(d_abs_count == 1)
			d_start_time = clock();
		else{
			clock_t cur_time = clock();
			std::cout << (double)(cur_time-d_start_time)/(d_abs_count-1)/CLOCKS_PER_SEC << std::endl;
		}
		d_abs_count++;
		count++;
	}   // while

	return noutput_items;
}

} /* namespace fast_square */
} /* namespace gr */
