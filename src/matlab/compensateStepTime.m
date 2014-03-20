%This script removes any induced phase offset from time delay to
%transform all calculated phases to original frequency step's time-base

time_delay_in_samples = repmat(((0:num_steps-1).').*2099*decim_factor,[1,size(square_phasors,3)]);
phase_corr_rep = repmat(shiftdim(harmonic_freqs.*time_delay_in_samples,-1),[size(square_phasors,1),1,1]);
square_phasors = square_phasors.*exp(-1i*phase_corr_rep./sample_rate.*2*pi);