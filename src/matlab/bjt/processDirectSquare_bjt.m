%Figure out how much time shift is present before adding to tx_phasors
square_phasors_norm = square_phasors./abs(square_phasors);
tx_phasors_temp = squeeze(tx_phasors(prf_anchor,:,:));
if max(tx_phasors_temp(:)) == 0
	tx_phasors(prf_anchor,:,:) = square_phasors(prf_anchor,:,:);
	temp_phasors = tx_phasors_temp;
else
	disp('got here')
    
	tx_phasors_norm = tx_phasors_temp./abs(tx_phasors_temp);
	
	max_corr = 0;
	max_corr_delay = 0;
	max_corr_offset = 0;
	for time_delay=0:1/prf/5000:1/prf
	    temp_phasors = squeeze(square_phasors_norm(prf_anchor,:,:)).*exp(1i*time_delay*harmonic_freqs_abs(:,:).*(2*pi));
	    cur_corr = abs(sum(sum(temp_phasors.*conj(tx_phasors_norm))));
	    cur_offset = angle(sum(sum(temp_phasors.*conj(tx_phasors_norm))));
	    if(cur_corr > max_corr)
	        max_corr = cur_corr;
	        max_corr_delay = time_delay;
	        max_corr_offset = cur_offset;
	    end
	end
	
	temp_phasors = squeeze(square_phasors(prf_anchor,:,:)).*exp(1i*max_corr_delay*harmonic_freqs_abs.*(2*pi));
	temp_phasors = temp_phasors.*exp(-1i*max_corr_offset);
	
	tx_phasors(prf_anchor,:,:) = tx_phasors_temp + temp_phasors;
end
