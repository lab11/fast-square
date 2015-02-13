cand_peaks = [];
cand_freqs = prf*(1-prf_accuracy):prf*coarse_precision:prf*(1+prf_accuracy);
for ii=1:length(cand_freqs)
	jj = 1;
	for cur_freq_step=1:num_steps
		calculateCenterFreqHarmonicNum;
		%TODO: num_harmonics_present/4 is somewhat arbitrary...
		for harmonic_num = -num_harmonics_present/4+.5:num_harmonics_present/4-.5
			cand_peaks(ii,jj) = fft_len*(...
					cand_freqs(ii)*harmonic_num+...
					(cand_freqs(ii)-prf)*center_freq_harmonic_num-...
					tune_offset...
				)/(sample_rate/decim_factor);

			cand_peaks(ii,jj) = mod(round(cand_peaks(ii,jj)),fft_len) + ((cur_freq_step-1)*fft_len) + 1;
			jj = jj + 1;
		end
	end
end

