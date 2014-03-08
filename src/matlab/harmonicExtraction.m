%Extract amplitude, phase measurements from entire dataset
square_phasors = zeros(size(anchor_positions,1),size(cur_iq_data,2),(num_harmonics_present+1));
for cur_anchor_idx = 1:size(anchor_positions,1)
	for cur_freq_step = 1:size(cur_iq_data,2)
		harmonic_idx = 1;
		for harmonic_num = -num_harmonics_present:2:num_harmonics_present
			cur_bb = exp(1i*(0:size(cur_iq_data,3)-1)*2*pi*(...
                        square_est*harmonic_num+...
                        carrier_offset+...
                        (carrier_segment-cur_freq_step)*(step_freq-square_est*(step_freq/square_freq))...
                    )/(sample_rate/decim_factor)); %TODO: Review cur_freq_step addition
			square_phasors(cur_anchor_idx,cur_freq_step,harmonic_idx) = sum(cur_bb .* squeeze(cur_iq_data(cur_anchor_idx,cur_freq_step, :)).');
			harmonic_idx = harmonic_idx + 1;
		end
	end
end

%keyboard;

%Extract apparent length of LO cable from successive inter-segment phase measurements
num_harmonic_step = round(-step_freq/square_freq/2);
phase_step = angle(square_phasors(:,carrier_segment+1,1+num_harmonic_step))-angle(square_phasors(:,carrier_segment,1));
