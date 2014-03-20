num_timepoints = 213;
num_anchors = 4;

square_phasors_all = zeros(num_anchors,32,8,num_timepoints);
carrier_offset_all = zeros(num_timepoints,1);
square_est_all = zeros(num_timepoints,1);
for ii=1:num_timepoints
	load(['timestep', num2str(ii)]);
	square_phasors_all(:,:,:,ii) = square_phasors;
	carrier_offset_all(ii) = carrier_offset;
	square_est_all(ii) = square_est;
end
figure(1);
for ii=1:num_anchors
    first_anchor = ii;
    second_anchor = ii+1;
    if(second_anchor == num_anchors+1)
        second_anchor = 1;
    end
    
    square_phasors_diff = squeeze(angle(square_phasors_all(second_anchor,:,:,:))-angle(square_phasors_all(first_anchor,:,:,:)));
    square_phasors_diff2 = diff(square_phasors_diff,1,3);
    square_phasors_diff2(square_phasors_diff2 > pi) = square_phasors_diff2(square_phasors_diff2 > pi) - 2*pi;
    square_phasors_diff2(square_phasors_diff2 < -pi) = square_phasors_diff2(square_phasors_diff2 < -pi) + 2*pi;
    subplot(2,2,ii);
    hist(square_phasors_diff2(:),1000)
    xlim([-2*pi,2*pi]);
    xlabel('Phase (rad)');
    title(['Between anchors ', num2str(first_anchor), ' and ', num2str(second_anchor)]);
end
suptitle('Consistency of Differential Phase Measurements');
figure(2);
plot(carrier_offset_all/1e3);
title('Observed Carrier Frequency Error');
xlabel('Measurement #');
ylabel('Error (kHz)');
figure(3);
plot(square_est_all-4e6);
title('Observed Subcarrier Frequency Error');
xlabel('Measurement #');
ylabel('Error (Hz)');
figure(4);
blah = squeeze(angle(square_phasors(1,:,:))-angle(square_phasors(2,:,:)));
blah_mean = repmat(mean(blah,2),[1,8]);
blah(blah < blah_mean) = blah(blah < blah_mean) + 2*pi;
imagesc(blah);
title('Single Differential Phase Measurement (Between anchors 1 and 2)');
ylabel('Frequency Step');
xlabel('Harmonic #');
colorbar
