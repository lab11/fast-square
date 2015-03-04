function ret = visToAs(imp, imp_toa_idxs)

num_imps = size(imp,1);

for ii=1:num_imps
	subplot(1,num_imps,ii);
	plot(1:size(imp,2),abs(imp(ii,:)),repmat(imp_toa_idxs(ii),[2,1]),[0,max(abs(imp(ii,:)))]);
	axis tight
end
