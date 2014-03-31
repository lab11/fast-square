%For now, LO length compensation will be directly based on assumed LO cable
%lengths
square_phasors = square_phasors.*exp(-1i*repmat(lo_lengths,[1,size(square_phasors,2),size(square_phasors,3)]).*repmat(shiftdim(harmonic_freqs_abs,-1),[size(square_phasors,1),1,1])/3e8*2*pi);