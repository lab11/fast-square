%size(cur_iq_data) = [<num_anchors>, <num_freq_steps>, <num_samples_per_step>]
carrier_segment = ceil(carrier_freq-start_freq)/step_freq+1;

%Start by searching for the apparent carrier offset contained within the segment which contains it
%The carrier isn't necessarily present because it gets attenuated by the COMB filter.
%However, it can be inferred by determinig which carrier offset best approximates expected square wave harmonics

carrier_lo = carrier_freq*(-carrier_accuracy);
carrier_hi = carrier_freq*(carrier_accuracy);
carrier_step = carrier_freq*carrier_measurement_precision;
square_lo = square_freq*(1-square_accuracy);
square_hi = square_freq*(1+square_accuracy);
square_step = square_freq*square_measurement_precision;
carrier_search = carrier_lo:carrier_step:carrier_hi;
square_search = square_lo:square_step:square_hi;

corr_tot = zeros(length(carrier_search), length(square_search));

carrier_idx = 1;
for carrier_est = carrier_search
	square_idx = 1;
	for square_est = square_search
		square_decim_freq = square_est;

		cur_corr = 0;
		for harmonic_num = -num_harmonics_present:2:num_harmonics_present
			cur_bb = exp(-1i*(0:size(cur_iq_data,3)-1)*2*pi*(square_decim_freq*harmonic_num+carrier_est)/(sample_rate/decim_factor));
			cur_bb = cur_bb .* squeeze(cur_iq_data(1,carrier_segment, :)).';

			cur_corr = cur_corr + abs(sum(cur_bb));
		end
	
		corr_tot(carrier_idx, square_idx) = cur_corr;
		square_idx = square_idx + 1;
	end
	carrier_est
	carrier_idx = carrier_idx + 1;
end

%Find max correlation
[carrier_idx, square_idx] = find(corr_tot == max(max(corr_tot)));
carrier_idx = carrier_idx(end);
square_idx = square_idx(end);
carrier_offset = carrier_search(carrier_idx);
square_est = square_search(square_idx);


