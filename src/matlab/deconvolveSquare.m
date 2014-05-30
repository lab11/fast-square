load tx_phasors

square_phasors_deconv = square_phasors./repmat(shiftdim(tx_phasors,-1),[size(square_phasors,1),1,1]);

%tx_phasors_rep = repmat(shiftdim(tx_phasors,-1),[size(square_phasors,1),1,1]);

%square_phasors_deconv = wienerDe(tx_phasors_rep, square_phasors, abs(tx_phasors_rep)./max(abs(tx_phasors_rep(:))));