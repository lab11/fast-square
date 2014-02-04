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
carrier_peak_phase = zeros(length(restarts)-1,1);
subcarrier_peak_phase = zeros(length(restarts)-1,1);
carrier_peak_error = zeros(length(restarts)-1,1);
carrier_freq_setting = zeros(length(restarts)-1,1);
subcarrier_peak_error = zeros(length(restarts)-1,1);
carrier_setting_error = zeros(length(restarts)-1,num_steps);
for ii=1:length(restarts)-1
    start_harmonic = 120;
    
    %Get indices of each dataset
    cur_data = data_iq(restarts(ii):restarts(ii+1));
    cur_baseband_data = data_iq_baseband(restarts(ii):restarts(ii+1));
    
    %Find carrier, subcarrier peaks
    cur_baseband_fft_interp = interpFFT(cur_baseband_data, 1e6);
    [carrier_peak, carrier_peak_idx] = max(cur_baseband_fft_interp(850e3+1:950e3));
    carrier_peak_freq = carrier_peak_idx + 850e3 - 1;
    carrier_peak_error(ii) = carrier_peak_freq-9e5;
    carrier_peak_phase(ii) = angle(cur_baseband_fft_interp(carrier_peak_freq+1));
    [subcarrier_peak, subcarrier_peak_idx] = max(cur_baseband_fft_interp(250e3+1:350e3));
    subcarrier_peak_freq = subcarrier_peak_idx + 250e3 - 1;
    subcarrier_peak_phase(ii) = angle(cur_baseband_fft_interp(subcarrier_peak_freq+1));
    subcarrier_peak_error(ii) = subcarrier_peak_freq-3e5-carrier_peak_error(ii);

    steps = find(cur_data == -32768);
    steps_diff = diff(steps);
    steps = [1;steps(find(steps_diff > 1))];
    
    if length(steps) < num_steps
        disp(num2str(length(steps)))
        continue
    end
    
    for jj=1:num_steps
        cur_step_data = cur_data(steps(jj)+1:steps(jj)+11);
        cur_step_data(imag(cur_step_data) < 0) = cur_step_data(imag(cur_step_data) < 0) + 65536*1i;%Signed to unsigned LSBs
        cur_step_data = real(cur_step_data)*65536+imag(cur_step_data);%Add on MSBs
        freq_data(ii,:,jj) = cur_step_data(1:4) + 1i*cur_step_data(5:8);%I data first, Q data second
        carrier_freq_setting(ii) = cur_step_data(9);
        subcarrier_freq_setting = cur_step_data(10);
        freq_step_setting = cur_step_data(11);
        
        %Subtract accumulated phase at each frequency step
        freq_data(ii,:,jj) = freq_data(ii,:,jj).*...
                             conj(exp(1i*2*pi*(...
                                 (100e3-carrier_peak_error(ii)-subcarrier_peak_error(ii)*start_harmonic)*total_ticks*(jj-1)/64e6+...
                                 ((-3:2:3))*(4e6+subcarrier_peak_error(ii))*total_ticks*(jj-1)/64e6)...%-...%(960e6)*total_ticks*(jj-1)/64e6)...
                             ));
                         
        %Subtract phase induced by incorrect real-time frequency estimates
        carrier_setting_error(ii,jj) = (carrier_freq_setting(ii)-freq_step_setting*(jj-1))/(2^32)*64e6-(100e3-carrier_peak_error(ii)-subcarrier_peak_error(ii)*start_harmonic);
        freq_data(ii,:,jj) = freq_data(ii,:,jj).*...
                             conj(exp(1i*2*pi*(...
                                 carrier_setting_error(ii,jj)*total_ticks/2/64e6)...
                             ));
                         
        %Subtract phase from recovered carrier and subcarrier
        freq_data(ii,:,jj) = freq_data(ii,:,jj).*...
                             conj(exp(1i*(...
                                 (subcarrier_peak_phase(ii)-carrier_peak_phase(ii))*((-3:2:3)+start_harmonic))...
                             ));
                             
        %TODO: Theoretically subcarrier_setting_error should be introduced
        %as well, but its influence should be negligible
                         
        start_harmonic = start_harmonic - 8;
    end
end

%Flip the third dimension to put frequencies in ascending order
freq_data = flipdim(freq_data,3);

%Reorganize interleaved frequencies
freq_data = reshape(freq_data,[size(freq_data,1),size(freq_data,2)*size(freq_data,3)]);

%GARBAGE
%for ii=1:size(freq_data,1)
%    freq_data(ii,:) = freq_data(ii,:).*exp(-1i*((angle(freq_data(ii,67))-angle(freq_data(ii,66))).*(-131:2:123)/2));
%end

clear data data_iq data_iq_baseband