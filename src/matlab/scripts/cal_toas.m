addpath('~/repos/fast-square/src/matlab/');
addpath('~/repos/fast-square/src/matlab/bjt');

cd ~/temp/diversity_data/ipsn16/toa_calibration2
analyzeHSCOMBData_bjt('operation','localization','system_setup','diversity','anchor',3);
analyzeHSCOMBData_bjt('operation','diversity_localization','system_setup','diversity');
analyzeHSCOMBData_bjt('operation','toa_calibration','system_setup','diversity','toa_cal_location',[2.185+0.06,2.028,1.868]);
