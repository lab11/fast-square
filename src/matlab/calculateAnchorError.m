function ret = calculateAnchorError(real_position, anchor_positions, anchor_toas)

%real_position = [2.695,2.46,0];

anchor_distances = sqrt(sum((anchor_positions-repmat(real_position,[size(anchor_positions,1),1])).^2,2));
ret = anchor_toas-anchor_distances;
