prf_anchor = 1;

%Start by searching for the apparent prf

format long;

if(full_search_flag)
	
	prf_est = prf;
	prf_lo = prf*(1-prf_accuracy);
	prf_hi = prf*(1+prf_accuracy);
	prf_coarse_step = prf*coarse_precision;
	prf_coarse_search = prf_lo:prf_coarse_step:prf_hi;
	
	corr_max = 0;
	prf_corr_max_idx = 1;
	cur_idx = 1;
	for prf_est = prf_coarse_search
		bb_tot = zeros(size(cur_data_iq,1),size(cur_data_iq,3));
		for cur_freq_step = 1:size(cur_iq_data,2)
			cur_corr = 0;
			calculateCenterFreqHarmonicNum;
			for harmonic_num = -num_harmonics_present/2+.5:num_harmonics_present/2-.5
				cur_bb = exp(-1i*(0:size(cur_iq_data,3)-1)*2*pi*(...
						prf_est*harmonic_num+...
						(prf_est-prf)*center_freq_harmonic_num-...
						tune_offset...
					)/(sample_rate/decim_factor));
				bb_tot(cur_freq_step,:) = bb_tot(cur_freq_step,:) + conj(cur_bb);
				cur_bb = cur_bb .* squeeze(cur_iq_data(prf_anchor,cur_freq_step, :)).';
				cur_corr = cur_corr + abs(sum(cur_bb));
			end
		end
		keyboard;

		if(cur_corr > corr_max)
			corr_max = cur_corr;
			prf_corr_max_idx = cur_idx;
		end
		cur_idx = cur_idx + 1;
	end
	
	prf_est = prf_coarse_search(prf_corr_max_idx);
end

prf_step = prf*fine_precision;

new_est = true;
cur_corr_max = 0;
step_sizes = [...
    -prf_step;...
    prf_step];
while new_est
	corr_max = 0;
	for cur_step_idx = 1:size(step_sizes,1)
		cur_corr = 0;
		bb_tot = zeros(size(cur_data_iq,1),size(cur_data_iq,3));
		for cur_freq_step = 1:size(cur_iq_data,2)
			calculateCenterFreqHarmonicNum;
			for harmonic_num = -num_harmonics_present/2+.5:num_harmonics_present/2-.5
				cur_bb = exp(-1i*(0:size(cur_iq_data,3)-1)*2*pi*(...
						(prf_est+step_sizes(cur_step_idx,1))*harmonic_num+...
						(prf_est+step_sizes(cur_step_idx,1)-prf)*center_freq_harmonic_num-...
						tune_offset...
					)/(sample_rate/decim_factor));
				bb_tot(cur_freq_step,:) = bb_tot(cur_freq_step,:) + conj(cur_bb);
				cur_bb = cur_bb .* squeeze(cur_iq_data(prf_anchor,cur_freq_step, :)).';
				
				cur_corr = cur_corr + abs(sum(cur_bb));
			end
		end
		
		if(cur_corr > corr_max)
			corr_max = cur_corr;
			corr_max_idx = cur_step_idx;
		end
	end
	
	if(corr_max > cur_corr_max)
		cur_corr_max = corr_max;
		prf_est = prf_est + step_sizes(corr_max_idx,1)
		new_est = true;
	else
		new_est = false;
	end
end

prf_est

%keyboard;
