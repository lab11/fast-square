%Extract apparent length of LO cable from successive inter-segment phase measurements
%NOTE: This function should be evaluated AFTER all other phase compensation
%steps have been performed
num_harmonic_step = round(-step_freq/square_freq/2);
phase_step = angle(square_phasors(:,carrier_segment+1,1+num_harmonic_step))-angle(square_phasors(:,carrier_segment,1));

%For now, LO length compensation will be directly based on pre-calculated phase
%differentials
square_phasors = square_phasors.*exp(-1i*repmat((0:31),[size(square_phasors,1),1,size(square_phasors,3)]).*repmat(cal_diff_meas,[1,size(square_phasors,2),size(square_phasors,3)]));