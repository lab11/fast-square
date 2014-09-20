impulse_data_cur = load('impulse_data_v2_cand.txt');

sample_rate = 14e9*20;
prf = 4e6;
R = 50;

t = 0:1/sample_rate:1/prf;

impulse_data = interp1(impulse_data_cur(:,1),impulse_data_cur(:,2),t,'linear');
impulse_data(isnan(impulse_data)) = 0;

%Normalized FFT
S=fft(impulse_data)./length(impulse_data);

%Power spectrum
Sp=10*log10((abs(S).^2)/R*1000);

plot(linspace(0,sample_rate,length(Sp)),Sp);

%S(1:100) = 0;
%S(end-99:end) = 0;
%plot(abs(ifft(S)));
