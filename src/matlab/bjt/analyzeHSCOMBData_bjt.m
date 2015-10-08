function ret = analyzeHSCOMBData_bjt(varargin)

p = inputParser;

defaultOperation = 'localization';
validOperations = {'localization','calibration','toa_calibration','diversity_localization','post_localization','reset_cal_data'};
checkOperation = @(x) any(validatestring(x,validOperations));

defaultPRFAlgorithm = 'normal';
validPRFAlgorithms = {'normal','fast'};
checkPRFAlgorithm = @(x) any(validatestring(x,validPRFAlgorithms));

defaultSystemSetup = 'normal';
validSystemSetups = {'normal','diversity','diversity-cal'};
checkSystemSetup = @(x) any(validatestring(x,validSystemSetups));

defaultAnchor = 1;
defaultIFFreq = 990e6;
defaultCalLocation = [0 0 0];
defaultToaCalName = 'measured_toa_errors.mat';

addParamValue(p,'operation', defaultOperation, checkOperation);
addParamValue(p,'prf_algorithm',defaultPRFAlgorithm, checkPRFAlgorithm);
addParamValue(p,'system_setup',defaultSystemSetup, checkSystemSetup);
addParamValue(p,'anchor', defaultAnchor, @isnumeric);
addParamValue(p,'if_freq', defaultIFFreq, @isnumeric);
addParamValue(p,'toa_cal_location', defaultCalLocation, @ismatrix);
addParamValue(p,'toa_cal_name', defaultToaCalName, @ischar);

parse(p,varargin{:});
res = p.Results;

RECORD_TICKS = 35000;
total_ticks = RECORD_TICKS + 1 + 642 + 31;
ticks_per_sequence = 4096+total_ticks*32;

sub_folders = false;

NUM_HIST = 10;
INTERP = 64;
THRESH = 0.2;

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
start_timepoint = 15;
restart_samples = 101;
samples_per_freq = round(total_ticks/stream_decim);

%Figure out which harmonics are in each snapshot
num_harmonics_present = floor(sample_rate/prf);

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
%anchor_positions = [...
%    2.405, 3.815, 2.992;...
%    2.105, 0.034, 2.494;...
%    4.108, 0.347, 1.543;...
%    0.273, 0.343, 1.56 ...
%];
%%Positions with all antennas taken into account (attached directly to anchors)
anchor_positions = zeros(4,3,3);
anchor_positions(1,:,:) = [...
	2.425, 3.910, 3.008;...
	2.400, 3.808, 3.008;...
	2.334, 3.855, 2.945 ...
];
%Rough paper coords
%anchor_positions(2,:,:) = [
%	2.125, 0.000, 2.559;...
%	2.125, 0.000, 2.454;...
%	2.040, 0.000, 2.507 ...
%] + repmat([-0.025, 0.232, -0.067],[3,1]);
anchor_positions(2,:,:) = [
	2.136, 0.250, 2.479;...
	2.124, 0.247, 2.384;...
	2.044, 0.239, 2.439 ...
];
anchor_positions(3,:,:) = [
	4.219, 0.486, 1.635;...
	4.157, 0.404, 1.649;...
	4.198, 0.458, 1.728 ...
]-.113;
anchor_positions(4,:,:) = [
	0.326, 0.441, 1.649;...
	0.424, 0.441, 1.649;...
	0.374, 0.441, 1.738 ...
]-.113;
%%Positions with all antennas taken into account (extended away from anchors)
%anchor_positions = zeros(4,3,3);
%anchor_positions(1,:,:) = [...
%	2.969, 3.927, 2.969;...
%	2.129, 3.289, 2.861;...
%	1.744, 3.927, 2.819 ...
%];
%anchor_positions(2,:,:) = [
%	2.535, 0.000, 2.775;...
%	2.519, 0.000, 2.036;...
%	1.427, 0.000, 2.494 ...
%];
%anchor_positions(3,:,:) = [
%	4.312, 0.749, 1.229;...
%	3.488, 0.316, 1.510;...
%	4.085, 0.316, 1.880 ...
%];
%anchor_positions(4,:,:) = [
%	0.000, 0.675, 1.230;...
%	0.867, 0.316, 1.515;...
%	0.261, 0.316, 1.888 ...
%];
num_anchors = size(anchor_positions,1);

