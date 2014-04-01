if_cal_m = zeros(size(anchor_positions,1),1);
if_cal_b = zeros(size(anchor_positions,1),1);

%All of this is aligning to anchor 1.  Can't do absolute
for ii=2:size(anchor_positions,1)
    angle_diff = squeeze(angle(square_phasors(ii,:,:))-angle(square_phasors(1,:,:)));
    angle_diff(angle_diff < -pi) = angle_diff(angle_diff < -pi) + 2*pi;
    angle_diff(angle_diff > pi) = angle_diff(angle_diff > pi) - 2*pi;
    
    %Perform simple linear regression
    angle_diff = angle_diff(:);
    harmonic_freqs_temp = harmonic_freqs(:);
    p = polyfit(harmonic_freqs_temp,angle_diff,1);
    if_cal_b(ii) = p(2);
    if_cal_m(ii) = p(1);
end

save if_cal if_cal_m if_cal_b