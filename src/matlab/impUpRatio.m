function ret = impUpRatio(in_imp, num_preceding)
%This function finds the maximum ratio in time domain amplitudes between
%one sample and those preceding it (heuristic)

in_imp = in_imp(:);
in_imp_shifts = -num_preceding:0;
in_imp_shifts = repmat(in_imp_shifts,[length(in_imp),1]);
in_imp_idxs = 1:length(in_imp);
in_imp_idxs = repmat(in_imp_idxs(:),[1,num_preceding+1]);
shift_idxs = in_imp_shifts + in_imp_idxs;
shift_idxs(shift_idxs < 1) = shift_idxs(shift_idxs < 1) + length(in_imp);
in_imp_rep = in_imp(shift_idxs);
%keyboard;

%Compute ratio
ret = max(in_imp_rep(:,end)./sum(in_imp_rep(:,1:end-1),2));