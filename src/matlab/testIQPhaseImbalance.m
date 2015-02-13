freqs = -pi:.01:pi;
bb_len = 1000;
q_phase = pi/2*1.38;

out = zeros(size(freqs));
for freq_idx = 1:length(freqs)
	freq = freqs(freq_idx);
	bb = exp(1i*freq*(0:bb_len-1)/bb_len);
	bb_i = bb.*exp(-1i*freq*(0:bb_len-1)/bb_len);
	bb_q = bb.*exp(-1i*(freq*(0:bb_len-1)/bb_len+q_phase));
	out(freq_idx) = mean(real(bb_i)) + 1i*mean(real(bb_q));
end
