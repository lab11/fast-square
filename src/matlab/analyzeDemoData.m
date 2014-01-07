RECORD_TICKS = 35000;
total_ticks = RECORD_TICKS + 1 + 642 + 31;

fid = fopen('usrp_chan0.dat','r');
data = fread(fid,'float');
fclose(fid);
data_iq_baseband = data(1:2:end) + 1i*data(2:2:end);

fid = fopen('usrp_chan1.dat','r');
data = fread(fid,'float');
fclose(fid);
data_iq = data(1:2:end) + 1i*data(2:2:end);

num_steps = 32;

data_iq = round(data_iq*32767);

restarts = find(data_iq == -32768+-32768*1i);
res_diff = diff(restarts);
restarts = restarts(find(res_diff > 1));

freq_data = zeros(length(restarts)-1,4,num_steps);
step_length = zeros(length(restarts)-1,num_steps);
for ii=1:length(restarts)-1
    start_harmonic = 120;
    
    %Get indices of each dataset
    cur_data = data_iq(restarts(ii):restarts(ii+1));
    cur_baseband_data = data_iq_baseband(restarts(ii):restarts(ii+1));
    
    %Find carrier, subcarrier peaks
    cur_baseband_fft_interp = interpFFT(cur_baseband_data, 1e6);
    [carrier_peak, carrier_peak_idx] = max(cur_baseband_fft_interp(850e3+1:950e3));
    carrier_peak_freq = carrier_peak_idx + 850e3;
    carrier_peak_error = carrier_peak_freq-9e5;
    carrier_peak_phase = angle(cur_baseband_fft_interp(carrier_peak_idx));
    [subcarrier_peak, subcarrier_peak_idx] = max(cur_baseband_fft_interp(250e3+1:350e3));
    subcarrier_peak_freq = subcarrier_peak_idx + 250e3;
    subcarrier_peak_phase = angle(cur_baseband_fft_interp(subcarrier_peak_idx));
    subcarrier_peak_error = subcarrier_peak_freq-3e5-carrier_peak_error;

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
        freq_data(ii,:,jj) = cur_step_data(1:4) + 1i*cur_step_data(5:end);%I data first, Q data second
        
        %Subtract accumulated phase at each frequency step
        freq_data(ii,:,jj) = freq_data(ii,:,jj).*...
                             conj(exp(1i*2*pi*(...
                                 (100e3-carrier_peak_error-subcarrier_peak_error*start_harmonic)*total_ticks*(jj-1)/64e6+...
                                 ((-3:2:3))*(4e6+subcarrier_peak_error)*total_ticks*(jj-1)/64e6)...%-...%(960e6)*total_ticks*(jj-1)/64e6)...
                             ));
                         
        start_harmonic = start_harmonic - 8;
    end
end

%Flip the third dimension to put frequencies in ascending order
freq_data = flipdim(freq_data,3);

%Reorganize interleaved frequencies
freq_data = reshape(freq_data,[size(freq_data,1),size(freq_data,2)*size(freq_data,3)]);

clear data data_iq data_iq_baseband