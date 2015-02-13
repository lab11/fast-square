%This reverses any phase imparted by the DBSRX2's RC highpass filter
rc_phase = freqs([19e-12, 0],[2.99e-11,3.03e-2],2*pi*(harmonic_freqs(:)+if_freq));
rc_phase = reshape(rc_phase,size(harmonic_freqs));

square_phasors = square_phasors./repmat(shiftdim(rc_phase,-1),[size(anchor_positions,1),1,1]);
