RECORD_TICKS = 35000;
total_ticks = RECORD_TICKS + 1 + 642 + 31;

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

%TODO: May need to selectively read parts of files since this is pretty memory-intense
smallest_num_timepoints = Inf;
for ii=1:size(anchor_positions,1)
	cur_data_iq = readHSCOMBData(['usrp_chan', num2str(ii-1), '.dat']);
	if(size(cur_data_iq,2) < smallest_num_timepoints)
		smallest_num_timepoints = size(cur_data_iq,2);
	end
end
data_iq = zeros(size(anchor_positions,1),size(cur_data_iq,1),smallest_num_timepoints,size(cur_data_iq,3));
for ii=1:size(anchor_positions,1)
	data_iq(ii,:,:,:) = shiftdim(readHSCOMBData(['usrp_chan', num2str(ii-1), '.dat']),-1);
end

%Construct a candidate search space over which to look for the tag
[x,y,z] = meshgrid(0:.05:4,0:.05:4,-2:.05:2);
physical_search_space = [x(:),y(:),z(:)];

%Figure out which harmonics are in each snapshot
num_harmonics_present = floor((sample_rate-square_freq)/(square_freq*2));
harmonic_freqs = zeros(size(data_iq,2),num_harmonics_present+1);
for ii=1:size(harmonic_freqs,1)
	harmonic_freqs(ii,:) = start_lo_freq+if_freq+(-num_harmonics_present:2:num_harmonics_present)*square_freq+step_freq*(ii-1);
end


%Loop through each timepoint
for cur_timepoint=1:size(data_iq,2)
	cur_iq_data = squeeze(data_iq(:,:,cur_timepoint,:));

	carrierSearch;

	harmonicExtraction;
    
    keyboard;
    
    harmonicCalibration;

	%harmonicLocalization;
    
    %keyboard;
    save(['timestep',num2str(cur_timepoint)], 'est_likelihood', 'est_position', 'carrier_offset', 'square_est', 'square_phasors', 'phase_step');
end

num_steps = 32;

clear data data_iq data_iq_baseband
