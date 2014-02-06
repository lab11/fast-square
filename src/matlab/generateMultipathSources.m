function [multi_coords, multi_delays, multi_mags] = generateMultipathSources(source_coord, max_distance, num_paths, los_mag)

%Some #defines to describe the multipath environment

%Restructure incoming vectors to make sure they're in the right orientation
source_coord = source_coord(:).';

%For now, let's just model the reflecting surfaces as being distributed
%evenly in 3D in a cube
multi_coords = (rand(num_paths,3)-.5)*max_distance*2;

%Delay between source_coord and the multipath coordinates is just
% proportional to the distance between them
multi_delays = sqrt(sum(multi_coords.^2,2))/3e8;

%Center the multipath coordinates around the source coordinate
multi_coords = multi_coords + repmat(source_coord,[num_paths,1]);

%Lastly, include the direct LOS path
multi_delays = [0;multi_delays];
multi_coords = [source_coord;multi_coords];
multi_mags = [los_mag;ones(num_paths,1)];