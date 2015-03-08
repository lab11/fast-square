function [ret, final_toa_errors] = runNewtonLocalization(anchor_positions, imp_toas_div, measured_toa_errors, prf_est)

toas = reshape(imp_toas_div-repmat(measured_toa_errors.',[1,size(imp_toas_div,2)]),[prod(size(imp_toas_div)),1]);
toas = modImps(toas,prf_est);
pos0 = [2,2,1];
t0 = toas(1);
%options = optimoptions('fminunc','Algorithm','quasi-newton','TypicalX',[pos0,t0],'Display','iter');
tdoaAnon = @(x)tdoaNewtonError(x(1:3),x(4),toas,anchor_positions);
[val,fval] = fminunc(tdoaAnon,[pos0,t0]);

dists = sqrt(sum((anchor_positions-repmat(val(1:3),[size(anchor_positions,1),1])).^2,2));
final_toa_errors = toas-dists-val(4);

ret = val(1:3);
