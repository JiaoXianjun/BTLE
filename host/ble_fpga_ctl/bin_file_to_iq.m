% Xianjun Jiao; putaoshu@msn.com

function iq = bin_file_to_iq(filename_bin)
% bin file: copmlex, uint8, i/q interleaved
fid = fopen(filename_bin);
if fid == -1
    disp('fopen failed!');
    return;
end

iq = fread(fid, inf, 'uint8');
fclose(fid);

iq(1:2:end) = iq(1:2:end) - mean(iq(1:2:end));
iq(2:2:end) = iq(2:2:end) - mean(iq(2:2:end));
iq = iq(1:2:end) + 1i.*iq(2:2:end);
