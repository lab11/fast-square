num_ant = 4;
num_coherent = 4;
source_coord = [0, 3, 0];
freqs = [4.32e9-12e6:8e6:5.312e9+12e6]+960e6;

num_freq = length(freqs);

%Construct linear array for now (4-element linear array along one 3-meter wall)
%antenna_coords = [-3,0,0;3,0,3;-3,6,3;3,6,0];
%antenna_coords = constructArray('linear', 1.0, num_ant);
antenna_coords = constructArray('mills', 0.2, 20);
antenna_coords = [antenna_coords(:,1),antenna_coords(:,3),antenna_coords(:,2)+1];
num_ant = size(antenna_coords,1)

%Transform to frequency response at each anchor antenna
[toas, freq_responses] = simulateAntennaArrayToA(source_coord, antenna_coords, freqs, 1, 1);

%Construct search space for the source
[x,y,z] = meshgrid(-3:0.05:3, 0:0.05:6, 0);
search_coords = [x(:),y(:),z(:)];

%Calculate distances for each antenna, coordinate pair
distances = repmat(search_coords,[num_ant,1])-reshape(repmat(shiftdim(antenna_coords,-1),[size(search_coords,1),1,1]),[num_ant*size(search_coords,1),3]);
distances = sqrt(sum(distances.^2,2));

%Convert to phase
phases = repmat(distances,[1,num_freq]).*repmat(freqs,[size(distances,1),1])./3e8.*2.*pi;
phases = reshape(phases,[size(search_coords,1),num_ant,num_freq]);

%Cancel out phase
t = cputime;
search_fresp = repmat(shiftdim(freq_responses,-1),[size(search_coords,1),1]).*exp(1i*phases);

%Add together and take absolute value
search_comb = search_fresp;
%search_comb = reshape(search_comb,[size(search_comb,1),size(search_comb,2),num_coherent,size(search_comb,3)/num_coherent]);
%search_comb = sum(search_comb,3);
search_comb = sum(search_comb,2);
search_comb = sum(abs(search_comb),3);
search_comb = reshape(search_comb,size(x));

%Print how long this search took
e = cputime - t;
disp(['Calculation took ', num2str(e), ' sec'])
