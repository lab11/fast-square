function data = readVerilogData(filename)

data = fileread(filename);

%reshape to Nx4
data = reshape(data,[4,length(data)/4]).';

%Convert hex to decimal
data = hex2dec(data);

%Perform 2s complement
data(data > 32767) = data(data > 32767) - 65536;