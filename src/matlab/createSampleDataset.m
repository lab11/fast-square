sample_rate = 1e6;
num_samples = 1e6;
num_freq_steps = 14;
num_subfreqs = 4;
filler_len = 300;

time = (0:length(baseband_rx)-1)/sample_rate;

baseband_rx = zeros(1,num_samples);
baseband_rx = baseband_rx + 0.25*exp(-1i*time*100e3*2*pi);
baseband_rx = baseband_rx + 0.25*exp(-1i*time*200e3*2*pi);
baseband_rx = baseband_rx + 0.01*randn(size(baseband_rx));

stitcher_rx = zeros(1,num_samples);
for ii=1:filler_len*num_freq_steps:num_samples
	stitcher_rx(ii:ii+filler_len) = -1 + -1*1i;
	stitcher_rx(ii+filler_len-num_subfreqs+1:ii+filler_len) = 0.25;
	for jj=2:num_freq_steps
		stitcher_rx(ii+filler_len*(jj-1)+1:ii+filler_len*(jj)) = -1i;
		stitcher_rx(ii+filler_len*jj-num_subfreqs+1:ii+filler_len*jj) = 0.25;
	end
end
stitcher_rx = stitcher_rx(1:num_samples);

baseband_int = [real(baseband_rx);imag(baseband_rx)];

fid = fopen('test.dat','w');
fwrite(baseband_int(:),'float');
fclose(fid);

stitcher_int = [real(stitcher_rx);imag(stitcher_rx)];
fid = fopen('test_freqs.dat','w');
fwrite(stitcher_int(:),'float');
fclose(fid);

