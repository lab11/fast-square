data_set_size = 35000;

blah = [1;zeros(data_set_size-1,1)];
%blah = randn(data_set_size,1) + 1i*randn(data_set_size,1) + exp(1i*(1:data_set_size)*2*pi/16).' + exp(1i*(1:data_set_size)*2*pi/16*3).';
figure(1);plot(20*log10(abs(fft(blah))));
feedback_shift = zeros(8,1);
blah2 = zeros(data_set_size,1);
for ii=1:data_set_size
	blah2(ii) = blah(ii) - (7/8)*feedback_shift(8);
	feedback_shift = [blah2(ii);feedback_shift(1:7)];
end


blah = blah2;
feedback_shift = zeros(8,1);
blah2 = zeros(data_set_size,1);
for ii=1:data_set_size
	blah2(ii) = blah(ii) - (7/8)*feedback_shift(8);
	feedback_shift = [blah2(ii);feedback_shift(1:7)];
end

%Decimate by 17 to space peaks out in frequency
blah_dec = blah2(1:17:end);

figure(2);
plot(20*log10(abs(fft(blah_dec))));

%Try a different approach: IIR filter design
%f = [0 3.8 3.8 4.2 4.2 11.8 11.8 12.2 12.2 19.8 19.8 20.2 20.2 27.8 27.8 28.2 28.2 32]/32;
%m = [0 0   1   1   0   0    1    1    0    0    1    1    0    0    1    1    0    0];
%[b,a] = yulewalk(50,f,m);
%[h,w] = freqz(b,a,1024);
%plot(f,m,w/pi,abs(h),'--')
%legend('Ideal','yulewalk Designed')
%title('Comparison of Frequency Response Magnitudes')
