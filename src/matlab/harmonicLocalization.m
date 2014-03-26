tic
est_likelihood = zeros(size(physical_search_space,1),1);
chunk_size = 10e3;
harmonic_freqs_abs_rep = repmat(shiftdim(harmonic_freqs_abs,-2),[size(recomputed_phasors,1),chunk_size,1,1]);
%Perform localization operations, breaking up into chunks which are small enough
for ii=1:chunk_size:size(physical_search_space,1)
    if ii+chunk_size < size(physical_search_space,1)
        cur_num_search = chunk_size;
    else
        cur_num_search = size(physical_search_space,1)-ii+1;
    end
    
    %Perform localization operations
    square_phasors_reshaped = reshape(square_phasors,[size(square_phasors,1),1,size(square_phasors,2),size(square_phasors,3)]);
    recomputed_phasors = repmat(square_phasors_reshaped,[1,cur_num_search,1,1]);
    
    recomputed_phasors = recomputed_phasors./abs(recomputed_phasors);
    
    recomputed_phasors = recomputed_phasors.*exp(-1i*repmat(physical_distances(:,ii:ii+cur_num_search-1),[1,1,size(recomputed_phasors,3),size(recomputed_phasors,4)]).*harmonic_freqs_abs_rep(:,1:cur_num_search,:,:)./3e8*2*pi);
    
    est_likelihood(ii:ii+cur_num_search-1) = abs(sum(sum(abs(sum(recomputed_phasors,1)),3),4));
    %keyboard;
end
toc

[est_max, est_max_idx] = max(est_likelihood);
[est_x_idx, est_y_idx, est_z_idx] = ind2sub([length(x),length(y),length(z)],est_max_idx);
est_position = physical_search_space(est_max_idx,:);
est_likelihood = reshape(est_likelihood,[length(x),length(y),length(z)]);

%keyboard;

% physical_est = physical_search_space(1,:);
% physical_distances = zeros(size(anchor_positions,1),1);
% est_likelihood = zeros(size(physical_search_space,1),1);
% recomputed_phasors = zeros(size(square_phasors));
% for pos_idx=1:size(physical_search_space,1)
% 	physical_est = physical_search_space(pos_idx,:);
% 	for ii=1:size(anchor_positions,1)
% 		physical_distances(ii) = norm(physical_est-anchor_positions(ii,:));
% 		recomputed_phasors(ii,:,:) = square_phasors(ii,:,:) .* shiftdim(exp(-1i*physical_distances(ii)*harmonic_freqs_abs./3e8.*2*pi),-1)./abs(square_phasors(ii,:,:));
%     end
%     %Bring all anchors to a common center harmonic phase
%     %TODO: is this supposed to be a constant value?
%     %recomputed_phasors = recomputed_phasors.*repmat(exp(-1i*angle(recomputed_phasors(:,15,4))),[1,32,8]);
% 	est_likelihood(pos_idx) = abs(sum(sum(abs(sum(recomputed_phasors,1)),3)));
%     %keyboard;
% 	%disp(['cur_val = ', num2str(est_likelihood(pos_idx))])
% 	if mod(pos_idx,10000) == 0
% 		disp(['pos_idx = ', num2str(pos_idx)])
% 	end
% end



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