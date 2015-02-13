%load timestep2
%harmonicLocalization_r6
%initial_phasors = square_phasors_reshaped;
%
%sprs_idx = 1;
%sprs = zeros(size(square_phasors_reshaped,1),size(square_phasors_reshaped,2),1400);
%ctmi = zeros(1400,1);
%shift_ctr = 0;
%
%for ii=3:1400
%try
%	load(['timestep',num2str(ii)]);
%	harmonicLocalization_r6
%	corr_temp_max = 0;
%	corr_temp_max_idx = 0;
%	ct = zeros(1,512);
%	for jj=0:511
%		spr_temp = square_phasors_reshaped.*repmat(conj(exp(1i*(0:255)*(shift_ctr+jj)/256*pi)),[size(initial_phasors,1),1]);
%		corr_temp = sum(spr_temp./abs(spr_temp).*(initial_phasors),2);
%		ct(jj+1) = sum(abs(corr_temp));
%		if(sum(abs(corr_temp)) > corr_temp_max)
%			corr_temp_max = sum(abs(corr_temp));
%			corr_temp_max_idx = jj;
%		end
%	end
%	ctmi(sprs_idx) = corr_temp_max_idx;
%
%	spr_temp = square_phasors_reshaped.*repmat(conj(exp(1i*(0:255)*shift_ctr/256*pi)),[size(square_phasors_reshaped,1),1]);
%	shift_ctr = shift_ctr + 110;
%	corr_temp = sum(spr_temp./abs(spr_temp).*(initial_phasors./abs(initial_phasors)),1);
%	spr_temp = spr_temp.*repmat(conj(corr_temp./abs(corr_temp)),[size(spr_temp,1),1]);
%
%	sprs(:,:,sprs_idx) = spr_temp;
%	sprs_idx = sprs_idx + 1;
%	ii
%catch
%end
%end

load timestep2
harmonicLocalization_r6
sprs_idx = 1;
sprs = zeros(size(square_phasors_reshaped,1),size(square_phasors_reshaped,2),1400);
for ii=3:1400
try
	load(['timestep',num2str(ii)]);
	harmonicLocalization_r6
	square_phasors_reshaped = square_phasors_reshaped./repmat(max(abs(imp),[],2),[1,size(square_phasors_reshaped,2)]);
	sprs(:,:,sprs_idx) = square_phasors_reshaped;
	sprs_idx = sprs_idx + 1;
	ii
catch
end
end
