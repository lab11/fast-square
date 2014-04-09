RECORD_TICKS = 35000;
total_ticks = RECORD_TICKS + 1 + 642 + 31;

%Define constantsf for this implementation
start_lo_freq = 5.312e9;
if_freq = 960e6;
start_freq = start_lo_freq + if_freq;
step_freq = -32e6;
num_steps = 32;
sample_rate = 64e6;
decim_factor = 17;
carrier_freq = 5.792e9;
square_freq = 4e6;
square_accuracy = 30e-6;
carrier_accuracy = 10e-6;
coarse_precision = 1e-7;
fine_precision = 1e-9;

%Load calibration data
load if_cal

%Physical LO cable lengths
lo_lengths = [1.524;1.524;2.1336;2.1336];
%Apparent lengths are longer since light travels slower in cables
%Velocity through CA-400: 85%
lo_lengths = lo_lengths/0.85;

% %These are old anchor positions
% anchor_positions = [...
% 	0.8889, 0.0, 0.3579;...
% 	2.8938, 0.0, 0.3596;...
% 	3.829, 0.0, 0.0;...
% 	0.0, 0.0, 0.0 ...
% ];

%These are the new anchor positions
anchor_positions = [...
    0.890, 0.0, 0.3515;...
    2.890, 0.0, 0.3515;...
    3.828, 0.0, 0.0;...
    0.0, 0.0, 0.0 ...
];
num_anchors = size(anchor_positions,1);

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
    cur_data_iq = shiftdim(readHSCOMBData(['usrp_chan', num2str(ii-1), '.dat']));
    data_iq(ii,:,:,:) = cur_data_iq(:,1:smallest_num_timepoints,:);

end

%Construct a candidate search space over which to look for the tag
[x,y,z] = meshgrid(0:.05:4,0:.05:4,-.7);%-2:.05:2);
physical_search_space = [x(:),y(:),z(:)];

%Pre-calculate distances from each point on search space to corresponding
%anchors
anchor_positions_reshaped = reshape(anchor_positions,[size(anchor_positions,1),1,size(anchor_positions,2)]);
physical_distances = repmat(shiftdim(physical_search_space,-1),[size(anchor_positions,1),1,1])-repmat(anchor_positions_reshaped,[1,size(physical_search_space,1),1]);
physical_distances = sqrt(sum(physical_distances.^2,3));

%Figure out which harmonics are in each snapshot
num_harmonics_present = floor((sample_rate-square_freq)/(square_freq*2));

cur_iq_data = squeeze(data_iq(:,:,1,:));
full_search_flag = true;
%Loop through each timepoint
tx_phasors = zeros(num_steps,num_harmonics_present+1);
for cur_timepoint=2:size(data_iq,3)
	cur_iq_data = squeeze(data_iq(:,:,cur_timepoint,:));
	carrierSearch;
	harmonicExtraction;
    correctCOMBPhase;
    compensateRCLP;
    compensateRCHP;
    compensateStepTime;
    %processIFCal;
    correctIFCal;
    compensateLOLength;
    %processDirectSquare;
    deconvolveSquare;
    keyboard;
    
	%harmonicCalibration;

	%harmonicLocalization_r3;
    
	%keyboard;
	%save(['timestep',num2str(cur_timepoint)], 'carrier_offset', 'square_est', 'square_phasors', 'est_position', 'est_likelihood');
	full_search_flag = false;
    disp(['done with timepoint ', num2str(cur_timepoint)])
end

