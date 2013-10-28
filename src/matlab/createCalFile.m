num_freqs = num_subfreqs*num_freq_steps;


%For now, the cal coefficients are non-existent
dlmwrite('cal.dat',ones(num_freqs,2),' ');
