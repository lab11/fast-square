[num_data,str_data] = xlsread('adcs.xlsx');

%num_data(:,1) => price
%num_data(:,8) => num_converters
%str_data(:,13) => sample_rate

prices = num_data(:,1);
num_converters = num_data(:,8);
sample_rates_str = str_data(:,13);

%Parsing logic for 'sample_rate' field (uses k's, M's, and G's... also can be a range)
sample_rates = zeros(size(prices));
for ii=1:length(prices)
	cur_sr_str = sample_rates_str{ii};
	if(isempty(cur_sr_str) || strcmp(cur_sr_str,'-') || strcmp(cur_sr_str,'*')) 
		continue;
	end

	t = cur_sr_str;
	r = t;
	while ~isempty(r)
		[t,r] = strtok(r,' ');
	end

	%Now that we have the last sample rate, parse it...
	last_char = t(end);
	if(last_char >= 'A')
		if(last_char == 'k') sample_rates(ii) = str2num(t(1:end-1))*1e3;
		elseif(last_char == 'M') sample_rates(ii) = str2num(t(1:end-1))*1e6;
		elseif(last_char == 'G') sample_rates(ii) = str2num(t(1:end-1))*1e9;
		end
	else
		sample_rates(ii) = str2num(t);
	end
end
