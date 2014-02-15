RECORD_TICKS = 35000;
total_ticks = RECORD_TICKS + 1 + 642 + 31;

%data_iq0 = readHSData('usrp_chan0.dat');
%data_iq1 = readHSData('usrp_chan1.dat');
%data_iq2 = readHSData('usrp_chan2.dat');
data_iq3 = readHSData('usrp_chan3.dat');

%Loop through each timepoint
for ii=1:size(data_iq3,2)
	cur_iq_data = packed16ToUnpacked(squeeze(data_iq3(:,ii,:)));
	keyboard;
end

num_steps = 32;

clear data data_iq data_iq_baseband
