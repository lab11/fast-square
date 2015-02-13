function ret = readHSCOMBData(file_name, samples_per_freq)

%Magic numbers and derived magic numbers
skip_samples = 240;
samples_per_trimmed_step = samples_per_freq-skip_samples-59;

fid = fopen(file_name,'r');
%fseek(fid, offset,-1);
data = fread(fid,'float');
fclose(fid);
data = round(data*32767);
data_iq = data(1:2:end) + 1i*data(2:2:end);

%Find marked restarts in data stream
restarts = find(data_iq == -32768-32768*1i);
res_diff = diff(restarts);

restart_idxs = restarts(find(res_diff > 1)+1)-1;%Subtract one to account for restart counter which comes before restart sequence
restart_idxs = restart_idxs(1:end-1);

restart_counter_real = real(data_iq(restart_idxs));
restart_counter_real(restart_counter_real < 0) = restart_counter_real(restart_counter_real < 0) + 65536;
restart_counter_imag = imag(data_iq(restart_idxs));
restart_counter_imag(restart_counter_imag < 0) = restart_counter_imag(restart_counter_imag < 0) + 65536;
restart_counter = restart_counter_real + 65536*restart_counter_imag;
restart_counter = restart_counter + 1; %fixes zero-indexed MATLAB issues

%Get rid of switching frequency junk data
data_segment_start_idxs = (restart_idxs + skip_samples).';%Magic number for how many samples before the start of restart sequence before valid data is present

data_segment_idxs = repmat(data_segment_start_idxs,[32,1]) + repmat(((0:31).').*samples_per_freq,[1,size(data_segment_start_idxs,2)]);


ret = zeros(size(data_segment_idxs,1),max(restart_counter),samples_per_trimmed_step);
ret(:,restart_counter,:) = data_iq(repmat(data_segment_idxs,[1,1,samples_per_trimmed_step])+repmat(shiftdim(0:samples_per_trimmed_step-1,-1),[size(data_segment_idxs,1),size(data_segment_idxs,2),1]));
