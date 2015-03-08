function ret = tdoaNewtonError(pos, t, toas, anchor_positions)

num_anchors = size(anchor_positions,1);

ret = sum((sqrt(sum((repmat(pos,[num_anchors,1])-anchor_positions).^2,2)) - (toas-repmat(t,[num_anchors,1]))).^2);
%keyboard;
