harmonic_nums = -num_harmonics_present/2+.5:num_harmonics_present/2-.5;
he_idxs = repmat(shiftdim(0:fft_len-1,-1),[size(cur_iq_data,1),size(cur_iq_data,2),1,length(harmonic_nums)]);

%Indexes for harmonics from FFT once corrected for any frequency offsets
sp_idxs = mod(round(fft_len*harmonic_nums*prf/(sample_rate/decim_factor)),fft_len)+1;

for cur_freq_step = 1:size(cur_iq_data,2)
	calculateCenterFreqHarmonicNum;
	harmonic_nums_abs(cur_freq_step,:) = center_freq_harmonic_num+harmonic_nums;
end
