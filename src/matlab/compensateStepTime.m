%This script removes any induced phase offset from time delay to
%transform all calculated phases to original frequency step's time-base

%Compute harmonic frequencies relative to start frequency
%harmonic_freqs_rel = harmonic_freqs + repmat(((0:num_steps-1).').*step_freq,[1,size(square_phasors,3)]);

time_delay_in_samples = repmat(((0:num_steps-1).').*samples_per_freq,[1,size(square_phasors,3)]);
phase_corr_rep = repmat(shiftdim(harmonic_freqs.*time_delay_in_samples,-1),[size(square_phasors,1),1,1]);
square_phasors = square_phasors.*exp(-1i*phase_corr_rep./(sample_rate/decim_factor).*2*pi);