load ../tx_phasors

INTERP = 64;

%This does localization via analysis of the impulse response at each antenna
square_phasors_reshaped = flipdim(square_phasors(:,:,5:12),2);
square_phasors_reshaped = permute(square_phasors_reshaped,[1,3,2]);
square_phasors_reshaped = reshape(square_phasors_reshaped,[size(square_phasors_reshaped,1),size(square_phasors_reshaped,2)*size(square_phasors_reshaped,3)]);

%Rearrange so DC is at zero
square_phasors_reshaped = [square_phasors_reshaped(:,133:end),square_phasors_reshaped(:,1:132)];

%Perform same rearrangements to tx_phasors_reshaped
tx_phasors_reshaped = flipdim(tx_phasors(:,:,5:12),2);
tx_phasors_reshaped = permute(tx_phasors_reshaped,[1,3,2]);
tx_phasors_reshaped = reshape(tx_phasors_reshaped,[size(tx_phasors_reshaped,1),size(tx_phasors_reshaped,2)*size(tx_phasors_reshaped,3)]);
tx_phasors_reshaped = [tx_phasors_reshaped(:,133:end),tx_phasors_reshaped(:,1:132)];

%Calculate ToAs and the corresponding impulse response
[imp_toas, imp] = extractToAs(square_phasors_reshaped, tx_phasors_reshaped, [0.2, 0.2, 0.2, 0.2]);

%Convert imp_toas to meters
imp_toas = imp_toas/(2*prf_est*size(square_phasors_reshaped,2))/INTERP*3e8;

