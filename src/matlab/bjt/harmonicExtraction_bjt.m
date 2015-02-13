%Keep bb equivalent around for checking later
bb_tot = zeros(size(cur_iq_data,2),size(cur_iq_data,3));

%Actual harmonic frequencies are necessary for later comb filter correction
harmonic_freqs = zeros(size(cur_iq_data,2),num_harmonics_present);

%Extract amplitude, phase measurements from entire dataset
square_phasors = zeros(size(anchor_positions,1),size(cur_iq_data,2),num_harmonics_present);
for cur_anchor_idx = 1:size(anchor_positions,1)
	for cur_freq_step = 1:size(cur_iq_data,2)
		harmonic_idx = 1;
		calculateCenterFreqHarmonicNum;
		for harmonic_num = -num_harmonics_present/2+.5:num_harmonics_present/2-.5
			harmonic_freq = (...
					prf_est*harmonic_num+...
					(prf_est-prf)*center_freq_harmonic_num-...
					tune_offset);
			cur_bb = exp(-1i*(0:size(cur_iq_data,3)-1)*2*pi*harmonic_freq...
				/(sample_rate/decim_factor)); %TODO: Review cur_freq_step addition
			square_phasors(cur_anchor_idx,cur_freq_step,harmonic_idx) = sum(cur_bb .* squeeze(cur_iq_data(cur_anchor_idx,cur_freq_step, :)).');
			
			bb_tot(cur_freq_step,:) = bb_tot(cur_freq_step,:) + conj(cur_bb);
			harmonic_freqs(cur_freq_step,harmonic_idx) = harmonic_freq;
			harmonic_freqs_abs(cur_freq_step,harmonic_idx) = harmonic_freq + prf*center_freq_harmonic_num;
            
			harmonic_idx = harmonic_idx + 1;
		end
	end
end
