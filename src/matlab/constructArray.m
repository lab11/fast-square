function ret_array = constructArray(array_type, array_spacing, array_dim, array_dim2)

if(strcmp(array_type,'grid'))
    if(nargin < 4)
        array_dim2 = array_dim;
    end
    array_coords = ((0:(array_dim-1))-(array_dim-1)/2)*array_spacing;
    array_coords2 = ((0:(array_dim2-1))-(array_dim2-1)/2)*array_spacing;
    [x,y] = meshgrid(array_coords,array_coords2);
    ret_array = [x(:),y(:),zeros(length(x(:)),1)];
elseif(strcmp(array_type,'circular'))
    %Array spacing is in radians
    angles = 0:array_spacing:(2*pi-eps);
    ret_array = [cos(angles(:))*array_dim/2,sin(angles(:))*array_dim/2,zeros(length(angles(:)),1)];
elseif(strcmp(array_type,'sphere'))
    angles = 0:array_spacing:(2*pi+eps);
    el_angles = -pi/2:array_spacing:pi/2;
    disp(['len(angles) = ', num2str(length(angles)), ', len(el_angles) = ', num2str(length(el_angles))])
    [el,az] = meshgrid(el_angles,angles);
    ret_array = [cos(az(:)).*cos(el(:))*array_dim/2,sin(az(:)).*cos(el(:))*array_dim/2,sin(el(:))*array_dim/2];
elseif(strcmp(array_type,'cube'))
    array_coords = ((0:(array_dim-1))-(array_dim-1)/2)*array_spacing;
    [x,y,z] = meshgrid(array_coords);
    ret_array = [x(:),y(:),z(:)];
elseif(strcmp(array_type,'mills'))
    num_horizontal = ceil(array_dim/2);
    num_vertical = array_dim-num_horizontal;
    h_coords = ((0:(num_horizontal-1))-(num_horizontal-1)/2)*array_spacing;
    v_coords = ((0:(num_vertical-1))-(num_vertical-1)/2)*array_spacing;
    ret_array = [h_coords(:),zeros(num_horizontal,2);zeros(num_vertical,1),v_coords(:),zeros(num_vertical,1)];
elseif(strcmp(array_type,'3dmills'))
    num_horizontal = ceil(array_dim/3);
    num_vertical = num_horizontal;
	num_depth = array_dim-num_horizontal-num_vertical;
    h_coords = ((0:(num_horizontal-1))-(num_horizontal-1)/2)*array_spacing;
    v_coords = ((0:(num_vertical-1))-(num_vertical-1)/2)*array_spacing;
	d_coords = ((0:(num_depth-1))-(num_depth-1)/2)*array_spacing;
    ret_array = [h_coords(:),zeros(num_horizontal,2);zeros(num_vertical,1),v_coords(:),zeros(num_vertical,1);zeros(num_depth,2),d_coords(:)];
elseif(strcmp(array_type,'linear'))
    coords = ((0:(array_dim-1))-(array_dim-1)/2)*array_spacing;
    ret_array = [coords(:),zeros(array_dim,2)];
end
