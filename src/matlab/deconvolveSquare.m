load tx_phasors

square_phasors_deconv = square_phasors./repmat(shiftdim(tx_phasors,-1),[size(square_phasors,1),1,1]);