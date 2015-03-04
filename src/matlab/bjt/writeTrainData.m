
pos = est_positions*100;
pos = pos - repmat([182.88, 203.2, 86.36],[size(est_positions,1),1]);
pos = [-pos(:,2), -pos(:,1), pos(:,3)];

dlmwrite('real_data_raw.txt', pos, ' ');
