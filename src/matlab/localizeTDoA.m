function ret = localizeTDoA(anchor_positions, imp_toas, est_position_start, position_step)

%Iteratively minimize the MSE between the position estimate and all TDoA
%measurements
est_position = est_position_start;
poss_steps = PermsRep([-position_step, 0, position_step], 3);
new_est = true;
best_error = Inf;
while new_est
    cur_best_error = best_error;
    cur_best_error_idx = 1;
    for ii=1:size(poss_steps,1)
        cand_position = est_position + poss_steps(ii,:);
        cand_error = calculatePositionError(cand_position, anchor_positions, imp_toas, true);
        
        if cand_error < cur_best_error
            cur_best_error = cand_error;
            cur_best_error_idx = ii;
        end
    end
    
    if cur_best_error < best_error
        best_error = cur_best_error;
        est_position = est_position + poss_steps(cur_best_error_idx,:);
        new_est = true;
    else
        new_est = false;
    end
    
    if(sqrt(sum(est_position.^2)) > 10)
        est_position = [0, 0, 0];
        break;
    end
end

ret = est_position;