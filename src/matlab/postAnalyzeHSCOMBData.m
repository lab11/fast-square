num_timepoints = 213;

square_phasors_all = zeros(4,32,8,num_timepoints);
carrier_offset_all = zeros(num_timepoints,1);
square_est_all = zeros(num_timepoints,1);
for ii=1:num_timepoints
	load(['timestep', num2str(ii)]);
	square_phasors_all(:,:,:,ii) = square_phasors;
	carrier_offset_all(ii) = carrier_offset;
	square_est_all(ii) = square_est;
end
square_phasors_diff = squeeze(angle(square_phasors_all(2,:,:,:))-angle(square_phasors_all(1,:,:,:)));
square_phasors_diff2 = diff(square_phasors_diff,1,3);
square_phasors_diff2(square_phasors_diff2 > pi) = square_phasors_diff2(square_phasors_diff2 > pi) - 2*pi;
square_phasors_diff2(square_phasors_diff2 < -pi) = square_phasors_diff2(square_phasors_diff2 < -pi) + 2*pi;
hist(square_phasors_diff2(:),1000)
