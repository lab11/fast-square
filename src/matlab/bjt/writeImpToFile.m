function ret = writeImpToFile(imp, imp_toas, measured_toa_errors, filename)

INTERP = 64;

t = (1:size(imp,2))/(4e6*256)/INTERP*1e9;

imp_rotate_amount = floor((measured_toa_errors-measured_toa_errors(1))/3e8*INTERP*(4e6*256));
imp_rotated = zeros(size(imp));
for ii=1:size(imp,1)
	imp_rotated(ii,:) = circshift(imp(ii,:),[0,-imp_rotate_amount(ii)]);
	imp_rotated(ii,:) = imp_rotated(ii,:)./max(abs(imp_rotated(ii,:)));
end

ret = imp_toas-measured_toa_errors.';

imp_rotate_amount = floor(imp_toas(1)/3e8*INTERP*(4e6*256));
imp_rotated = circshift(imp_rotated,[0,-imp_rotate_amount+500]);

csvwrite(filename,[t.',abs(imp_rotated.')]);

ret = ret-imp_toas(1)+500*3e8/INTERP/(4e6*256);

ret = ret./3e8*1e9;