%Check to see if we're performing toa calibration (which comes after running an entire dataset)
if(strcmp(res.operation,'toa_calibration'))
	%Loop through all post-processing data
	timestep_files = dir('timestep*');
	last_step_idx = 0;
	for ii=1:length(timestep_files)
		cand_idx = str2num(timestep_files(ii).name(9:end-4));
		if(cand_idx > last_step_idx)
			last_step_idx = cand_idx;
		end
	end

	measured_toa_errors = [];
	for ii=start_timepoint:3:last_step_idx
		try
			load(['timestep',num2str(ii)]);
			anchor_positions_div = zeros(num_anchors,3);
			for jj=1:num_anchors
				anchor_positions_div(jj,:) = anchor_positions(jj,diversity_choice(jj),:);
				imp_toas(jj) = imp_toas_div(jj,diversity_choice(jj));
			end
			measured_toas = imp_toas - imp_toas(1);
			measured_toa_errors = [measured_toa_errors;calculateAnchorErrors(anchor_positions_div, res.toa_cal_location, measured_toas).'];
			measured_toa_errors(end,:) = modImps(measured_toa_errors(end,:),prf_est);
		catch
		end
		%load(timestep_files(ii).name);
		%measured_toas = imp_toas-imp_toas(1);
		%measured_toa_errors(ii,:) = calculateAnchorErrors(anchor_positions, res.toa_cal_location, measured_toas);
		%measured_toa_errors(ii,:) = modImps(measured_toa_errors(ii,:),prf_est);
	end
	measured_toa_errors = median(measured_toa_errors,1);
	save(res.toa_cal_name, 'measured_toa_errors');
	return;
elseif(strcmp(res.operation,'diversity_localization'))
	%Get out of the directory with so many files because matlab hates that...
	cur_dir = pwd;
	cd ../
	
	timestep_files = dir([cur_dir,'/timestep*']);
	last_step_idx = 0;
	for ii=1:length(timestep_files)
		cand_idx = str2num(timestep_files(ii).name(9:end-4));
		if(cand_idx > last_step_idx)
			last_step_idx = cand_idx;
		end
	end
	diversity_choices = [];
	imp_toas_agg = [];
	est_positions = zeros(3,1,3);
	cur_folder = -1;
	if(sub_folders)
		last_step_idx = 18811; %TODO: Fix this...
	end
	for ii=start_timepoint:3:last_step_idx
		tic;
		disp('reading')
		%All five consecutive timesteps are necessary to calculate position
		try
			success = false;
			for jj=1:3
				if(sub_folders)
					cur_folder = goToSubFolder(cur_folder, ii+jj-1);
				end
				load([cur_dir,'/timestep',num2str(ii+jj-1),'.mat']);
			end
			success = true;
		catch
		end 
		disp('done reading')

		if(success)
			imp_agg = zeros([size(imp),3]);
			imp_toa_idxs_agg = zeros(4,3);
			prf_est_agg = zeros(1,3);
			drift_time_in_samples = 0;
			div_metric = zeros(4,3);
			%Start by refactoring ToA estimates by using 20% of the max amplitude instead of 20% of each snapshot
			for jj=1:3
				if(sub_folders)
					cur_folder = goToSubFolder(cur_folder, ii+jj-1);
				end
				load([cur_dir,'/timestep',num2str(ii+jj-1)]);
				imp_agg(:,:,jj) = imp;
			end
			imp_maxs = max(squeeze(max(abs(imp_agg),[],2)),[],2);
			imp_toa_div_idxs = zeros(num_anchors,1);
			for jj=1:3
				for kk=1:num_anchors
					cand_toa = impThresh(abs(imp_agg(kk,:,jj)),imp_maxs(kk)*THRESH);
					if(length(cand_toa) == 1)
						imp_toa_div_idxs(kk) = cand_toa;
					end
				end
				if(sub_folders)
					cur_folder = goToSubFolder(cur_folder, ii+jj-1);
				end
				save([cur_dir,'/timestep',num2str(ii+jj-1)],'-append','imp_toa_div_idxs');
			end

			for jj=1:3
				if(sub_folders)
					cur_folder = goToSubFolder(cur_folder, ii+jj-1);
				end
				load([cur_dir,'/timestep',num2str(ii+jj-1)]);
				
				%Compensate for drift due to time between datasets
				imp_toa_div_idxs = imp_toa_div_idxs - round(drift_time_in_samples);
				imp_toa_div_idxs = mod(imp_toa_div_idxs-1,size(imp,2))+1; %Have to remember we're not using 0-indexing...

				%Increment drift time due to current pulse repetition frequency
				drift_time_in_samples = drift_time_in_samples + (prf-prf_est)*(ticks_per_sequence/sample_rate)*size(imp,2);

				imp_toa_idxs_agg(:,jj) = imp_toa_div_idxs;
				prf_est_agg(jj) = prf_est;

				for kk=1:4
					%Calculate the los ratio by calculating los peak amplitude through successive addition
					los_amp = 0;
					idx_ctr = imp_toa_div_idxs(kk);
					idx_tot = 0;
					while(idx_tot < INTERP/2)
						los_amp = los_amp + abs(imp(kk,idx_ctr));
						idx_tot = idx_tot + 1;
						idx_ctr = idx_ctr + 1;
						if(idx_ctr > size(imp,2))
							idx_ctr = 1;
						end
					end
					div_metric(kk,jj) = max(abs(imp(kk,:)));%los_amp;
				end
			end

			imp_toa_idxs_div = zeros(4,3);
			imp_toa_idxs_div = imp_toa_idxs_agg;

			div_metric2 = zeros(4,3);
			div_metric2 = div_metric;

			imp_toas_div = imp_toa_idxs_div/(2*prf_est*num_steps*size(square_phasors,3)/2)/(INTERP+1)*3e8;
			imp_toas_div = imp_toas_div*2;

			%Diversity choice option #1: lowest ToA
			half_prf = prf_est/2;
			temp_toas_div = imp_toas_div - repmat(imp_toas_div(:,1),[1,size(imp_toas_div,2)]);
			temp_toas_div(temp_toas_div > half_prf) = temp_toas_div(temp_toas_div > half_prf) - prf_est;
			temp_toas_div(temp_toas_div < -half_prf) = temp_toas_div(temp_toas_div < -half_prf) + prf_est;
			[~,diversity_choice] = min(temp_toas_div,[],2);

			%%Diversity choice option #1: Highest div metric
			%[~,diversity_choice] = max(div_metric2,[],2);

			if(sub_folders)
				cur_folder = goToSubFolder(cur_folder, ii);
			end
			save([cur_dir,'/timestep',num2str(ii)],'-append','imp_toas_div','diversity_choice');
			
		end
		%%If we have all five timepoints, start with 'best antenna' classification
		%if(success)
		%	los_ratios = zeros(4,5);
		%	imp_toa_idxs_agg = zeros(size(anchor_positions,1),size(imp_toa_idxs,1));
		%	for jj=1:5
		%		load(['timestep',num2str(ii+jj)]);
		%		imp_toa_idxs_agg(jj,:) = imp_toa_idxs;
		%		for kk=1:4
		%			%Calculate the los ratio by calculating los peak amplitude through successive addition
		%			los_amp = 0;
		%			idx_ctr = imp_toa_idxs(kk);
		%			idx_tot = 0;
		%			while(idx_tot < INTERP*2) %los_amp < abs(imp(kk,idx_ctr)))
		%				los_amp = los_amp + abs(imp(kk,idx_ctr));
		%				idx_tot = idx_tot + 1;
		%				idx_ctr = idx_ctr + 1;
		%				if(idx_ctr > size(imp,2))
		%					idx_ctr = 1;
		%				end
		%			end
		%			los_ratios(kk,jj) = los_amp;%/sum(abs(imp(kk,:)));
		%		end
		%	end
	
		%	%Which snapshot we use depends on the largest los ratio
		%	[~,diversity_choice] = max(los_ratios,[],2);
		%	%keyboard;

		%	diversity_choices = [diversity_choices,diversity_choice(:)];

		%	%Now convert each ToA back to its equivalent in the 1st timestep
		%	for jj=1:4
		%		cur_choice = diversity_choice(jj);
		%		cur_toa_idx = imp_toa_idxs_agg(1,jj);
		%		if(cur_choice == 1)
		%			imp_toas(jj) = cur_toa_idx;
		%		elseif(cur_choice == 2 || cur_choice == 3)
		%			if(jj == 2 || jj == 4)
		%				imp_toas(jj) = cur_toa_idx;
		%			else
		%				imp_toas(jj) = imp_toa_idxs_agg(cur_choice,jj) + (imp_toa_idxs_agg(1,2) - imp_toa_idxs_agg(cur_choice,2));
		%			end
		%		elseif(cur_choice == 4 || cur_choice == 5)
		%			if(jj == 2 || jj == 4)
		%				imp_toas(jj) = imp_toa_idxs_agg(cur_choice,jj) + (imp_toa_idxs_agg(3,1) - imp_toa_idxs_agg(cur_choice,1));
		%				imp_toas(jj) = imp_toas(jj) + (imp_toa_idxs_agg(1,2) - imp_toa_idxs_agg(3,2));
		%			else
		%				imp_toas(jj) = imp_toa_idxs_agg(3,jj) + (imp_toa_idxs_agg(1,2) - imp_toa_idxs_agg(3,2));
		%			end
		%		end
		%		imp_toas(jj) = imp_toas(jj)/(2*prf_est*num_steps*size(square_phasors,3)/2)/(INTERP+1)*3e8;%MAGIC NUMBER (/2)
		%		imp_toas(jj) = imp_toas(jj)*2;
		%	end
		%	save(['timestep',num2str(ii+1)],'-append','imp_toas');
		%	imp_toas_agg = [imp_toas_agg,imp_toas];
		%end
		ii
		toc;
	end
	return;
