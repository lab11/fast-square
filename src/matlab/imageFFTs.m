for ii=1:4
subplot(2,2,ii);
imagesc(abs(fft(squeeze(cur_iq_data(ii,:,:)),[],2)));
colorbar
end
