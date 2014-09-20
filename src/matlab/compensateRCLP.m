%This reverses any phase imparted by the DBSRX2's RC lowpass filter
%rc_phase = freqs([200e6],[1,200e6],2*pi*harmonic_freqs(:));
rc_phase = freqs([80e6],[1,80e6],2*pi*harmonic_freqs(:));
rc_phase = reshape(rc_phase,size(harmonic_freqs));

square_phasors = square_phasors./repmat(shiftdim(rc_phase,-1),[size(anchor_positions,1),1,1]);
