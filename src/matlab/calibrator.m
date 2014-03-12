phase_steps = [];
for ii=1:33
load(['timestep',num2str(ii)]);
phase_steps = [phase_steps,phase_step];
end
phase_steps(phase_steps < 0) = phase_steps(phase_steps < 0) + 2*pi;

cal_phase_step = mean(phase_steps,2);
save('cal_phase_step','cal_phase_step');