which_anchors = 1:4;

%Get difference in phase across steps in order to compensate 'movement'
phase_diffs = square_phasors(which_anchors,2:32,6:7).*conj(square_phasors(which_anchors,1:31,2:3)./abs(square_phasors(which_anchors,1:31,2:3)));

%Average phase_diffs out over anchors
phase_diffs = squeeze(angle(sum(sum(phase_diffs,1),3)));

%Applied phase difference equals the [0,cumulative sum over phase differences]
applied_phase = [0;cumsum(phase_diffs)];

square_phasors = square_phasors.*exp(-1i*repmat(shiftdim(applied_phase,-1),[size(square_phasors,1),1,size(square_phasors,3)]));
