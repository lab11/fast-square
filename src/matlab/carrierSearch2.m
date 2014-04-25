%size(cur_iq_data) = [<num_anchors>, <num_freq_steps>, <num_samples_per_step>]
carrier_segment = ceil(carrier_freq-start_freq)/step_freq+1;
if(~(carrier_segment <= num_steps && carrier_segment > 0))
    carrier_segment = 1;
end

%Start by searching for the apparent carrier offset contained within the segment which contains it
%The carrier isn't necessarily present because it gets attenuated by the COMB filter.
%However, it can be inferred by determinig which carrier offset best approximates expected square wave harmonics

format long;

if(full_search_flag)
	carrier_lo = carrier_freq*(-carrier_accuracy);
	carrier_hi = carrier_freq*(carrier_accuracy);
	carrier_coarse_step = carrier_freq*coarse_precision;
	carrier_coarse_search = carrier_lo:carrier_coarse_step:carrier_hi;
	
	corr_max = 0;
	carrier_corr_max_idx = 1;
	cur_idx = 1;
	for carrier_est = carrier_coarse_search
		cur_corr = 0;
		for harmonic_num = -num_harmonics_present:2:num_harmonics_present
			cur_bb = exp(-1i*(0:size(cur_iq_data,3)-1)*2*pi*(square_freq*harmonic_num+carrier_est)/(sample_rate/decim_factor));
			cur_bb = cur_bb .* squeeze(cur_iq_data(4,carrier_segment, :)).';
	
			cur_corr = cur_corr + abs(sum(cur_bb));
		end
	
		if(cur_corr > corr_max)
			corr_max = cur_corr;
			carrier_corr_max_idx = cur_idx;
		end
		cur_idx = cur_idx + 1;
	end
	
	carrier_est = carrier_coarse_search(carrier_corr_max_idx);
	square_lo = square_freq*(1-square_accuracy);
	square_hi = square_freq*(1+square_accuracy);
	square_coarse_step = square_freq*coarse_precision;
	square_coarse_search = square_lo:square_coarse_step:square_hi;
	
	corr_max = 0;
	square_corr_max_idx = 1;
	cur_idx = 1;
	for square_est = square_coarse_search
		for cur_freq_step = 1:size(cur_iq_data,2)
			cur_corr = 0;
			for harmonic_num = -num_harmonics_present:2:num_harmonics_present
				cur_bb = exp(-1i*(0:size(cur_iq_data,3)-1)*2*pi*(...
						square_est*harmonic_num+...
						carrier_est+...
						(carrier_segment-cur_freq_step)*(step_freq-square_est)*(step_freq/square_freq)...
					)/(sample_rate/decim_factor));
				cur_bb = cur_bb .* squeeze(cur_iq_data(4,cur_freq_step, :)).';
		
				cur_corr = cur_corr + abs(sum(cur_bb));
			end
		end
	
		if(cur_corr > corr_max)
			corr_max = cur_corr;
			square_corr_max_idx = cur_idx;
		end
		cur_idx = cur_idx + 1;
	end
	
	square_est = square_coarse_search(square_corr_max_idx);
	carrier_est = carrier_coarse_search(carrier_corr_max_idx);
end


% square_step = square_freq*fine_precision/10;
% new_est = true;
% cur_corr_max = 0;
% step_sizes = [...
% 		0, square_step;...
% 		0, -square_step;...
% 	];
% while new_est
%     corr_max = 0;
%     for cur_step_idx = 1:size(step_sizes,1)
%         cur_freq_step = carrier_segment;
%         bb_tot = zeros(1,size(cur_data_iq,3));
%         cur_corr = 0;
%         for harmonic_num = -num_harmonics_present:2:num_harmonics_present
%             cur_bb = exp(-1i*(0:size(cur_iq_data,3)-1)*2*pi*(...
%                 (square_est+step_sizes(cur_step_idx,2))*harmonic_num+...
%                 (carrier_est)...
%             )/(sample_rate/decim_factor));
%             bb_tot = bb_tot + conj(cur_bb);
%             cur_bb = cur_bb .* squeeze(cur_iq_data(4,carrier_segment, :)).';
% 
%             cur_corr = cur_corr + abs(sum(cur_bb));%sum(abs(fft(cur_bb))+abs(fft(conj(cur_bb))));
%         end
% 
%         if(cur_corr > corr_max)
%             corr_max = cur_corr;
%             corr_max_idx = cur_step_idx;
%         end
%     end
% 
%     if(corr_max > cur_corr_max)
% %         plot(abs(fft(bb_tot)));
% %         drawnow;
%         cur_corr_max = corr_max;
%         square_est = square_est + step_sizes(corr_max_idx,2)
%         new_est = true;
%     else
%         new_est = false;
%     end
% end

square_step = square_freq*fine_precision;

new_est = true;
cur_corr_max = 0;
step_sizes = [...
    0, -square_step;...
    0, square_step];
