for ii=2:443
try
load(['timestep',num2str(ii)]);
for jj=1:4
subplot(2,2,jj);
blah = (imp_toas+anchor_errors)*(2*square_est*4*32)*64/3e8;
plot(circshift(abs(imp(jj,:)),[0,-blah(3)]));
end
catch
end
ii
drawnow
pause
end
