if(use_image)
	center_freq_harmonic_num = ((start_lo_freq-if_freq+step_freq*(cur_freq_step-1))/prf);
else
	center_freq_harmonic_num = ((start_lo_freq+if_freq+step_freq*(cur_freq_step-1))/prf);
end
