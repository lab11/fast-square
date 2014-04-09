physical_est = physical_search_space(1,:);
physical_distances = zeros(size(anchor_positions,1),1);
est_likelihood = zeros(size(physical_search_space,1),1);
recomputed_phasors = zeros(size(square_phasors));
for pos_idx=3872%1:size(physical_search_space,1)
	physical_est = physical_search_space(pos_idx,:);
	for ii=1:size(anchor_positions,1)
		physical_distances(ii) = norm(physical_est-anchor_positions(ii,:));
		recomputed_phasors(ii,:,:) = square_phasors(ii,:,:) .* shiftdim(exp(-1i*physical_distances(ii)*harmonic_freqs_abs./3e8.*2*pi),-1);
    end
    
    %Find phase offset of nodes 2-4 which maximizes max amplitude of
    %derived impulse response
    best_likelihood = 0;
    recomputed_phasors2 = recomputed_phasors(:,:,3:6);
    recomputed_phasors2 = flipdim(recomputed_phasors2, 2);
    recomputed_phasors2 = permute(recomputed_phasors2, [1, 3, 2]);
    recomputed_phasors2 = reshape(recomputed_phasors2,[size(recomputed_phasors2,1),size(recomputed_phasors2,2)*size(recomputed_phasors2,3)]);
    
    %modified fftshift to put DC at index 0
    recomputed_phasors2 = [recomputed_phasors2(:,67:end),recomputed_phasors2(:,1:66)];
    
    %Add in zeros to get accurate representation of square
    recomputed_phasors2 = [zeros(4,128);recomputed_phasors2];
    recomputed_phasors2 = reshape(recomputed_phasors2,[4,256]);

    recomputed_phasors_temp = recomputed_phasors2;
    for second_phase = 0:7
        recomputed_phasors_temp(2,:) = recomputed_phasors2(2,:)*exp(1i*second_phase*2*pi/8);
        for third_phase = 0:7
            recomputed_phasors_temp(3,:) = recomputed_phasors2(3,:)*exp(1i*third_phase*2*pi/8);
            for fourth_phase = 0:7
                recomputed_phasors_temp(4,:) = recomputed_phasors2(4,:)*exp(1i*fourth_phase*2*pi/8);
                phasors_sum = sum(recomputed_phasors_temp,1);
                
                %Calculate impulse responses based on phasors_sum
                %TODO: Figure out what the noise is in the system
                square_snr_temp = abs(phasors_sum)./square_snr;
                first_imp = ifft(wienerDe(phasors_sum, squeeze(recomputed_phasors_temp(1,:)), square_snr_temp));
                second_imp = ifft(wienerDe(phasors_sum, squeeze(recomputed_phasors_temp(2,:)), square_snr_temp));
                third_imp = ifft(wienerDe(phasors_sum, squeeze(recomputed_phasors_temp(3,:)), square_snr_temp));
                fourth_imp = ifft(wienerDe(phasors_sum, squeeze(recomputed_phasors_temp(4,:)), square_snr_temp));
                
                %Find the likelihood (=sum of largest imp peaks)
                %cur_likelihood = max(abs(first_imp) + abs(second_imp) + abs(third_imp) + abs(fourth_imp));
                cur_likelihood = impUpRatio(abs(first_imp) + abs(second_imp) + abs(third_imp) + abs(fourth_imp),10);
                
                if(cur_likelihood > best_likelihood)
                    keyboard;
                    best_likelihood = cur_likelihood;
                end
            end
        end
    end
    
	est_likelihood(pos_idx) = best_likelihood;
    
	%if mod(pos_idx,10000) == 0
		disp(['pos_idx = ', num2str(pos_idx)])
	%end
end