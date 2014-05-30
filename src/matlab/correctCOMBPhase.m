%This reverses any phase imparted by the FPGA's comb filtering
comb_h = freqz(1,[1,0,0,0,0,0,0,0,0.875],2*pi*harmonic_freqs(:)/sample_rate);
comb_h = reshape(comb_h,size(harmonic_freqs));

%Factor of two comes from the two cascaded comb filters
square_phasors = square_phasors./repmat(shiftdim(comb_h./comb_h,-1),[size(anchor_positions,1),1,1]);%.*exp(-1i*2*repmat(shiftdim(comb_phase,-1),[size(anchor_positions,1),1,1]));