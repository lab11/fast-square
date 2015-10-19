%for ii=1:50
%	cur_iq_data = cur_iq_data.*exp(-1i*he_idxs(:,:,:,1).*repmat(freq_offs,[size(cur_iq_data,1),1,size(cur_iq_data,3)]));
%	%blah = cat(3,cur_iq_data,zeros(size(cur_iq_data,1),size(cur_iq_data,2),size(cur_iq_data,3)*(interp-1)));
%	blah = cur_iq_data;
%	blah = fft(blah,[],3);
%end

%Subtract any frequency offset including tune offset and prf-induced offset at each snapshot
if(use_image)
	freq_offs = 2*pi*((prf_est-prf)*((start_lo_freq-if_freq+step_freq*(0:num_steps-1))/prf)-tune_offset)/(sample_rate/decim_factor);
else
	freq_offs = 2*pi*((prf_est-prf)*((start_lo_freq+if_freq+step_freq*(0:num_steps-1))/prf)-tune_offset)/(sample_rate/decim_factor);
end
cur_iq_data_temp = cur_iq_data_temp.*exp(he_idxs.*repmat(freq_offs,[size(cur_iq_data_temp,1),1,size(cur_iq_data_temp,3)]));

cur_iq_data_fft = fft(cur_iq_data_temp,fft_len,3);
square_phasors = cur_iq_data_fft(:,:,sp_idxs);

for cur_freq_step = 1:size(cur_iq_data,2)
	if(use_image)
		harmonic_freqs(cur_freq_step,:) = prf_est*harmonic_nums+(prf_est-prf)*((start_lo_freq-if_freq+step_freq*(cur_freq_step-1))/prf)-tune_offset;
	else
		harmonic_freqs(cur_freq_step,:) = prf_est*harmonic_nums+(prf_est-prf)*((start_lo_freq+if_freq+step_freq*(cur_freq_step-1))/prf)-tune_offset;
	end
end
