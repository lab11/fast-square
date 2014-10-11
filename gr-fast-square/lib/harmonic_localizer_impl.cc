
#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include "harmonic_localizer_impl.h"
#include <gnuradio/io_signature.h>
#include <cstdio>
#include <string>
#include <fstream>

namespace gr {
namespace fast_square {

harmonic_localizer::sptr harmonic_localizer::make(const std::string &phasor_tag_name, const std::string &hfreq_tag_name){
	return gnuradio::get_initial_sptr
		(new harmonic_localizer_impl(phasor_tag_name, hfreq_tag_name));
}

harmonic_localizer_impl::harmonic_localizer_impl(const std::string &phasor_tag_name, const std::string &hfreq_tag_name)
	: sync_block("harmonic_localizer",
			io_signature::make(4, 4, NUM_STEPS*FFT_SIZE*sizeof(gr_complex)),
			io_signature::make(4, 4, NUM_STEPS*FFT_SIZE*sizeof(gr_complex)))
{
	d_phasor_key = pmt::string_to_symbol(phasor_tag_name);
	d_hfreq_key = pmt::string_to_symbol(hfreq_tag_name);
	
	d_i = gr_complex(0, 1);

	//Pre-calculated vector generated for compensateStepTime step
	for(int ii=0; ii < NUM_ANCHORS * NUM_STEPS * NUM_HARMONICS_PER_STEP; ii++){
		d_time_delay_in_samples.push_back(((ii/NUM_HARMONICS_PER_STEP) % NUM_STEPS)*SAMPLES_PER_FREQ);
	}
}

harmonic_localizer_impl::~harmonic_localizer_impl(){
}

gr_complex harmonic_localizer_impl::polyval(std::vector<float> &p, gr_complex x){
	//Use horner's method to quickly calculate polynomial at frequencies specified in w
	gr_complex out = x;
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
	std::vector<float> w(d_harmonic_freqs);//TODO: Where is d_harmonic_freqs coming from??? (Shouldn't be abs...)
	for(int ii=0; ii < w.size(); ii++)
		w[ii] = w[ii]/SAMPLE_RATE;
	std::vector<gr_complex> comb_h = freqz(b, a, w);

	//Correct any imparted amplitude/phase from the two cascaded COMB filters
	for(int ii=0; ii < d_harmonic_phasors.size(); ii++){
		d_harmonic_phasors[ii] = d_harmonic_phasors[ii]./comb_h[ii%comb_h.size()]./comb_h[ii%comb_h.size()];
	}
}

void harmonic_localizer_impl::compensateRCLP(){
	//%This reverses any phase imparted by the DBSRX2's RC lowpass filter
	//%rc_phase = freqs([200e6],[1,200e6],2*pi*harmonic_freqs(:));
	//rc_phase = freqs([80e6],[1,80e6],2*pi*harmonic_freqs(:));
	//rc_phase = reshape(rc_phase,size(harmonic_freqs));
	//
	//square_phasors = square_phasors./repmat(shiftdim(rc_phase,-1),[size(anchor_positions,1),1,1]);
	static float b[1] = {200e6};
	static std::vector<float> b_v(b, b+sizeof(b)/sizeof(float));
	
	static float a[2] = {1,80e6};
	static std::vector<float> a_v(a, a+sizeof(a)/sizeof(float));
	
	//Calculate phasor imparted by RC low-pass filter
	std::vector<gr_complex> rc_phase = freqs(b, a, d_harmonic_freqs);
	
	//Correct any imparted amplitude/phase from the RC low-pass filter
	for(int ii=0; ii < d_harmonic_phasors.size(); ii++){
		d_harmonic_phasors[ii] = d_harmonic_phasors[ii]/rc_phase[ii%rc_phase.size()];
	}
}

void harmonic_localizer_impl::compensateRCHP(){
	//%This reverses any phase imparted by the DBSRX2's RC highpass filter
	//rc_phase = freqs([19e-12, 0],[2.99e-11,3.03e-2],2*pi*(harmonic_freqs(:)+if_freq));
	//rc_phase = reshape(rc_phase,size(harmonic_freqs));
	//
	//square_phasors = square_phasors./repmat(shiftdim(rc_phase,-1),[size(anchor_positions,1),1,1]);
	static float b[2] = {19e-12, 0};
	static std::vector<float> b_v(b, b+sizeof(b)/sizeof(float));
	
	static float a[2] = {2.99e-11,3.03e-2};
	static std::vector<float> a_v(a, a+sizeof(a)/sizeof(float));
	
	//Calculate phasor imparted by DBSRX2's RC highpass filter
	std::vector<float> w(d_harmonic_freqs);
	for(int ii=0; ii < w.size(); ii++)
		w[ii] = w[ii]+IF_FREQ;
	std::vector<gr_complex> rc_phase = freqs(b, a, w);

	//Correct any imparted amplitude/phase from the RC high-pass filter
	for(int ii=0; ii < d_harmonic_phasors.size(); ii++){
		d_harmonic_phasors[ii] = d_harmonic_phasors[ii]/rc_phase[ii%rc_phase.size()];
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
	for(int ii=0; ii < d_harmonic_phasors.size(); ii++){
		float phase_corr = d_harmonic_freqs[ii]*d_time_delay_in_samples[ii];
		d_harmonic_phasors[ii] = d_harmonic_phasors[ii]*std::exp(-d_i*phase_corr/(SAMPLE_RATE/DECIM_FACTOR));
	}
}

std::vector<float> harmonic_localizer_impl::extractToAs(float *imp_thresholds){
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
	std::vector<gr_complex> d_hp_rearranged;
	for(int ii=0; ii < NUM_ANCHORS; ii++)
		for(int jj=0; jj < NUM_STEPS; jj++)
			for(int kk=HARMONIC_NON_OVERLAP_START; kk <= HARMONIC_NON_OVERLAP_END; kk++)
				d_hp_rearranged.push_back(d_harmonic_phasors[ii*NUM_STEPS*NUM_HARMONICS_PER_STEP+jj*NUM_HARMONICS_PER_STEP+kk]);

	//Calculate ToAs given phasors and expected phasors
	//TODO: Initialize d_tx_phasors somewhere
	float imp_thresholds[4] = {0.2, 0.2, 0.2, 0.2};
	imp_toas = extractToAs(imp_thresholds);
}

int harmonic_localizer_impl::work(int noutput_items,
		gr_vector_const_void_star &input_items,
		gr_vector_void_star &output_items){

	const gr_complex *in = (const gr_complex *) input_items[0];
	gr_complex *out = (gr_complex *) output_items[0];
	int count=0;
	int out_count = 0;

	while(count < noutput_items){
		//Extract PRF estimate from tag
		get_tags_in_range(tags, 0, nread+count, nread+count+1);
		for(unsigned ii=0; ii < tags.size(); ii++){
			if(tags[ii].key == d_phasor_key)
				d_harmonic_phasors = pmt::c32vector_elements(tags[ii].value);
			else if(tags[ii].key == d_hfreq_key)
				d_harmonic_freqs = pmt::f32vector_elements(tags[ii].value);
		}

		//It is assumed that each dataset coming in has already populated d_harmonic_phasors and d_hfreq_key
		correctCOMBPhase();
		compensateRCLP();
		compensateRCHP();
		compensateStepTime();
		harmonicLocalization();
	}   // while

	return noutput_items;
}

} /* namespace fast_square */
} /* namespace gr */
