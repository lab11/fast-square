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

%Identify pure-zero phasors (they should be from zeroing due to narrowband cancellation)
if(length(res.ignore_freq_steps) > 0)
	N = size(tx_phasors_reshaped,2);
	for hl_ii = 1:size(tx_phasors_reshaped,1)
		y = square_phasors_reshaped(hl_ii,:).';
	
		OMEGA = find(abs(y) > 0);
		OMEGA_NOT = find(abs(y) == 0);
		N = length(y);
		K = sum(abs(y) > 0);
		B=dftmtx(N);
		Binv=inv(B);
		A=B(OMEGA,:);
		y = y(OMEGA);
		x0=A'*y;
		xp=l1eq_pd(x0,A,[],y,1e-5);
	
		new_cir = xp;
		new_fr = fft(new_cir);
		tx_phasors_reshaped(hl_ii,OMEGA_NOT) = new_fr(OMEGA_NOT);
	end
end

%Calculate ToAs and the corresponding impulse response
[imp_toas, imp] = extractToAs(square_phasors_reshaped, tx_phasors_reshaped, [0.2, 0.2, 0.2, 0.2]);

%%We are looking for the 30% height of the first peak, not overall magnitude
%for ii=1:size(imp,1)
%	up_slope = true;
%
%	%Find magnitude of LoS peak
%	while up_slope
%		last_imp = abs(imp(ii,imp_toas(ii)));
%		imp_toas(ii) = imp_toas(ii) + 1;
%		if(imp_toas(ii) > size(imp,2))
%			imp_toas(ii) = 1;
%		end
%		cur_imp = abs(imp(ii,imp_toas(ii)));
%		if(cur_imp < last_imp)
%			up_slope = false;
%		end
%	end
%
%	%Go back at most INTERP spaces to find 50% height of LoS peak
%	los_imp = last_imp;
%	for jj=1:INTERP*3
%		imp_toas(ii) = imp_toas(ii) - 1;
%		if(imp_toas(ii) < 1)
%			imp_toas(ii) = size(imp,2);
%		end
%		cur_imp = abs(imp(ii,imp_toas(ii)));
%		if(cur_imp < 0.5*los_imp)
%			break;
%		end
%	end
%end

%Convert imp_toas to meters
imp_toa_idxs = imp_toas;
imp_toas = imp_toas/(2*prf_est*size(square_phasors_reshaped,2))/(INTERP+1)*3e8;
