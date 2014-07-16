function ret = phasorsPostMovement(start_dist, end_dist, freqs, num_per_group)

num_freqs = length(freqs);

%Return an array of post-movement phasors
ret = zeros(num_freqs,1);

%Distance per observation
dist_per_obs = (end_dist-start_dist)/ceil(num_freqs/num_per_group);
obs_num = 0;

for freq_idx = 1:num_per_group:num_freqs
    end_freq_idx = min(freq_idx+num_per_group-1,num_freqs);
    obs_start_dist = start_dist+dist_per_obs*obs_num;
    
    cur_freqs = freqs(freq_idx:end_freq_idx);
    
    phasors = exp(1i.*cur_freqs./3e8.*obs_start_dist);
    phasors = phasors.*(1./(1i.*dist_per_obs./3e8.*cur_freqs));
    phasors = phasors.*(exp(1i.*dist_per_obs./3e8.*cur_freqs)-1);
    
    ret(freq_idx:end_freq_idx) = phasors;
    
    obs_num = obs_num + 1;
end