elseif(strcmp(res.operation,'post_localization'))
	load('../measured_toa_errors');

	%Get out of the directory with so many files because matlab hates that...
	cur_dir = pwd;
	cd ../
	
	%Loop through all post-processing data
	timestep_files = dir([cur_dir,'/timestep*']);
	last_step_idx = 0;
	for ii=1:length(timestep_files)
		cand_idx = str2num(timestep_files(ii).name(9:end-4));
		if(cand_idx > last_step_idx)
			last_step_idx = cand_idx;
		end
	end
	timestep_step = 1;
	if(strcmp(res.system_setup,'diversity'))
		timestep_step = 3;
	end
	est_positions = zeros(length(timestep_files),3);
	toa_hist = zeros(length(timestep_files),4);
	good_ests = zeros(length(timestep_files),1);
	toa_errors_hist = zeros(length(timestep_files),12);
	diversity_choices = zeros(length(timestep_files),4);
	cur_folder = -1;
	if(sub_folders)
		last_step_idx = 18811; %TODO: Fix this...
	end
	for ii=start_timepoint:timestep_step:last_step_idx
		try
			tic;
			if(sub_folders)
				cur_folder = goToSubFolder(cur_folder, ii);
			end
			load([cur_dir,'/timestep',num2str(ii)]);
			tic
			if(strcmp(res.system_setup,'diversity'))
				for jj=1:length(diversity_choice)
					imp_toas(jj) = imp_toas_div(jj,diversity_choice(jj));
				end
			end
			imp_toas = imp_toas - measured_toa_errors.';
			imp_toas = modImps(imp_toas,prf_est);
			anchor_pos = reshape(anchor_positions,[size(anchor_positions,1)*size(anchor_positions,2),size(anchor_positions,3)]);
			[pos_temp, temp_toa_errors] = runNewtonLocalization(anchor_pos, imp_toas_div, measured_toa_errors, prf_est);
			toa_errors_hist(ii,:) = temp_toa_errors(:);
			temp_toa_errors = reshape(temp_toa_errors,[size(imp_toas_div)]);
			[~,diversity_choice] = min(temp_toa_errors,[],2);
			%keyboard;
			diversity_anchor_pos = zeros(num_anchors,3);
			imp_toas_choice = zeros(num_anchors,1);
			for jj=1:num_anchors
				diversity_anchor_pos(jj,:) = anchor_positions(jj,diversity_choice(jj),:);
				imp_toas_choice(jj) = imp_toas_div(jj,diversity_choice(jj));
			end
			[est_position, toa_errors] = runNewtonLocalization(diversity_anchor_pos, imp_toas_choice, measured_toa_errors, prf_est);

			%%Iteratively minimize the MSE between the position estimate and all TDoA
			%%measurements
			%est_position = [0,0,0];
			%position_step = 0.01;
			%poss_steps = PermsRep([-position_step, 0, position_step], 3);
			%new_est = true;
			%best_error = Inf;
			%while new_est
			%    cur_best_error = best_error;
			%    cur_best_error_idx = 1;
			%    for jj=1:size(poss_steps,1)
			%        cand_position = est_position + poss_steps(jj,:);

			%	anchor_positions_div = zeros(num_anchors,3);
			%	for kk=1:num_anchors
			%		anchor_positions_div(kk,:) = anchor_positions(kk,diversity_choice(kk),:);
			%	end
			%        cand_error = calculatePositionError(cand_position, anchor_positions_div, imp_toas, true);
			%        
			%        if cand_error < cur_best_error
			%            cur_best_error = cand_error;
			%            cur_best_error_idx = jj;
			%        end
			%    end
			%    
			%    if cur_best_error < best_error
			%        best_error = cur_best_error;
			%        est_position = est_position + poss_steps(cur_best_error_idx,:);
			%        new_est = true;
			%    else
			%        new_est = false;
			%    end
			%    
			%    if(sqrt(sum(est_position.^2)) > 10)
			%        est_position = [0, 0, 0];
			%        break;
			%    end
			%end
			if(sum(abs(est_position)) > 0)
				est_positions(ii,:) = est_position;
				toa_hist(ii,:) = imp_toas;
				good_ests(ii) = ii;
				diversity_choices(ii,:) = diversity_choice;
				%save(['timestep',num2str(ii)],'-append','est_position');
			end
			ii
			toc
			est_positions(ii,:)
			%keyboard;
		catch
		end
	end
	%keyboard;
	toa_hist = toa_hist(est_positions(:,1) > 0,:);
	good_ests = good_ests(est_positions(:,1) > 0);
	diversity_choices = diversity_choices(est_positions(:,1) > 0,:);
	est_positions = est_positions(est_positions(:,1) > 0,:);
	save([cur_dir,'/est_positions'],'est_positions','toa_hist','good_ests','diversity_choices');
	return;
