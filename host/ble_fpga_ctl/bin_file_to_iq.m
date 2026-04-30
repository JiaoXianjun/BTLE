% Xianjun Jiao; putaoshu@msn.com

function iq = bin_file_to_iq(filename_bin, data_format)
% bin file: copmlex, format (uint8, int16, etc.), i/q interleaved
if exist('data_format', 'var') ~= 1
    data_format = 'int16';
end

fid = fopen(filename_bin);
if fid == -1
    disp('fopen failed!');
    return;
end

##iq = fread(fid, inf, 'uint8');
iq = fread(fid, inf, data_format);
fclose(fid);

iq(1:2:end) = iq(1:2:end) - mean(iq(1:2:end));
iq(2:2:end) = iq(2:2:end) - mean(iq(2:2:end));
iq = iq(1:2:end) + 1i.*iq(2:2:end);
