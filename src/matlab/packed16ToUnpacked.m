function ret = packed16ToUnpacked(data_in)

%Make room for repmat in end-1'st dimension
data_in_size = size(data_in);
data_in = reshape(data_in,[data_in_size(1:end-1),1,data_in_size(end)]);

%Repeat data_in for each packed location
data_in_rep = ones(1,ndims(data_in));
data_in_rep(end-1) = 16;
data_in = repmat(data_in,data_in_rep);

%Power-of-2 array for later AND-ing with data array
p2_array = repmat(shiftdim(2.^(15:-1:0),3-ndims(data_in)),[data_in_size(1:end-1),1,data_in_size(end)]);

ret = (bitand(real(data_in),p2_array) > 0) + 1i*(bitand(imag(data_in),p2_array) > 0);

%Get rid of DC component
ret = ret - .5 - 1i*.5;

ret_out_size = data_in_size;
ret_out_size(end) = ret_out_size(end) * 16;
ret = reshape(ret,ret_out_size);

