function ret = analyzeHSCOMBData_bjt(varargin)

p = inputParser;

defaultOperation = 'localization';
validOperations = {'localization','calibration','toa_calibration','post_localization'};
checkOperation = @(x) any(validatestring(x,validOperations));

defaultAnchor = 1;
defaultIFFreq = 990e6;
defaultCalLocation = [0 0 0];

addParamValue(p,'operation', defaultOperation, checkOperation);
addParamValue(p,'anchor', defaultAnchor, @isnumeric);
addParamValue(p,'if_freq', defaultIFFreq, @isnumeric);
addParamValue(p,'toa_cal_location', defaultCalLocation, @ismatrix);

parse(p,varargin{:});
res = p.Results;

RECORD_TICKS = 35000;
total_ticks = RECORD_TICKS + 1 + 642 + 31;
ticks_per_sequence = 4096+total_ticks*32;


NUM_HIST = 10;

%Define constantsf for this implementation
start_lo_freq = 5.312e9;
if_freq = res.if_freq;
tune_offset = 42e3;
start_freq = start_lo_freq + if_freq;
step_freq = -32e6;
num_steps = 32;
sample_rate = 64e6;
decim_factor = 33; %DEPENDENT ON FREQ
prf = 4e6;
prf_accuracy = 20e-6;
coarse_precision = 1e-7;
fine_precision = 1e-9;
stream_decim = 33;
start_timepoint = 10;
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

%Check to see if we're performing toa calibration (which comes after running an entire dataset)
if(strcmp(res.operation,'toa_calibration'))
	%Loop through all post-processing data
	timestep_files = dir('timestep*');
	measured_toa_errors = zeros(length(timestep_files),4);
	for ii=1:length(timestep_files)
		load(timestep_files(ii).name);
		measured_toas = imp_toas-imp_toas(1);
		measured_toa_errors(ii,:) = calculateAnchorErrors(anchor_positions, res.toa_cal_location, measured_toas);
	end
	measured_toa_errors = median(measured_toa_errors,1);
	save('../measured_toa_errors', 'measured_toa_errors');
	return;
elseif(strcmp(res.operation,'post_localization'))
	load('../measured_toa_errors');

	%Loop through all post-processing data
	timestep_files = dir('timestep*');
	est_positions = zeros(length(timestep_files),3);
	for ii=1:length(timestep_files)
		load(timestep_files(ii).name);
		imp_toas = imp_toas - measured_toa_errors.';
		%Iteratively minimize the MSE between the position estimate and all TDoA
		%measurements
		est_position = [0,0,0];
		position_step = 0.01;
		poss_steps = PermsRep([-position_step, 0, position_step], 3);
		new_est = true;
		best_error = Inf;
		while new_est
		    cur_best_error = best_error;
		    cur_best_error_idx = 1;
		    for jj=1:size(poss_steps,1)
		        cand_position = est_position + poss_steps(jj,:);
		        cand_error = calculatePositionError(cand_position, anchor_positions, imp_toas, true);
		        
		        if cand_error < cur_best_error
		            cur_best_error = cand_error;
		            cur_best_error_idx = jj;
		        end
		    end
		    
		    if cur_best_error < best_error
		        best_error = cur_best_error;
		        est_position = est_position + poss_steps(cur_best_error_idx,:);
		        new_est = true;
		    else
		        new_est = false;
		    end
		    
		    if(sqrt(sum(est_position.^2)) > 10)
		        est_position = [0, 0, 0];
		        break;
		    end
		end
		if(sum(abs(est_position)) > 0)
			est_positions(ii,:) = est_position;
		end
		ii
	end
	est_positions = est_positions(est_positions(:,1) > 0,:);
	save est_positions est_positions;
	return;
end

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
first_time = true;
for cur_timepoint=start_timepoint:size(data_iq,3)
	cur_iq_data = squeeze(data_iq(:,:,cur_timepoint,:));

	%Detect overflow issues
	overflow_sum = sum(abs(cur_iq_data),3);
	if find(overflow_sum == 0)
		continue;
	end
	
	prfSearch;
	if first_time
		prf_est_history = repmat(prf_est,[NUM_HIST,1]);
		first_time = false;
	else
		prf_est_history = [prf_est_history(2:NUM_HIST);prf_est];
	end
	prf_est = mean(prf_est_history);

	%square_ests = [square_ests,square_est];
	%time_offset_maxs = [time_offset_maxs,time_offset_max];

	harmonicExtraction_bjt;
	correctCOMBPhase;
	compensateRCLP;
	compensateRCHP;
	compensateStepTime;
	%processIFCal;
	%correctIFCal;
	%compensateLOLength;
	%%compensateMovement;
	if(strcmp(res.operation,'calibration'))
		processDirectSquare_bjt;%ONLY FOR CALIBRATION DATA
		temp_to_tx(:,:,cur_timepoint) = angle(temp_phasors)-angle(tx_phasors);
		keyboard;
		
		%Final phasor calibration step calculates any remaining phase accrual errors between LO steps
		phase_accrual = squeeze(angle(square_phasors(prf_anchor,2:end,9:end))-angle(square_phasors(prf_anchor,1:end-1,1:8)));
		phase_accrual(phase_accrual > pi) = phase_accrual(phase_accrual > pi) - 2*pi;
		phase_accrual(phase_accrual < -pi) = phase_accrual(phase_accrual < -pi) + 2*pi;

		amplitude_accrual = squeeze(abs(square_phasors(prf_anchor,2:end,9:end))./abs(square_phasors(prf_anchor,1:end-1,1:8)));


		save(['timestep',num2str(cur_timepoint)], 'prf_est', 'square_phasors', 'tx_phasors', 'phase_accrual');%, 'time_offset_max', 'est_position', 'imp_toas', 'imp');%, 'est_likelihood', 'time_offset_max');
	else
		harmonicLocalization_r7;
		imp_toas = imp_toas*2;
		keyboard;
		save(['timestep',num2str(cur_timepoint)], 'prf_est', 'square_phasors', 'tx_phasors', 'imp_toas', 'imp');%, 'est_likelihood', 'time_offset_max');
	end

	%save(['timestep',num2str(cur_timepoint)],'prf_est');
	full_search_flag = false;
	disp(['done with timepoint ', num2str(cur_timepoint)])
end

