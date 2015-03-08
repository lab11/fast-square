function [ret_data, restart_counter, new_offset] = readHSCOMBData_single(file_name, file_offset, samples_per_freq, restart_samples, num_steps)

%Magic numbers and derived magic numbers
skip_samples = 280;
samples_per_trimmed_step = samples_per_freq-skip_samples-59-6;

fid = fopen(file_name,'r');
fseek(fid, file_offset,-1);
whole_snapshot = false;
data_iq = [];
while whole_snapshot == false
	new_data = fread(fid,samples_per_freq*num_steps*2,'float');
	if(feof(fid))
		restart_counter = -1;
		ret_data = -1;
		new_offset = -1;
		break;
	end
	new_data = round(new_data*32767);
	new_data = new_data(1:2:end) + 1i*new_data(2:2:end);
	data_iq = [data_iq; new_data];

	%Find marked restarts in data stream
	restarts = find(data_iq == -32768-32768*1i);
	res_diff = diff(restarts);

	
	%Subtract one to account for restart counter which comes before restart sequence
	restart_idx = restarts(find(res_diff > num_steps*samples_per_freq-skip_samples))-restart_samples;
	next_restart_idx = restarts(find(res_diff > num_steps*samples_per_freq-skip_samples)+1)-1;
	if(length(restart_idx) > 0)
		whole_snapshot = true;
		new_offset = file_offset + next_restart_idx*4*2 + 4*2;

		restart_counter_real = real(data_iq(next_restart_idx));
		restart_counter_real(restart_counter_real < 0) = restart_counter_real(restart_counter_real < 0) + 65536;
		restart_counter_imag = imag(data_iq(next_restart_idx));
		restart_counter_imag(restart_counter_imag < 0) = restart_counter_imag(restart_counter_imag < 0) + 65536;
		restart_counter = restart_counter_real + 65536*restart_counter_imag;

		%Get rid of switching frequency junk data
		data_segment_start_idxs = (restart_idx + skip_samples).';%Magic number for how many samples before the start of restart sequence before valid data is present
		data_segment_idxs = repmat(data_segment_start_idxs,[num_steps,1]) + repmat(((0:num_steps-1).').*samples_per_freq,[1,size(data_segment_start_idxs,2)]);
		ret_data = zeros(size(data_segment_idxs,1),samples_per_trimmed_step);
		ret_data = data_iq(repmat(data_segment_idxs,[1,samples_per_trimmed_step])+repmat(0:samples_per_trimmed_step-1,[size(data_segment_idxs,1),1]));
	
	end
end
disp([file_name,',',num2str(restart_counter),',',num2str(new_offset)])
fclose(fid);


