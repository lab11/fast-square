%Figure out how much time shift is present before adding to tx_phasors
square_phasors_norm = square_phasors./abs(square_phasors);
if max(tx_phasors(:)) == 0
    tx_phasors = squeeze(square_phasors(carrier_anchor,:,:));
end
    
tx_phasors_norm = tx_phasors./abs(tx_phasors);

square_phasors_norm = square_phasors_norm(:,9:24,:);
tx_phasors_norm = tx_phasors_norm(9:24,:);


max_corr = 0;
max_corr_delay = 0;
max_corr_offset = 0;
for time_delay=0:1/square_freq/5000:1/square_freq
    temp_phasors = squeeze(square_phasors_norm(carrier_anchor,:,:)).*exp(1i*time_delay*harmonic_freqs_abs(9:24,:).*(2*pi));
    cur_corr = abs(sum(sum(temp_phasors.*conj(tx_phasors_norm))));
    cur_offset = angle(sum(sum(temp_phasors.*conj(tx_phasors_norm))));
    if(cur_corr > max_corr)
        max_corr = cur_corr;
        max_corr_delay = time_delay;
        max_corr_offset = cur_offset;
    end
end

temp_phasors = squeeze(square_phasors(carrier_anchor,:,:)).*exp(1i*max_corr_delay*harmonic_freqs_abs.*(2*pi));
temp_phasors = temp_phasors.*exp(-1i*max_corr_offset);
%keyboard;

tx_phasors = tx_phasors + temp_phasors;