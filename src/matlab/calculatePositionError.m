function ret = calculatePositionError(cand_pos, anchor_pos, anchor_toas, tdoa_flag)

%Calculate the distance from the candidate position
cand_pos_rep = repmat(cand_pos,[size(anchor_pos,1),1]);
cand_dist = sqrt(sum((anchor_pos-cand_pos_rep).^2,2));

%TDoA implies only differences in time are useful, so normalize to the
%first node
if(tdoa_flag)
    cand_dist = cand_dist - cand_dist(1);
    anchor_toas = anchor_toas - anchor_toas(1);
end

%Create a metric based on the difference between the candidate distances
%and the observed distances
errors = cand_dist-anchor_toas;
ret = sum(errors.^2);