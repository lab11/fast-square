INTERP = 64;

%This does localization via analysis of the impulse response at each antenna
square_phasors_reshaped = flipdim(square_phasors(:,:,3:6),2);
square_phasors_reshaped = permute(square_phasors_reshaped,[1,3,2]);
square_phasors_reshaped = reshape(square_phasors_reshaped,[size(square_phasors_reshaped,1),size(square_phasors_reshaped,2)*size(square_phasors_reshaped,3)]);

%Rearrange so DC is at zero
square_phasors_reshaped = [square_phasors_reshaped(:,67:end),square_phasors_reshaped(:,1:66)];

%Perform same rearrangements to tx_phasors
tx_phasors = flipud(tx_phasors(:,3:6)).';
tx_phasors = tx_phasors(:);
tx_phasors = [tx_phasors(67:end);tx_phasors(1:66)];

%Calculate ToAs and the corresponding impulse response
[imp_toas, imp] = extractToAs(square_phasors_reshaped, tx_phasors);

%Convert imp_toas to meters
imp_toas = imp_toas/(2*square_est*size(square_phasors_reshaped,2))/INTERP*3e8;

%Uncomment for anchor error calculation
%keyboard;

load anchor_errors
imp_toas = imp_toas - anchor_errors;

%Iteratively minimize the MSE between the position estimate and all TDoA
%measurements
est_position = [0,0,0];
position_step = 0.01;
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