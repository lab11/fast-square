%TODO: Possibly add compensation logic for BSF
%TODO: Possibly add ???

load tx_phasors
load tx_phasors_first
load tx_phasors_third

INTERP = 64;

%This does localization via analysis of the impulse response at each antenna
square_phasors_reshaped = flipdim(square_phasors(:,:,5:12),2);
square_phasors_reshaped = permute(square_phasors_reshaped,[1,3,2]);
square_phasors_reshaped = reshape(square_phasors_reshaped,[size(square_phasors_reshaped,1),size(square_phasors_reshaped,2)*size(square_phasors_reshaped,3)]);

%Rearrange so DC is at zero
square_phasors_reshaped = [square_phasors_reshaped(:,133:end),square_phasors_reshaped(:,1:132)];

%spr_deconv = [1, 0, 0, 1, zeros(1,252)];
%spr_deconv_fft = fft(spr_deconv);
%square_phasors_reshaped = square_phasors_reshaped./repmat(spr_deconv_fft,[size(square_phasors_reshaped,1),1]);

%Perform same rearrangements to tx_phasors
tx_phasors = flipud(tx_phasors(:,5:12)).';
tx_phasors = tx_phasors(:);
tx_phasors = [tx_phasors(133:end);tx_phasors(1:132)];
tx_phasors_first = flipud(tx_phasors_first(:,5:12)).';
tx_phasors_first = tx_phasors_first(:);
tx_phasors_first = [tx_phasors_first(133:end);tx_phasors_first(1:132)];
tx_phasors_third = flipud(tx_phasors_third(:,5:12)).';
tx_phasors_third = tx_phasors_third(:);
tx_phasors_third = [tx_phasors_third(133:end);tx_phasors_third(1:132)];

%Calculate ToAs and the corresponding impulse response
[imp_toas, imp] = extractToAs(square_phasors_reshaped, [tx_phasors_first.';tx_phasors.';tx_phasors_third.';tx_phasors.'], [0.2, 0.2, 0.2, 0.2]);

%Convert imp_toas to meters
imp_toas = imp_toas/(2*square_est*size(square_phasors_reshaped,2))/INTERP*3e8;

