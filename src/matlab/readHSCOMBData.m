function ret = readHSCOMBData(file_name, offset)

fid = fopen(file_name,'r');
data = fread(fid,'float');
fclose(fid);
data = round(data*32767);
data_iq = data(1:2:end) + 1i*data(2:2:end);

%Find marked restarts in data stream (should be 73375 samples apart)
restarts = find(data_iq == -32768-32768*1i);
res_diff = diff(restarts);

first_start_idx = restarts(find(res_diff >= 69046,1))+offset;
restarts = first_start_idx:69247:length(data_iq)-69247;

%Get rid of switching frequency junk data
data_segments = restarts + 40;

data_segments = repmat(data_segments,[33,1]) + repmat(((0:32).').*2099,[1,size(data_segments,2)]);

ret = data_iq(repmat(data_segments,[1,1,1800])+repmat(shiftdim(1:1800,-1),[size(data_segments,1),size(data_segments,2),1]));

