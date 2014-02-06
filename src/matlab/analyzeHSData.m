RECORD_TICKS = 35000;
total_ticks = RECORD_TICKS + 1 + 642 + 31;

data_iq0 = readHSData('usrp_chan0.dat');
data_iq1 = readHSData('usrp_chan1.dat');
data_iq2 = readHSData('usrp_chan2.dat');
data_iq3 = readHSData('usrp_chan3.dat');

num_steps = 32;

restarts = find(data_iq0 == -32768+-32768*1i);
res_diff = diff(restarts);
restarts = restarts(find(res_diff > 1));

clear data data_iq data_iq_baseband
