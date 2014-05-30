%For now, LO length compensation will be directly based on assumed LO cable
%lengths
lo_freqs = start_lo_freq + (0:num_steps-1)*step_freq;
square_phasors = square_phasors.*exp(-1i*repmat(lo_lengths,[1,size(square_phasors,2),size(square_phasors,3)]).*repmat(lo_freqs,[size(square_phasors,1),1,size(square_phasors,3)])/3e8*2*pi);

%For now, LO length compensation will be directly based on pre-calculated phase
%differentials
load cal_diff_meas
square_phasors = square_phasors.*exp(-1i*repmat((0:31),[size(square_phasors,1),1,size(square_phasors,3)]).*repmat(cal_diff_meas,[1,size(square_phasors,2),size(square_phasors,3)]));