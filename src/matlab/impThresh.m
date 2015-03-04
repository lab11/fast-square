function ret = impThresh(imp, thresh);

gt_thresh = [0, find(abs(imp) > thresh)];
gt_thresh(1) = gt_thresh(end)-length(imp);
gt_thresh_diff = diff(gt_thresh);
[~,gt_thresh_diff_max] = max(gt_thresh_diff);
ret = gt_thresh(gt_thresh_diff_max+1);
