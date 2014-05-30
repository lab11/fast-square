num_timepoints = 213;
num_anchors = 4;

square_phasors_all = zeros(num_anchors,32,8,num_timepoints);
carrier_offset_all = zeros(num_timepoints,1);
square_est_all = zeros(num_timepoints,1);
est_likelihoods = zeros(81,81,81,num_timepoints);
est_positions = zeros(num_timepoints,3);
for ii=2:num_timepoints %Start at 2 because 1 tends to have alignment issues
	load(['timestep', num2str(ii)]);
	square_phasors_all(:,:,:,ii) = square_phasors;
	carrier_offset_all(ii) = carrier_offset;
	square_est_all(ii) = square_est;
	est_likelihoods(:,:,:,ii) = est_likelihood;
	est_positions(ii,:) = est_position;
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

figure(5);
phase_step_diffs = zeros(num_anchors,size(square_phasors,2)-1,size(square_phasors,3)/2,num_timepoints);
for ii=1:num_timepoints
	for jj=1:num_anchors
		blah = squeeze(angle(square_phasors_all(jj,:,:,ii)));
		blah2 = blah(2:32,5:8)-blah(1:31,1:4);
		blah2(blah2 > pi) = blah2(blah2 > pi) - 2*pi;
		blah2(blah2 < -pi) = blah2(blah2 < -pi) + 2*pi;
		phase_step_diffs(jj,:,:,ii) = shiftdim(blah2,-1);
	end
end
for ii=1:num_anchors
	cur_phase_step_diffs = squeeze(phase_step_diffs(ii,:,2:3,:));
	subplot(2,2,ii);
	hist(cur_phase_step_diffs(:),1000);
	xlim([-pi,pi]);
end

%Calculate differential phase measurements.  All measurements done with anchor 1
figure(6);
cal_diff_meas = zeros(num_anchors,1);
for ii=2:num_anchors
	blah = phase_step_diffs(ii,:,:,:)-phase_step_diffs(1,:,:,:);

	%Determine most-populated bin
	[n,x] = hist(blah(:),1000);
	[s,i] = max(n);
	blah_mode = x(i);
	blah(blah > blah_mode+pi) = blah(blah > blah_mode+pi) - 2*pi;
	blah(blah < blah_mode-pi) = blah(blah < blah_mode-pi) + 2*pi;
	cal_diff_meas(ii) = median(blah(:));
	subplot(2,2,ii);
	hist(blah(:),1000);
end
save cal_diff_meas cal_diff_meas

%Make a movie of sequential localization heat maps
figure(7);
clear F;
est_likelihood_filename = 'est_likelihood.gif';
est_likelihood_min = min(est_likelihoods(:));
est_likelihood_max = max(est_likelihoods(:));
for ii=2:num_timepoints
    cur_est_slice = est_likelihoods(:,:,27,ii);
    [~,max_idx] = max(cur_est_slice(:));
    [est_x, est_y] = ind2sub(size(cur_est_slice),max_idx);
	imagesc(est_likelihoods(:,:,27,ii));%,[est_likelihood_min,est_likelihood_max]);
    hold on;
    plot(est_y, est_x, 'o');
    hold off;
    
	text(2,5,[num2str(ii-2)]);
	drawnow;
	frame = getframe;
	im = frame2im(frame);
	[imind,cm] = rgb2ind(im,256);
	if ii==2
		imwrite(imind,cm,est_likelihood_filename,'gif','Loopcount',inf,'DelayTime',0.1);
	else
		imwrite(imind,cm,est_likelihood_filename,'gif','WriteMode','append','DelayTime',0.1);
	end
end