while new_est
    corr_max = 0;
    for cur_step_idx = 1:size(step_sizes,1)
        cur_corr = 0;
        bb_tot = zeros(size(cur_data_iq,1),size(cur_data_iq,3));
        for cur_freq_step = 1:size(cur_iq_data,2)
            for harmonic_num = -num_harmonics_present:2:num_harmonics_present
                cur_bb = exp(-1i*(0:size(cur_iq_data,3)-1)*2*pi*(...
                    (square_est+step_sizes(cur_step_idx,2))*harmonic_num+...
                    (carrier_est+step_sizes(cur_step_idx,1))+...
                    (carrier_segment-cur_freq_step)*(step_freq-(square_est+step_sizes(cur_step_idx,2))*(step_freq/square_freq))...
                )/(sample_rate/decim_factor));
                bb_tot(cur_freq_step,:) = bb_tot(cur_freq_step,:) + conj(cur_bb);
                cur_bb = cur_bb .* squeeze(cur_iq_data(4,cur_freq_step, :)).';

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
        square_est = square_est + step_sizes(corr_max_idx,2);
        new_est = true;
    else
        new_est = false;
    end
end

%Compare with the next timestep to see how far off the square frequency's
%estimate is
next_iq_data = squeeze(data_iq(:,:,cur_timepoint+1,:));
cur_phasors = zeros(num_harmonics_present+1,1);
next_phasors = zeros(num_harmonics_present+1,1);
harmonic_idx = 1;
for harmonic_num = -num_harmonics_present:2:num_harmonics_present
    cur_bb = exp(-1i*(0:size(cur_iq_data,3)-1)*2*pi*(...
        square_est*harmonic_num+...
        carrier_est...
    )/(sample_rate/decim_factor));
    cur_phasors(harmonic_idx) = sum(cur_bb.*squeeze(cur_iq_data(4,carrier_segment,:)).');
    next_phasors(harmonic_idx) = sum(cur_bb.*squeeze(next_iq_data(4,carrier_segment,:)).');
    
    %Add time delay to current_phasors in order to compare with next_phasors
    cur_phasors(harmonic_idx) = cur_phasors(harmonic_idx).*exp(1i*2*pi*(square_est*harmonic_num+carrier_est)/(sample_rate/decim_factor)*(ticks_per_sequence/decim_factor));
    
    harmonic_idx = harmonic_idx + 1;
end
corr_max = 0;
for phase_offset = -pi:0.1:pi
    for time_offset = -pi/2:0.001:pi/2
        cur_phasors_temp = cur_phasors.*exp(1i*phase_offset).*exp(1i*(-num_harmonics_present:2:num_harmonics_present)*time_offset).';
        cur_corr = sum(abs(cur_phasors_temp(3:6)+next_phasors(3:6)));
        if(cur_corr > corr_max)
            corr_max = cur_corr;
            phase_offset_max = phase_offset;
            time_offset_max = time_offset;
        end
    end
end

%Correct square_est based on time_offset_max
square_est = square_est/((ticks_per_sequence/sample_rate)/((ticks_per_sequence/sample_rate)+time_offset_max/2/pi/square_est));

% carrier_step = carrier_freq*fine_precision/10;
% new_est = true;
% cur_corr_max = 0;
% step_sizes = [...
% 		carrier_step, 0;...
% 		-carrier_step, 0;...
% 	];
% while new_est
%     corr_max = 0;
%     for cur_step_idx = 1:size(step_sizes,1)
%         cur_freq_step = carrier_segment;
%         cur_bb = exp(-1i*(0:size(cur_iq_data,3)-1)*2*pi*(...
%             (carrier_est+step_sizes(cur_step_idx,1))...
%         )/(sample_rate/decim_factor));
%         cur_bb = cur_bb .* squeeze(cur_iq_data(4,carrier_segment, :)).';
% 
%         cur_corr = sum(abs(fft(cur_bb))+abs(fft(conj(cur_bb))));
% 
%         if(cur_corr > corr_max)
%             corr_max = cur_corr;
%             corr_max_idx = cur_step_idx;
%         end
%     end
% 
%     if(corr_max > cur_corr_max)
%         cur_corr_max = corr_max;
%         carrier_est = carrier_est + step_sizes(corr_max_idx,1);
%         new_est = true;
%     else
%         new_est = false;
%     end
% end

%Perform gradient descent for carrier search
new_est = true;
cur_corr_max = 0;
step_sizes = [...
    carrier_step, 0;...
    -carrier_step, 0;...
];
while new_est
    corr_max = 0;
    for cur_step_idx = 1:size(step_sizes,1)
        cur_corr = 0;
        for harmonic_num = -num_harmonics_present:2:num_harmonics_present
            cur_bb = exp(-1i*(0:size(cur_iq_data,3)-1)*2*pi*(...
                (square_est+step_sizes(cur_step_idx,2))*harmonic_num+...
                (carrier_est+step_sizes(cur_step_idx,1))...
            )/(sample_rate/decim_factor));
            cur_bb = cur_bb .* squeeze(cur_iq_data(4,carrier_segment, :)).';

            cur_corr = cur_corr + abs(sum(cur_bb));
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


carrier_offset = carrier_est;
time_offset_max
carrier_est
square_est
