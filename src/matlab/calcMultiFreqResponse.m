function ret = calcMultiFreqResponse(rcv_coord, multi_coords, multi_delays, multi_mags, freqs)

%Restructure incoming vectors to make sure they're in the right orientation
rcv_coord = rcv_coord(:).';

%Calculate the delay of each incident multipath component
num_paths = size(multi_coords,1);
multi_vec = multi_coords-repmat(rcv_coord,[num_paths,1]);
multi_delays = multi_delays + sqrt(sum(multi_vec.^2,2))/3e8;

%Also figure out how much attenuation these paths will impart (approx.)
path_loss = 4*pi*multi_delays/(3e8/freqs(1));

%Now go through each of the given frequencies and compute the mag, phase,
%at the given coordinate
num_freqs = length(freqs);
ret = zeros(num_freqs,1);
for ii=1:num_freqs
    cur_freq = freqs(ii);
    incident_phase_vecs = exp(-1i*2*pi*cur_freq*multi_delays)./path_loss.*multi_mags;
    ret(ii) = sum(incident_phase_vecs);
end