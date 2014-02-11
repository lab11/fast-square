source_coord = [0, 3, 0];
freqs = [4.32e9-12e6:8e5:5.312e9+12e6];

antenna_coords = constructArray('mills', 0.2, 20);
antenna_coords = [antenna_coords(:,1),antenna_coords(:,3),antenna_coords(:,2)+1];
num_ant = size(antenna_coords,1)

[toas, freq_responses] = simulateAntennaArrayToA(source_coord, antenna_coords, freqs, 1, 1);
[toas_single, freq_responses_single] = simulateAntennaArrayToA(source_coord, antenna_coords, freqs, 1, 0);

csvwrite('two_path_theory.csv',[(freqs/1e9).',(abs(freq_responses(1,:))./abs(freq_responses_single(1,:))).',angle(freq_responses(1,:)).']);
