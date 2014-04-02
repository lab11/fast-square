%Perform localization operations
recomputed_phasors = square_phasors;

recomputed_phasors = recomputed_phasors./abs(recomputed_phasors);

recomputed_phasors = recomputed_phasors.*exp(-1i*repmat(physical_distances(:,est_max_idx),[1,size(recomputed_phasors,2),size(recomputed_phasors,3)]).*repmat(shiftdim(harmonic_freqs_abs,-1),[size(recomputed_phasors,1),1,1])./3e8*2*pi);
recomputed_phasors = recomputed_phasors.*conj(repmat(recomputed_phasors(1,:,:),[4,1,1]));

est_likelihood = abs(sum(sum(sum(recomputed_phasors,1),3),2));