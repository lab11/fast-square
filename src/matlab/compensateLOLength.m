%Extract apparent length of LO cable from successive inter-segment phase measurements
%NOTE: This function should be evaluated AFTER all other phase compensation
%steps have been performed
num_harmonic_step = round(-step_freq/square_freq/2);
phase_step = angle(square_phasors(:,carrier_segment+1,1+num_harmonic_step))-angle(square_phasors(:,carrier_segment,1));
