function ret = visCurImps(start_idx)

for ii=1:3
	load(['timestep',num2str(start_idx+ii-1)]);
	for jj=1:4
		subplot(3,4,(ii-1)*4+jj);
		plot(abs(imp(jj,:)))
	end
end
