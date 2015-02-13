%Resize raw data to be a power of two
cur_iq_data = cat(3,cur_iq_data,zeros(size(cur_iq_data,1),size(cur_iq_data,2),fft_len-size(cur_iq_data,3)));

if(strcmp(res.operation,'calibration') | isfield(res,'anchor'))
	prf_anchor = res.anchor;
else
	prf_anchor = 1;
end

cur_iq_fft_abs = squeeze(abs(fft(cur_iq_data(prf_anchor,:,:),[],3))).';
cur_iq_fft_abs_flat = reshape(cur_iq_fft_abs,[prod(size(cur_iq_fft_abs)),1]);

cand_peaks_sum = sum(cur_iq_fft_abs_flat(cand_peaks),2);

[~,cand_peaks_idx] = max(cand_peaks_sum);

prf_est = cand_freqs(cand_peaks_idx);