elseif(strcmp(res.operation,'reset_cal_data'))
	tx_phasors = zeros(num_anchors,num_steps,num_harmonics_present);
	save tx_phasors tx_phasors
	return;
end

%%TODO: May need to selectively read parts of files since this is pretty memory-intense
%smallest_num_timepoints = Inf;
%for ii=1:size(anchor_positions,1)
%	cur_data_iq = readHSCOMBData(['usrp_chan', num2str(ii-1), '.dat'],samples_per_freq);
%	if(size(cur_data_iq,2) < smallest_num_timepoints)
%		smallest_num_timepoints = size(cur_data_iq,2);
%	end
%end
%data_iq = zeros(size(anchor_positions,1),size(cur_data_iq,1),smallest_num_timepoints,size(cur_data_iq,3));
%for ii=1:size(anchor_positions,1)
%    cur_data_iq = shiftdim(readHSCOMBData(['usrp_chan', num2str(ii-1), '.dat'],samples_per_freq));
%    data_iq(ii,:,:,:) = cur_data_iq(:,1:smallest_num_timepoints,:);
%
%end
%if(use_image)
%	data_iq = conj(data_iq);
%end

%%Construct a candidate search space over which to look for the tag
%[x,y,z] = meshgrid(0:.05:4,0:.05:4,-.65);%-2:.05:2);
%physical_search_space = [x(:),y(:),z(:)];
%
%%Pre-calculate distances from each point on search space to corresponding
%%anchors
%anchor_positions_reshaped = reshape(anchor_positions,[size(anchor_positions,1),1,size(anchor_positions,2)]);
%physical_distances = repmat(shiftdim(physical_search_space,-1),[size(anchor_positions,1),1,1])-repmat(anchor_positions_reshaped,[1,size(physical_search_space,1),1]);
%physical_distances = sqrt(sum(physical_distances.^2,3));

