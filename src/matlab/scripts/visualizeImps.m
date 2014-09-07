
num_timesteps = 200;

%Load all imps in so that we can get the max...
imp_maxs = zeros(4,1);
spm = zeros(4,32,8);
est_positions = [];
square_ests = [];
carrier_ests = [];
for ii=2:num_timesteps
	try
		load(['timestep',num2str(ii)]);
		imp_maxs = max(imp_maxs,max(abs(imp),[],2));
		spm = max(spm,abs(square_phasors));
		est_positions = [est_positions; est_position];
		square_ests = [square_ests; square_est];
		carrier_ests = [carrier_ests; carrier_offset];
	catch
	end
end

load anchor_errors
cir_filename = 'cir.gif';
idx = 1;
figure(1);
for ii=2:num_timesteps
	try
		load(['timestep',num2str(ii)]);
		for jj=1:4
			subplot(1,4,jj);
			blah = round((imp_toas+anchor_errors)*(2*square_est*4*32)*64/3e8);
			plot((0:size(imp,2)-1)*1e9/8e6/size(imp,2),circshift(abs(imp(jj,:)),[0,200-blah(3)]));
			xlabel('Time (ns)');
			h = gca;
			set(h,'YTick',[]);
			ylim([0,imp_maxs(jj)]);
			axis tight
			title(['Anchor', num2str(jj)]);
		end
		%title(num2str(idx));
		idx = idx + 1;
		frame = getframe(gcf);
		im = frame2im(frame);
		[imind,cm] = rgb2ind(im,256);
		if ii==2
			imwrite(imind,cm,cir_filename,'gif','Loopcount',inf,'DelayTime',0.1);
		else
			imwrite(imind,cm,cir_filename,'gif','WriteMode','append','DelayTime',0.1);
		end
		ii
	catch
	end
end

figure(2);
%wtp = 130:240;
wtp = 12:180;
subplot(1,2,2);
scatter3(est_positions(wtp,1),est_positions(wtp,2),est_positions(wtp,3),ones(length(wtp),1)*100,1:length(wtp),'filled');
xlim([0, 4.310]);
ylim([0, 7.235]);
zlim([0, 3.212]);
grid on;
subplot(2,4,1);
scatter(est_positions(wtp,1),est_positions(wtp,2),ones(length(wtp),1)*100,1:length(wtp),'filled');
xlim([0, 4.310]);
ylim([0, 7.235]);
title('Top');
grid on;
subplot(2,4,2);
scatter(est_positions(wtp,1),est_positions(wtp,3),ones(length(wtp),1)*100,1:length(wtp),'filled');
xlim([0, 4.310]);
ylim([0, 3.212]);
title('Front');
grid on;
subplot(2,4,5);
scatter(est_positions(wtp,2),est_positions(wtp,3),ones(length(wtp),1)*100,1:length(wtp),'filled');
xlim([0, 7.235]);
ylim([0, 3.212]);
title('Side');
grid on;
