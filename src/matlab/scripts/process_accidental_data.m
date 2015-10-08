addpath('~/repos/fast-square/src/matlab/');
addpath('~/repos/fast-square/src/matlab/bjt');

cd ~/temp/diversity_data/ipsn16/accidental_retest/
analyzeHSCOMBData_bjt('operation','localization','system_setup','diversity');
analyzeHSCOMBData_bjt('operation','diversity_localization','system_setup','diversity');
analyzeHSCOMBData_bjt('operation','post_localization','system_setup','diversity');
