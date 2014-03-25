
%Perform localization operations
physical_est = physical_search_space(1,:);
physical_distances = zeros(size(anchor_positions,1),1);
est_likelihood = zeros(size(physical_search_space,1),1);
recomputed_phasors = zeros(size(square_phasors));
for pos_idx=1:size(physical_search_space,1)
	physical_est = physical_search_space(pos_idx,:);
	for ii=1:size(anchor_positions,1)
		physical_distances(ii) = norm(physical_est-anchor_positions(ii,:));
		recomputed_phasors(ii,:,:) = square_phasors(ii,:,:) .* shiftdim(exp(-1i*physical_distances(ii)*harmonic_freqs_abs./3e8.*2*pi),-1)./abs(square_phasors(ii,:,:));
    end
    %Bring all anchors to a common center harmonic phase
    %TODO: is this supposed to be a constant value?
    %recomputed_phasors = recomputed_phasors.*repmat(exp(-1i*angle(recomputed_phasors(:,15,4))),[1,32,8]);
	est_likelihood(pos_idx) = abs(sum(sum(abs(sum(recomputed_phasors,1)),3)));
    %keyboard;
	%disp(['cur_val = ', num2str(est_likelihood(pos_idx))])
	if mod(pos_idx,10000) == 0
		disp(['pos_idx = ', num2str(pos_idx)])
	end
end

[est_max, est_max_idx] = max(est_likelihood);
[est_x_idx, est_y_idx, est_z_idx] = ind2sub([length(x),length(y),length(z)],est_max_idx);
est_position = physical_search_space(est_max_idx,:);
est_likelihood = reshape(est_likelihood,[length(x),length(y),length(z)]);

% %One more time for debugging purposes
% physical_est = physical_search_space(est_max_idx,:);
% for ii=1:size(anchor_positions,1)
%     physical_distances(ii) = norm(physical_est-anchor_positions(ii,:));
%     recomputed_phasors(ii,:,:) = square_phasors(ii,:,:) .* shiftdim(exp(-1i*physical_distances(ii)*harmonic_freqs_abs./3e8.*2*pi),-1)./abs(square_phasors(ii,:,:));
% end
% %Bring all anchors to a common center harmonic phase
% recomputed_phasors = recomputed_phasors.*repmat(exp(-1i*angle(recomputed_phasors(:,15,4))),[1,32,8]);
% est_likelihood_single = abs(sum(sum(abs(sum(recomputed_phasors,1)),3)));
% keyboard;