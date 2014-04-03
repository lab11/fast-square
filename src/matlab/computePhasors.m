%Only to be used after all timesteps have been computed and a new run has
%been initiated to populate square_phasors and est_max_idx
rps = zeros([213,size(square_phasors)]);
for ii=2:213
    
    load(['timestep',num2str(ii)]);
    
    rps(ii,:,:,:) = square_phasors;
    
    %Perform localization operations
    recomputed_phasors = square_phasors;

    recomputed_phasors = recomputed_phasors./abs(recomputed_phasors);

    recomputed_phasors = recomputed_phasors.*exp(-1i*repmat(physical_distances(:,est_max_idx),[1,size(recomputed_phasors,2),size(recomputed_phasors,3)]).*repmat(shiftdim(harmonic_freqs_abs,-1),[size(recomputed_phasors,1),1,1])./3e8*2*pi);
    recomputed_phasors = recomputed_phasors.*conj(repmat(recomputed_phasors(1,:,:),[4,1,1]));

    est_likelihood = abs(sum(sum(sum(recomputed_phasors,1),3),2));
end

for ii=2:4
    subplot(2,2,ii);
    blah = angle(rps(:,ii,:,:))-angle(rps(:,1,:,:));
    blah(blah < -pi) = blah(blah < -pi) + 2*pi;
    blah(blah > pi) = blah(blah > pi) - 2*pi;
    hist(blah(:),1000);
end