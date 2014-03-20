%This script removes any induced phase offset from time delay to
%transform all calculated phases to original frequency step's time-base

time_delay_in_samples = repmat(((0:num_steps-1).').*2099*decim_factor,[1,size(square_phasors,2)]);
square_phasors = square_phasors.*exp(-1i*harmonic_freqs.*time_delay_in_samples./sample_rate.*2*pi);