tic
est_likelihood = zeros(size(physical_search_space,1),1);
chunk_size = 10e3;
harmonic_freqs_abs_rep = repmat(shiftdim(harmonic_freqs_abs,-2),[size(anchor_positions,1),chunk_size,1,1]);
%Perform localization operations, breaking up into chunks which are small enough
for ii=1:chunk_size:size(physical_search_space,1)
    if ii+chunk_size < size(physical_search_space,1)
        cur_num_search = chunk_size;
    else
        cur_num_search = size(physical_search_space,1)-ii+1;
    end
    
    %Perform localization operations
    square_phasors_reshaped = reshape(square_phasors_deconv,[size(square_phasors,1),1,size(square_phasors,2),size(square_phasors,3)]);
    recomputed_phasors = repmat(square_phasors_reshaped,[1,cur_num_search,1,1]);
    
    recomputed_phasors = recomputed_phasors./abs(recomputed_phasors);
    
    recomputed_phasors = recomputed_phasors.*exp(-1i*repmat(physical_distances(:,ii:ii+cur_num_search-1),[1,1,size(recomputed_phasors,3),size(recomputed_phasors,4)]).*harmonic_freqs_abs_rep(:,1:cur_num_search,:,:)./3e8*2*pi);
    recomputed_phasors = recomputed_phasors.*conj(repmat(recomputed_phasors(1,:,:,:),[4,1,1,1]));
    
    recomputed_phasors_temp = recomputed_phasors;
    best_sum = zeros(1,size(recomputed_phasors,2));
    for second_phase = 0:7
        recomputed_phasors_temp(2,:,:,:) = recomputed_phasors(2,:,:,:)*exp(1i*second_phase*2*pi/8);
        for third_phase = 0:7
            recomputed_phasors_temp(3,:,:,:) = recomputed_phasors(3,:,:,:)*exp(1i*third_phase*2*pi/8);
            for fourth_phase = 0:7
                recomputed_phasors_temp(4,:,:,:) = recomputed_phasors(4,:,:,:)*exp(1i*fourth_phase*2*pi/8);
                phasors_sum = sum(abs(sum(sum(recomputed_phasors,4),1)),3);
                
                best_sum = max(phasors_sum, best_sum);
            end
        end
    end
    
    est_likelihood(ii:ii+cur_num_search-1) = best_sum;%sum(sum(abs(sum(recomputed_phasors,4)),1),3);
    %keyboard;
end
toc

[est_max, est_max_idx] = max(est_likelihood);
[est_x_idx, est_y_idx, est_z_idx] = ind2sub(size(x),est_max_idx);
est_position = physical_search_space(est_max_idx,:);
est_likelihood = reshape(est_likelihood,size(x));

%Look at how phasors align at the 'known' tag location
actual_ranges = [3.632;3.398;3.593;4.003];
actual_phases = repmat(actual_ranges,[1,size(square_phasors,2),size(square_phasors,3)]).*repmat(shiftdim(harmonic_freqs_abs,-1),[size(anchor_positions,1),1,1])./3e8*2*pi;
actual_recomputed = square_phasors.*exp(-1i*actual_phases);