%This script attempts to determine the best placement of anchors in a TDoA 
% localization system if they are all constrained to the same plane (e.g.
% situated on the ceiling)

c = 299792458;

num_anchors = 4;
anchor_height = 2;
anchor_area_side = 2;
num_trials = 10e3;
noise_amp = 0.001;
step_size = 0.05;

round = 2;
if round == 2
    load best_mse
else
    best_anchor_positions = zeros(num_anchors,3);
end
best_mse = Inf;

real_pos = [0,0,0];
while true
    if round == 2
        cand_anchor_pos = best_anchor_positions + [randn(num_anchors,2)*step_size,zeros(num_anchors,1)];
        cand_anchor_pos(:,1:2) = min(cand_anchor_pos(:,1:2),anchor_area_side/2);
        cand_anchor_pos(:,1:2) = max(cand_anchor_pos(:,1:2),-anchor_area_side/2);
    else
        cand_anchor_pos = [rand(num_anchors,2)*anchor_area_side-anchor_area_side/2,ones(num_anchors,1)*anchor_height];
    end
    %cand_anchor_pos = [1,1,2;0,0,2;1,-1,2;-1,-1,2];
    cand_toas = sqrt(sum((cand_anchor_pos-repmat(real_pos,[num_anchors,1])).^2,2));
    
    %Perform monte carlo simulation with noisy toas
    cand_position_errors = zeros(num_trials,1);
    toa_errors = randn(num_trials,num_anchors)*noise_amp;
    for ii=1:size(toa_errors,1)
        cur_toas = cand_toas + toa_errors(ii,:).';
        est_position = TDOALoc4(cand_anchor_pos,cur_toas/c*1e9);%localizeTDoA(cand_anchor_pos, cur_toas, real_pos, 0.001);
        cand_position_errors(ii) = min(sqrt(sum((real(est_position)-repmat(real_pos,[2,1])).^2)));
        %ii
    end
    
    cur_mse = mean(cand_position_errors.^2)
    if cur_mse < best_mse
        best_mse = cur_mse
        best_anchor_positions = cand_anchor_pos;
        save best_mse best_mse best_anchor_positions
    end
end
localizeTDoA(anchor_positions, imp_toas, est_position_start, position_step)