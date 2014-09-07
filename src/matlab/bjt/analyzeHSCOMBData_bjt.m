function ret = analyzeHSCOMBData_bjt(varargin)

p = inputParser;

defaultOperation = 'localization';
validOperations = {'localization','calibration'};
checkOperation = @(x) any(validatestring(x,validOperations));

defaultAnchor = 1;

addParamValue(p,'operation', defaultOperation, checkOperation);
addParamValue(p,'anchor', defaultAnchor, @isnumeric);

parse(p,varargin{:});
res = p.Results;

RECORD_TICKS = 35000;
total_ticks = RECORD_TICKS + 1 + 642 + 31;
ticks_per_sequence = 4096+total_ticks*32;


NUM_HIST = 10;

%Define constantsf for this implementation
start_lo_freq = 5.312e9;
if_freq_nom = 990e6;
tune_offset = 42e3;
start_freq = start_lo_freq + if_freq_nom;
step_freq = -32e6;
num_steps = 32;
sample_rate = 64e6;
decim_factor = 33; %DEPENDENT ON FREQ
prf = 4e6;
prf_accuracy = 20e-6;
coarse_precision = 1e-7;
fine_precision = 1e-9;
stream_decim = 33;
samples_per_freq = round(total_ticks/stream_decim);

use_image = true;
if(use_image)
	tune_offset = -tune_offset;
end

%Load calibration data
load if_cal

%Physical LO cable lengths
%lo_lengths = [1.524;1.524;2.1336;2.1336];
lo_lengths = [5.1816;1.524;2.1336;2.1336]; %New LO legths
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

% %These are the anchor positions in second placement -- coplanar along south wall
% anchor_positions = [...
%     0.890, 0.0, 0.3515;...
%     2.890, 0.0, 0.3515;...
%     3.828, 0.0, 0.0;...
%     0.0, 0.0, 0.0 ...
% ];

%These are the anchor positions in the third placement -- more spaced out
%in y and z directions
anchor_positions = [...
    2.405, 3.815, 2.992;...
    2.105, 0.034, 2.494;...
    4.108, 0.347, 1.543;...
    0.273, 0.343, 1.56 ...
];
num_anchors = size(anchor_positions,1);

%TODO: May need to selectively read parts of files since this is pretty memory-intense
smallest_num_timepoints = Inf;
for ii=1:size(anchor_positions,1)
	cur_data_iq = readHSCOMBData(['usrp_chan', num2str(ii-1), '.dat'],samples_per_freq);
	if(size(cur_data_iq,2) < smallest_num_timepoints)
		smallest_num_timepoints = size(cur_data_iq,2);
	end
end
data_iq = zeros(size(anchor_positions,1),size(cur_data_iq,1),smallest_num_timepoints,size(cur_data_iq,3));
for ii=1:size(anchor_positions,1)
    cur_data_iq = shiftdim(readHSCOMBData(['usrp_chan', num2str(ii-1), '.dat'],samples_per_freq));
    data_iq(ii,:,:,:) = cur_data_iq(:,1:smallest_num_timepoints,:);

end
if(use_image)
	data_iq = conj(data_iq);
end

%Construct a candidate search space over which to look for the tag
[x,y,z] = meshgrid(0:.05:4,0:.05:4,-.65);%-2:.05:2);
physical_search_space = [x(:),y(:),z(:)];

%Pre-calculate distances from each point on search space to corresponding
%anchors
anchor_positions_reshaped = reshape(anchor_positions,[size(anchor_positions,1),1,size(anchor_positions,2)]);
physical_distances = repmat(shiftdim(physical_search_space,-1),[size(anchor_positions,1),1,1])-repmat(anchor_positions_reshaped,[1,size(physical_search_space,1),1]);
physical_distances = sqrt(sum(physical_distances.^2,3));

%Figure out which harmonics are in each snapshot
num_harmonics_present = floor(sample_rate/prf);

cur_iq_data = squeeze(data_iq(:,:,1,:));
full_search_flag = true;
%Loop through each timepoint
tx_phasors = zeros(num_steps,num_harmonics_present);
temp_to_tx = zeros(32,num_harmonics_present,size(data_iq,3));
time_offset_maxs = [];
square_ests = [];
for cur_timepoint=10:size(data_iq,3)
    cur_iq_data = squeeze(data_iq(:,:,cur_timepoint,:));
    %Detect overflow issues
    overflow_sum = sum(abs(cur_iq_data),3);
    if find(overflow_sum == 0)
        continue
    end
    
    prfSearch;
    if cur_timepoint == 10
        prf_est_history = repmat(prf_est,[NUM_HIST,1]);
    else
        prf_est_history = [prf_est_history(2:NUM_HIST);prf_est];
    end
    prf_est = mean(prf_est_history);
%     square_ests = [square_ests,square_est];
%     time_offset_maxs = [time_offset_maxs,time_offset_max];
	harmonicExtraction_bjt;
    correctCOMBPhase;
    compensateRCLP;
    compensateRCHP;
    compensateStepTime;
%    processIFCal;
    correctIFCal;
%    compensateLOLength;
%    %compensateMovement;
     if(strcmp(operation,res.calibration))
         processDirectSquare_bjt;%ONLY FOR CALIBRATION DATA
         temp_to_tx(:,:,cur_timepoint) = angle(temp_phasors)-angle(tx_phasors);
     else
     end
%     deconvolveSquare;
%    %keyboard;
%    
%	%harmonicCalibration;
%
%	%harmonicLocalization_r5;
%    %keyboard;
%    
%	%keyboard;
%	save(['timestep',num2str(cur_timepoint)], 'carrier_offset', 'square_est', 'square_phasors', 'tx_phasors');%, 'time_offset_max', 'est_position', 'imp_toas', 'imp');%, 'est_likelihood', 'time_offset_max');
	save(['timestep',num2str(cur_timepoint)],'prf_est');
	full_search_flag = false;
    disp(['done with timepoint ', num2str(cur_timepoint)])
end

