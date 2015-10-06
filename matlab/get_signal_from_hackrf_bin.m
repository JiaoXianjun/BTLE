function [s, status] = get_signal_from_hackrf_bin(filename, num_sample_read)
s = int8(-1);
status = false;

fid = fopen(filename);

if fid == -1
    disp('get_signal_from_hackrf_bin: Can not open file!');
    status = true;
    return;
end

[s, count] = fread(fid, num_sample_read*2, 'int8');
fclose(fid);

% s = int8(s);

if num_sample_read~=inf && count ~= (num_sample_read*2)
    disp('get_signal_from_hackrf_bin: No enough samples in the file!');
    status = true;
    return;
end

% s = single( (s(1:2:end) + 1i.*s(2:2:end))./128 );
% s = (s(1:2:end) + 1i.*s(2:2:end))./128;

s = complex(s(1:2:end), s(2:2:end));

% len_s = length(s);
% 
% s = s((len_s/2)+1:end);