%cur_iq_data = squeeze(data_iq(:,:,1,:));
full_search_flag = true;

%fft_len = 2^ceil(log2(size(data_iq,4)));

%Loop through each timepoint
%tx_phasors = zeros(num_steps,num_harmonics_present);
%temp_to_tx = zeros(32,num_harmonics_present,size(data_iq,3));
%time_offset_maxs = [];
%square_ests = [];
file_offsets = zeros(4,1);
cur_counters = zeros(4,1);
first_time = true;
time_step = 1;
if(strcmp(res.system_setup,'diversity-cal'))
	time_step = 3;
	cur_timepoint = start_timepoint-time_step-1;
else
	cur_timepoint = start_timepoint-time_step;
end
while min(file_offsets) >= 0
	cur_timepoint = cur_timepoint + time_step;
	while min(cur_counters) < cur_timepoint
		for ii=1:num_anchors
			if cur_counters(ii) < cur_timepoint
				[cur_iq_data(ii,:,:), cur_counters(ii), file_offsets(ii)] = readHSCOMBData_single(['usrp_chan',num2str(ii-1),'.dat'],file_offsets(ii),samples_per_freq, restart_samples, num_steps);
				if(file_offsets(ii) == -1)
					return;
				end
			end
		end
	end
	if max(cur_counters) > cur_timepoint
		continue;
	end
	tic
	%cur_iq_data = squeeze(data_iq(:,:,cur_timepoint,:));
	if(use_image)
		cur_iq_data = conj(cur_iq_data);
	end
	%keyboard

	%Detect overflow issues
	overflow_sum = sum(abs(cur_iq_data),3);
	if find(overflow_sum == 0)
		continue;
	end
	
	if first_time
		load ../tx_phasors;
	end
	if(strcmp(res.prf_algorithm,'fast'))
		if first_time
			prfSearch_init;
			harmonicExtraction_bjt_init;
		end
		prfSearch_fast;
		prf_est
	else
		prfSearch;
	end
	%keyboard;
	if first_time
		prf_est_history = repmat(prf_est,[NUM_HIST,1]);
		first_time = false;
	else
		prf_est_history = [prf_est_history(2:NUM_HIST);prf_est];
	end
	prf_est = mean(prf_est_history);

	%square_ests = [square_ests,square_est];
	%time_offset_maxs = [time_offset_maxs,time_offset_max];

	if(strcmp(res.prf_algorithm,'fast'))
		harmonicExtraction_bjt_fast;
	else
		harmonicExtraction_bjt;
	end
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
		%temp_to_tx(:,:,cur_timepoint) = squeeze(angle(temp_phasors))-squeeze(angle(tx_phasors(prf_anchor,:,:)));
		%keyboard;
		
		%Final phasor calibration step calculates any remaining phase accrual errors between LO steps
		phase_accrual = squeeze(angle(square_phasors(prf_anchor,2:end,9:end))-angle(square_phasors(prf_anchor,1:end-1,1:8)));
		phase_accrual(phase_accrual > pi) = phase_accrual(phase_accrual > pi) - 2*pi;
		phase_accrual(phase_accrual < -pi) = phase_accrual(phase_accrual < -pi) + 2*pi;

		amplitude_accrual = squeeze(abs(square_phasors(prf_anchor,2:end,9:end))./abs(square_phasors(prf_anchor,1:end-1,1:8)));


		save(['timestep',num2str(cur_timepoint)], 'prf_est', 'square_phasors', 'tx_phasors', 'phase_accrual');%, 'time_offset_max', 'est_position', 'imp_toas', 'imp');%, 'est_likelihood', 'time_offset_max');
		keyboard;
	else
		harmonicLocalization_r7;
		imp_toas = imp_toas*2;
		toc
		%if cur_timepoint == 211
		%	keyboard;
		%end
		save(['timestep',num2str(cur_timepoint)], 'prf_est', 'square_phasors', 'tx_phasors', 'imp_toas', 'imp_toa_idxs', 'imp');%, 'est_likelihood', 'time_offset_max');
	end

	%save(['timestep',num2str(cur_timepoint)],'prf_est');
	full_search_flag = false;
	%disp(['done with timepoint ', num2str(cur_timepoint)])
end

