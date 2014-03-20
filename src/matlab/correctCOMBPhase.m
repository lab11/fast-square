%This reverses any phase imparted by the FPGA's comb filtering
comb_phase = phasez(1,[1,0,0,0,0,0,0,0.875],2*pi*harmonic_freqs(:)/sample_rate);
comb_phase = reshape(comb_phase,size(harmonic_freqs));

square_phasors = square_phasors.*exp(-1i*repmat(shiftdim(comb_phase,-1),[size(anchor_positions,1),1,1]));