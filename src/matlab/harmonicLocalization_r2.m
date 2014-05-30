%Start by normalizing the phasors
%square_phasors = square_phasors./abs(square_phasors);

%Create (num_anchors choose 2) difference-based measurements
anchor_pairs = combnk(1:num_anchors,2);
pair_diffs = zeros(size(anchor_pairs,1),128);
for ii=1:size(anchor_pairs,1)
    %Calculate this pair's difference
    cur_pair_diff = squeeze(square_phasors(anchor_pairs(ii,2),:,:)./square_phasors(anchor_pairs(ii,1),:,:));%squeeze(square_phasors(anchor_pairs(ii,2),:,:).*conj(square_phasors(anchor_pairs(ii,1),:,:)));
    
    %For now, just pay attention to square phasors indexed 3-6
    % (1,2,7,8) are valid as well, but repeated elsewhere.  May be a good
    % idea to use them in the future to improve SNR
    cur_pair_diff = cur_pair_diff(1:32,3:6);
    
    %Flip to make consecutive phasors consistent
    cur_pair_diff = flipud(cur_pair_diff).';
    cur_pair_diff = cur_pair_diff(:);
    
    pair_diffs(ii,:) = cur_pair_diff;
end
keyboard;