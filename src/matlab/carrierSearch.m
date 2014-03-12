%size(cur_iq_data) = [<num_anchors>, <num_freq_steps>, <num_samples_per_step>]
carrier_segment = ceil(carrier_freq-start_freq)/step_freq+1;

%Start by searching for the apparent carrier offset contained within the segment which contains it
%The carrier isn't necessarily present because it gets attenuated by the COMB filter.
%However, it can be inferred by determinig which carrier offset best approximates expected square wave harmonics

carrier_lo = carrier_freq*(-carrier_accuracy);
carrier_hi = carrier_freq*(carrier_accuracy);
carrier_coarse_step = carrier_freq*carrier_coarse_measurement_precision;
carrier_coarse_search = carrier_lo:carrier_coarse_step:carrier_hi;

corr_max = 0;
corr_max_idx = 1;
cur_idx = 1;
for carrier_est = carrier_coarse_search
	cur_corr = 0;
	for harmonic_num = -num_harmonics_present:2:num_harmonics_present
		cur_bb = exp(-1i*(0:size(cur_iq_data,3)-1)*2*pi*(square_freq*harmonic_num+carrier_est)/(sample_rate/decim_factor));
		cur_bb = cur_bb .* squeeze(cur_iq_data(1,carrier_segment, :)).';

		cur_corr = cur_corr + abs(sum(cur_bb));
	end

	if(cur_corr > corr_max)
		corr_max = cur_corr;
		corr_max_idx = cur_idx;
	end
	cur_idx = cur_idx + 1;
end

%Perform gradient descent
square_est = square_freq;
carrier_est = carrier_coarse_search(corr_max_idx);
for precision = [coarse_precision,fine_precision]
	carrier_fine_step = carrier_freq*fine_precision;
	square_fine_step = square_freq*precision;
	step_sizes = [...
		-carrier_fine_step, square_fine_step;...
		0, square_fine_step;...
		carrier_fine_step, square_fine_step;...
		carrier_fine_step, 0;...
		carrier_fine_step, -square_fine_step;...
		0, -square_fine_step;...
		-carrier_fine_step, -square_fine_step;...
		-carrier_fine_step, 0;...
	];
	new_est = true;
	cur_corr_max = 0;
	while new_est
		corr_max = 0;
		for cur_step_idx = 1:size(step_sizes,1)
			cur_corr = 0;
			for cur_freq_step = 1:size(cur_iq_data,2)
				for harmonic_num = -num_harmonics_present:2:num_harmonics_present
					cur_bb = exp(-1i*(0:size(cur_iq_data,3)-1)*2*pi*(...
						(square_est+step_sizes(cur_step_idx,2))*harmonic_num+...
						(carrier_est+step_sizes(cur_step_idx,1))+...
						(carrier_segment-cur_freq_step)*(step_freq-(square_est+step_sizes(cur_step_idx,2))*(step_freq/square_freq))...
					)/(sample_rate/decim_factor));
					cur_bb = cur_bb .* squeeze(cur_iq_data(1,cur_freq_step, :)).';
			
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
			carrier_est = carrier_est + step_sizes(corr_max_idx,1);
			square_est = square_est + step_sizes(corr_max_idx,2);
			new_est = true;
		else
			new_est = false;
		end
	end
end
carrier_est
square_est
