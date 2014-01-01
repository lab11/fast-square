fid = fopen('usrp_chan1.dat','r');
data = fread(fid,'float');
fclose(fid);
data_iq = data(1:2:end) + 1i*data(2:2:end);

num_steps = 32;

data_iq = round(data_iq*32767);

restarts = find(data_iq == -32768+-32768*1i);
res_diff = diff(restarts);
restarts = restarts(find(res_diff > 1));

freq_data = zeros(length(restarts)-1,num_steps,4);
step_length = zeros(length(restarts)-1,num_steps);
for ii=1:length(restarts)-1
    %Get indices of each dataset
    cur_data = data_iq(restarts(ii):restarts(ii+1));
    steps = find(cur_data == -32768);
    steps_diff = diff(steps);
    steps = [1;steps(find(steps_diff > 1))];
    
    if length(steps) < num_steps
        disp(num2str(length(steps)))
        continue
    end
    
    for jj=1:num_steps
        cur_step_data = cur_data(steps(jj)+1:steps(jj)+9);
        step_length(ii,jj) = cur_step_data(end);
        cur_step_data = cur_step_data(1:end-1);
        cur_step_data(imag(cur_step_data) < 0) = cur_step_data(imag(cur_step_data) < 0) + 65536*1i;%Signed to unsigned LSBs
        cur_step_data = real(cur_step_data)*65536+imag(cur_step_data);%Add on MSBs
        freq_data(ii,jj,:) = 1i*cur_step_data(1:4) + cur_step_data(5:end);%Imaginary data first, real data second
    end
end
