close all;

%Loop through all post-processing data
timestep_files = dir('timestep*');
last_step_idx = 0;
for ii=1:length(timestep_files)
	cand_idx = str2num(timestep_files(ii).name(9:end-4));
	if(cand_idx > last_step_idx)
		last_step_idx = cand_idx;
	end
end

file_name = 'abs.gif';
first_time = true;
for ii=1:5:last_step_idx
	try
		load(['timestep',num2str(ii)]);
		imagesc(squeeze(abs(square_phasors(1,:,:))));
		drawnow;
		frame = getframe(1);
		im = frame2im(frame);
		[imind,cm] = rgb2ind(im,256);
		if(first_time)
			imwrite(imind,cm,file_name,'gif', 'Loopcount',inf,'delaytime',1/30);
		else
			imwrite(imind,cm,file_name,'gif','WriteMode','append','delaytime',1/30);
		end
	catch
	end
end
