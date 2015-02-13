function ret = modImps(imp_toas,prf_est)

target_toa = imp_toas(1);
mod_dist = 3e8/prf_est;
for jj=2:length(imp_toas)
	while imp_toas(jj) < target_toa - mod_dist/2
		imp_toas(jj) = imp_toas(jj) + mod_dist;
	end
	while imp_toas(jj) > target_toa + mod_dist/2
		imp_toas(jj) = imp_toas(jj) - mod_dist;
	end
end

ret = imp_toas;
