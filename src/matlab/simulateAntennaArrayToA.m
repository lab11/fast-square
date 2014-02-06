function [toas, freq_responses] = simulateAntennaArrayToA(source_coord, ant_coords, freqs, los_mag, num_paths)
%This function assumes that the antenna matrix will be centered around the
%origin (0,0,0)

%Some #defines that aren't 'important enough' to include as arguments
max_distance = 5;
if nargin < 5
	num_paths = 10;
end
interp_factor = 100;

%First generate multipath sources
[multi_coords, multi_delays, multi_mags] = generateMultipathSources(source_coord, max_distance, num_paths, los_mag);

%Next calculate the frequency response at each node in the array
freq_responses = zeros(size(ant_coords,1),length(freqs));
toas = zeros(size(ant_coords,1),1);
for ii=1:size(ant_coords,1)
    cur_x = ant_coords(ii,1);
    cur_y = ant_coords(ii,2);
    cur_z = ant_coords(ii,3);
    
    rcv_coord = [cur_x;cur_y;cur_z];
    freq_responses(ii,:) = calcMultiFreqResponse(rcv_coord, multi_coords, multi_delays, multi_mags, freqs);
    toas(ii) = findToAFromFreqResponse(freq_responses(ii,:), interp_factor);
end

toas = toas+interp_factor*.855;

%Lastly, convert ToAs to meters
bw = freqs(end)-freqs(1);
toas = (toas-.5)/bw*3e8/interp_factor;
