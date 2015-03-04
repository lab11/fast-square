function ret = transformOptitrackCoords(optitrack_coords)

%reorder & apply offset
real_coords = [-optitrack_coords(:,1)+1.524,-optitrack_coords(:,3)+1.77795,optitrack_coords(:,2)];

ret = real_coords;
