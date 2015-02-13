anchor_positions = [...
    2.405, 3.815, 2.992;...
    2.105, 0.034, 2.494;...
    4.108, 0.347, 1.543;...
    0.273, 0.343, 1.56 ...
];

imp_toas_ave = [23.7995;-0.1361;-6.0701;0];
anchor_errors = calculateAnchorError([2.275,2.237,1.004],anchor_positions,imp_toas_ave);
save anchor_errors anchor_errors

num_timesteps = 122;

load timestep2
harmonicLocalization_r6
sprs_idx = 1;
ep_idx = 1;
imp_toas_hist = zeros(4,num_timesteps);
est_positions = zeros(num_timesteps,3);
for ii=3:num_timesteps
try
	load(['timestep',num2str(ii)]);
	harmonicLocalization_r6
	imp_toas_hist(:,sprs_idx) = imp_toas-imp_toas(2);
	%if(sprs_idx == 1150)
	%	ii
	%end
	imp_toas = imp_toas - anchor_errors;
	
	%Iteratively minimize the MSE between the position estimate and all TDoA
	%measurements
	est_position = [0,0,0];
	position_step = 0.001;
	poss_steps = PermsRep([-position_step, 0, position_step], 3);
	new_est = true;
	best_error = Inf;
	while new_est
	    cur_best_error = best_error;
	    cur_best_error_idx = 1;
	    for jj=1:size(poss_steps,1)
	        cand_position = est_position + poss_steps(jj,:);
	        cand_error = calculatePositionError(cand_position, anchor_positions, imp_toas, true);
	        
	        if cand_error < cur_best_error
	            cur_best_error = cand_error;
	            cur_best_error_idx = jj;
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
	if(sum(abs(est_position)) > 0)
		est_positions(ep_idx,:) = est_position;
		ep_idx = ep_idx + 1;
	end
	sprs_idx = sprs_idx + 1;
	ii
catch
end
end

train_data = (est_positions(1:ep_idx-1,:)-repmat([2.695,2.460,0],[ep_idx-1,1]))*100;
train_data = [-train_data(:,2),-train_data(:,1),train_data(:,3)];

dlmwrite('real_data.txt',train_data,' ');
