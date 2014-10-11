
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
	
}

harmonic_localizer_impl::~harmonic_localizer_impl(){
}

void harmonic_localizer_impl::correctCOMBPhase(){
	//%This reverses any phase imparted by the FPGA's comb filtering
	//%comb_h = freqz(1,[1,0,0,0,0,0,0,0,0.875],2*pi*harmonic_freqs(:)/sample_rate); %4 MHz oscillator: 
	//comb_h = freqz(1,[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.875],2*pi*harmonic_freqs(:)/sample_rate); %2 MHz oscillator
	//comb_h = reshape(comb_h,size(harmonic_freqs));
	//
	//%Factor of two comes from the two cascaded comb filters
	//square_phasors = square_phasors./repmat(shiftdim(comb_h.*comb_h,-1),[size(anchor_positions,1),1,1]);%.*exp(-1i*2*repmat(shiftdim(comb_phase,-1),[size(anchor_positions,1),1,1]));

}

void harmonic_localizer_impl::compensateRCLP(){
	//%This reverses any phase imparted by the DBSRX2's RC lowpass filter
	//%rc_phase = freqs([200e6],[1,200e6],2*pi*harmonic_freqs(:));
	//rc_phase = freqs([80e6],[1,80e6],2*pi*harmonic_freqs(:));
	//rc_phase = reshape(rc_phase,size(harmonic_freqs));
	//
	//square_phasors = square_phasors./repmat(shiftdim(rc_phase,-1),[size(anchor_positions,1),1,1]);

}

void harmonic_localizer_impl::compensateRCHP(){
	//%This reverses any phase imparted by the DBSRX2's RC highpass filter
	//rc_phase = freqs([19e-12, 0],[2.99e-11,3.03e-2],2*pi*(harmonic_freqs(:)+if_freq));
	//rc_phase = reshape(rc_phase,size(harmonic_freqs));
	//
	//square_phasors = square_phasors./repmat(shiftdim(rc_phase,-1),[size(anchor_positions,1),1,1]);

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
