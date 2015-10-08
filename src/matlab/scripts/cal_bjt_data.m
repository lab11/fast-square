addpath('~/repos/fast-square/src/matlab/');
addpath('~/repos/fast-square/src/matlab/bjt');

cd ~/research/harmonium/data/ipsn16/cal_anchor1
analyzeHSCOMBData_bjt('operation','calibration','anchor',1,'system_setup','diversity-cal');
