function [carrier_freq, carrier_phase, subcarrier_freq, subcarrier_phase] = extractSubcarrierParameters(iq_data, sample_rate, decim_factor, square_freq_lo, square_freq_hi, square_freq_step, offset_freq_lo, offset_freq_hi, offset_freq_step)
%This function takes COMB-filtered and decimated baseband data and finds the most-likely square wave 
% and carrier offset frequency


