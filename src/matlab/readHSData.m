function ret = readHSData(file_name)

fid = fopen(file_nbame,'r');
data = fread(fid,'float');
fclose(fid);
data_iq = data(1:2:end) + 1i*data(2:2:end);
ret = round(data_iq*32767);
