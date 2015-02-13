function ret = attenuateFreq(iq_data, freq)

iq_data_size = size(iq_data);
iq_len = iq_data_size(end);

freq_iq = exp(1i*(0:iq_len-1)*2*pi).';

freq_iq = repmat(shiftdim(freq_iq,-(length(iq_data_size)-1)),[iq_data_size(1:end-1),1]);

iq_phasors = sum(iq_data.*freq_iq,length(size(iq_data)));
iq_phasors = iq_phasors./iq_len;

iq_data_corrected = iq_data.*exp
