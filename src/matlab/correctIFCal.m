load if_cal

%apply phase offset according to calibration (which is a linear model)
if_cal_m = repmat(if_cal_m,[1,size(square_phasors,2),size(square_phasors,3)]);
if_cal_b = repmat(if_cal_b,[1,size(square_phasors,2),size(square_phasors,3)]);
harmonic_freqs_temp = repmat(shiftdim(harmonic_freqs,-1),[size(square_phasors,1),1,1]);
phase_errors = if_cal_m.*harmonic_freqs_temp+if_cal_b;

%Remove any phase error
square_phasors = square_phasors.*exp(-1i*phase_errors);