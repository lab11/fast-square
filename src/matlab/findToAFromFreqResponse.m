function [toa_idx,imp_response, imp_response_complex] = findToAFromFreqResponse(freq_response, interp_factor)

%Restructure incoming vectors to make sure they're in the right orientation
freq_response = freq_response(:);

%Apply a window function to the incoming frequency response
num_freqs = length(freq_response);
num_freqs_cut2 = floor(num_freqs/2);
freq_response = freq_response.*hamming(num_freqs);

%Impulse response corresponds to the inverse FFT of the freq response
imp_response_fft = [freq_response(num_freqs_cut2:end);zeros(num_freqs*(interp_factor-1),1);freq_response(1:num_freqs_cut2-1)];
imp_response_complex = ifft(imp_response_fft);
imp_response = abs(ifft(imp_response_fft));

%Account for interp in num_freqs
num_freqs = num_freqs*interp_factor;
num_freqs_cut2 = num_freqs_cut2*interp_factor;

%Now the fun part, finding the ToA from the impulse response
[max_peak, max_peak_idx] = max(imp_response);
max_peak = max_peak(1);
max_peak_idx = max_peak_idx(1);

%We'll define the ToA as the first time the impulse response gets above 10%
% of the max peak amplitude
start_window_idx = max_peak_idx - num_freqs_cut2;
if(start_window_idx < 1) 
    start_window_idx = start_window_idx + num_freqs;
    toa_window = [imp_response(start_window_idx:end);imp_response(1:max_peak_idx)];
else
    toa_window = imp_response(start_window_idx:max_peak_idx);
end
toa_thresh = find(toa_window > (max_peak*.1));
toa_thresh = toa_thresh(1);

toa_idx = start_window_idx+toa_thresh-1;
if(toa_idx > num_freqs)
    toa_idx = toa_idx - num_freqs;
end
if(toa_idx > num_freqs_cut2)
    toa_idx = toa_idx - num_freqs;
end
