RECORD_TICKS = 35000;
total_ticks = RECORD_TICKS + 1 + 642 + 31;

%data_iq0 = readHSData('usrp_chan0.dat');
%data_iq1 = readHSData('usrp_chan1.dat');
%data_iq2 = readHSData('usrp_chan2.dat');
data_iq3 = readHSCOMBData('usrp_chan3.dat');

%Define constantsf for this implementation
start_lo_freq = 5.312e9;
if_freq = 960e6;
start_freq = start_lo_freq + if_freq;
step_freq = -32e6;
sample_rate = 64e6;
decim_factor = 17;
carrier_freq = 5.792e9;
square_freq = 4e6;
square_accuracy = 10e-6;
square_measurement_precision = 1e-7;
carrier_accuracy = 10e-6;
carrier_measurement_precision = 1e-7;

anchor_positions = [...
	0.8889, 0.0, 0.3579;...
	2.8938, 0.0, 0.3596;...
	3.829, 0.0, 0.0;...
	0.0, 0.0, 0.0 ...
];

%Loop through each timepoint
for ii=1:size(data_iq3,2)
	cur_iq_data = squeeze(data_iq3(:,ii,:));

	%size(cur_iq_data) = [<num_freq_steps>, <num_samples_per_step>]
	carrier_segment = ceil(carrier_freq-(start_freq-sample_rate/2))/step_freq+1;

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

	carrier_idx = 1;
	for carrier_est = carrier_search
		square_idx = 1;
		for square_est = square_search
			square_decim_freq = square_est;
			num_present_harmonics = floor((sample_rate-square_est)/(square_est*2));

			cur_corr = 0;
			for harmonic_num = -num_present_harmonics:2:num_present_harmonics
				cur_bb = exp(1i*(1:size(cur_iq_data,2))*2*pi*(square_decim_freq*harmonic_num+carrier_est)/(sample_rate/decim_factor));
				cur_bb = cur_bb .* cur_iq_data(carrier_segment, :);

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
	carrier_offset = carrier_search(carrier_idx);
	square_est = square_search(square_idx);

	%Extract amplitude, phase measurements from entire dataset
	num_harmonics_present = floor((sample_rate-square_est)/(square_est*2));
	square_phasors = zeros(size(cur_iq_data,1),num_harmonics_present);
	for cur_freq_step = 1:size(cur_iq_data,1)
		cur_square_freqs = (square_freq+step_freq*(carrier_segment-1))+carrier_offset;
		harmonic_idx = 1;
		for harmoic_num = -num_present_harmonics:2:num_present_harmonics
			cur_bb = exp(1i*(1:size(cur_iq_data,2))*2*pi*(square_est*harmonic_num+carrier_offset)/(sample_rate/decim_factor));
			square_phasors(cur_freq_step,harmonic_idx)  = cur_bb .* cur_iq_data(cur_freq_step, :);
			harmonic_idx = harmonic_idx + 1;
		end
	end
	
	%Extract apparent length of LO cable from successive inter-segment phase measurements
	lo_cable_length = square_phasors(carrier_segment,)-square_phasors(carrier_segment+1,)
	
	%Perform localization operations
	physical_est = physical_search_space(1,:);
	physical_distances = zeros(size(anchor_positions,1),1);
	est_likelihood = zeros(size(physical_search_space,1),1);
	for pos_idx=1:size(physical_search_space,1)
		physical_est = physical_search_space(1,:);
		for ii=1:size(anchor_positions,1)
			physical_distances(ii) = norm(physical_est-anchor_positions(ii,:));
			recomputed_phasors(ii,:) = square_phasors(ii,:) .* exp(-1i*physical_distances(ii)*harmonic_freqs(:)./3e8.*2*pi);
		end
		est_likelihood(pos_idx) = sum(sum(recomputed_phasors,1),2);
	end

	keyboard;
end

num_steps = 32;

clear data data_iq data_iq_baseband
