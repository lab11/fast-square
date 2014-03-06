%Extract amplitude, phase measurements from entire dataset
square_phasors = zeros(size(anchor_positions,1),size(cur_iq_data,2),(num_harmonics_present+1));
for cur_anchor_idx = 1:size(anchor_positions,1)
	for cur_freq_step = 1:size(cur_iq_data,2)
		cur_square_freqs = (square_freq+step_freq*(carrier_segment-1))+carrier_offset;
		harmonic_idx = 1;
		for harmonic_num = -num_harmonics_present:2:num_harmonics_present
			cur_bb = exp(1i*(1:size(cur_iq_data,3))*2*pi*(square_est*harmonic_num+carrier_offset)/(sample_rate/decim_factor));
			square_phasors(cur_anchor_idx,cur_freq_step,harmonic_idx) = sum(cur_bb .* squeeze(cur_iq_data(cur_anchor_idx,cur_freq_step, :)).');
			harmonic_idx = harmonic_idx + 1;
		end
	end
end

keyboard;

%Extract apparent length of LO cable from successive inter-segment phase measurements
num_harmonic_step = round(-step_freq/square_freq/2);
phase_step = angle(square_phasors(1,carrier_segment,1))-angle(square_phasors(1,carrier_segment+1,1+num_harmonic_step));

%Remove accumulated phase error across successive frequency steps
for ii=1:size(cur_iq_data,2)
	square_phasors(:,ii,:) = square_phasors(:,ii,:)*exp(-1i*phase_step*(ii-1));
end

