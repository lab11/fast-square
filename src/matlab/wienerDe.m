function ret = wienerDe(h, s, snr)
%This function calculates the wiener deconvolution of the incoming signal

ret = s./h.*(1./(1+1./snr));
ret(isnan(ret)) = 0;