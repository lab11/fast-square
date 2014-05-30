function ret = calculateAnchorErrors(anchor_locs, actual_node_pos, measured_toas)

%Normalize measured_toas to first anchor
measured_toas = measured_toas-measured_toas(1);

%Calculate expected toas
expected_toas = sqrt(sum((anchor_locs-repmat(actual_node_pos,[size(anchor_locs,1),1])).^2,2));
expected_toas = expected_toas-expected_toas(1);

ret = measured_toas-expected_toas;