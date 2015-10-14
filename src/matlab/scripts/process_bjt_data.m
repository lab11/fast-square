addpath('~/repos/fast-square/src/matlab/');
addpath('~/repos/fast-square/src/matlab/bjt');

cd ~/temp/diversity_data/ipsn16/stationary_tee_unobstructed/
analyzeHSCOMBData_bjt('operation','localization','system_setup','diversity','anchor',3,'mod_index',5);
analyzeHSCOMBData_bjt('operation','diversity_localization','system_setup','diversity','mod_index',5);
analyzeHSCOMBData_bjt('operation','post_localization','system_setup','diversity','mod_index',5);
