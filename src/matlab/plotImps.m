for ii=1:4
    subplot(2,2,ii);
    blah = squeeze(square_phasors_deconv(ii,:,3:6));
    blah = flipud(blah).';
    blah = blah(:);
    blah = [blah(67:end);blah(1:66)];
    blah = blah.*fftshift(hamming(128));
    blah = [blah(1:64);zeros(1920,1);blah(65:end)];
    plot((0:2047)/2048/(square_freq*2)*1e9,circshift(abs(ifft(blah)),-1500)./max(abs(ifft(blah))))
    xlabel('Time (ns)')
    ylabel('Amplitude');
    title(['Anchor', num2str(ii-1)]);
    axis tight
end