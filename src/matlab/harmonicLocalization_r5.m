%This does localization via analysis of the impulse response at each antenna
square_phasors_reshaped = flipdim(square_phasors(:,:,3:6),2);
square_phasors_reshaped = permute(square_phasors_reshaped,[1,3,2]);
square_phasors_reshaped = reshape(square_phasors_reshaped,[size(square_phasors_reshaped,1),size(square_phasors_reshaped,2)*size(square_phasors_reshaped,3)]);

%Rearrange so DC is at zero
square_phasors_reshaped = [square_phasors_reshaped(:,67:end),square_phasors_reshaped(:,1:66)];

%Perform same rearrangements to tx_phasors
tx_phasors = flipud(tx_phasors(:,3:6)).';
tx_phasors = tx_phasors(:);
tx_phasors = [tx_phasors(67:end);tx_phasors(1:66)];

%Calculate ToAs and the corresponding impulse response
[imp_toas, imp] = extractToAs(square_phasors_reshaped, tx_phasors);

