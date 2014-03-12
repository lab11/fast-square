%Load pre-calibrated measurements
load('cal_phase_step');

%Remove accumulated phase error across successive frequency steps
for ii=1:size(cur_iq_data,2)
	square_phasors(:,ii,:) = square_phasors(:,ii,:).*repmat(exp(-1i*cal_phase_step*(ii-1)),[1,1,size(square_phasors,3)]);
end

