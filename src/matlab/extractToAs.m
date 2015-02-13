function [imp_toas, imp] = extractToAs(iq_fft, actual_fft, thresh_in, skip_windowing)

INTERP = 64;
THRESH = 0.2;

num_antennas = size(iq_fft,1);
num_timepoints = size(iq_fft,3);

if (nargin < 4) || (skip_windowing == 0)
    ham = hamming(size(actual_fft,2));
else
    ham = ones(size(actual_fft,2),1);
end
ham = fftshift(ham);

imp_toas = zeros(num_antennas, num_timepoints);

for ii=1:num_timepoints
    imp_fft = iq_fft(:,:,ii).*repmat(shiftdim(ham,-1),[num_antennas,1])./actual_fft;%repmat(shiftdim(actual_fft,-1),[num_antennas,1]);
    
    %zero-pad
    imp_fft = [imp_fft(:,1:ceil(size(imp_fft,2)/2)),zeros(size(imp_fft,1),INTERP*size(imp_fft,2)),imp_fft(:,ceil(size(imp_fft,2)/2)+1:end)];
    imp = ifft(imp_fft,[],2);

    %Find maxes for normalization
    [imp_maxes, imp_max_idxs] = max(imp,[],2);
    %keyboard;
    
    %Shift everything to the right as far as the latest max peak
    imp = circshift(imp,[0,-imp_max_idxs(1)]);
    %last_peak = max(imp_max_idxs);
    %if(last_peak > 3*size(imp,2)/4)
    %    imp = circshift(imp,[0,-floor(size(imp,2)/4)]);
    %    [~, imp_max_idxs] = max(imp,[],2);
    %    last_peak = max(imp_max_idxs);
    %end
    %imp = circshift(imp,[0,size(imp,2)-last_peak]);
    
    imp_norm = imp./repmat(imp_maxes,[1,size(imp,2)]);

    %Find peak of first impulse and see if we need to rotate
    for jj=1:num_antennas
        gt_thresh = [0, find(abs(imp_norm(jj,:)) > thresh_in(jj))];
	gt_thresh(1) = gt_thresh(end)-size(imp_norm,2);
        gt_thresh_diff = diff(gt_thresh);
        [~,gt_thresh_diff_max] = max(gt_thresh_diff);
        imp_toas(jj,ii) = gt_thresh(gt_thresh_diff_max+1);
    end
    %keyboard;
    
%     num_backsearch = floor(size(imp,2))/4;
%     start_idx = toa1-num_backsearch+1;
%     if(start_idx < 1)
%         imp = circshift(imp,[0,floor(size(imp,2)/4)]);
%     end
%     for jj=1:num_antennas
%         imp_toas(jj,ii) = find(abs(imp(jj,:)) > THRESH,1);
%     end
    %ii
end

