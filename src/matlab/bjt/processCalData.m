function ret = processCalData(anchor_direct_cal_paths,stationary_cal_path,stationary_location)

%NOTE: It is assumed that anchor_direct_cal_paths are subdirectories of the current path

%store current directory for later use
cur_dir = pwd;

%Zero out the tx_phasors calibration data
analyzeHSCOMBData_bjt('operation','reset_cal_data');

%Process calibration data for each anchor
for ii=1:length(anchor_direct_cal_paths)
	%Make sure we're in the correct top-level folder
	cd(cur_dir);

	%Proceed to the correct cal-specific folder
	cur_direct_cal_path = anchor_direct_cal_paths{ii};
	cd(cur_direct_cal_path);

	%Process the calibration data
	analyzeHSCOMBData_bjt('operation','calibration','anchor',ii);

	%Load the data which will be updated
	load ../tx_phasors
	tx_phasors_old = tx_phasors;

	%Load in the ~10th timestep to use for the calibration data
	jj = 10;
	successful_load = false;
	while successful_load == false
		try
			load(['timestep',num2str(jj)]);
			successful_load = true;
		catch
			successful_load = false;
		end
	end

	tx_phasors_old(ii,:,:) = tx_phasors(ii,:,:);
	tx_phasors = tx_phasors_old;
	save ../tx_phasors tx_phasors
end

%Then process the toa_calibration data
analyzeHSCOMBData_bjt('operation','toa_calibration','toa_cal_location',stationary_location);
