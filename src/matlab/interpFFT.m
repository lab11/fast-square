function out_fft = interpFFT(in_data, out_len)
in_data_window = hamming(length(in_data));
in_data = in_data(:).*in_data_window;

mid_idx = ceil(length(in_data/2));

out_data = [in_data(1:mid_idx);zeros(out_len-length(in_data),1);in_data(mid_idx+1:end)];
out_fft = fft(out_data);