% Xianjun Jiao; putaoshu@msn.com

function iq = test_rx_iq_show(freq_hz, sampling_rate_hz)
if exist('freq_hz', 'var') ~= 1
    freq_hz = 1575e6;
end
if exist('sampling_rate_hz', 'var') ~= 1
    sampling_rate_hz = 8e6;
end

rx_iq_filename = ['rx_iq_' num2str(freq_hz) 'Hz_' num2str(sampling_rate_hz) 'sps.bin'];

ssh_cmd  = ['ssh root@10.10.10.10 ./btle_ll -q 1 -o 1 -n ' num2str(freq_hz)]

[status, output] = system(ssh_cmd);
if status ~= 0
    error('SSH command failed: %s', output);
end

disp(output);

[status, output] = system(['scp root@10.10.10.10:' rx_iq_filename ' ./']);
if status ~= 0
    error('SCP command failed: %s', output);
end

disp(rx_iq_filename);

iq = bin_file_to_iq(rx_iq_filename);

fft_size = 1024;
num_sample_feed_to_fft = 1024;
sample_resolution = 1024;
tmp = water_fall(iq, fft_size, num_sample_feed_to_fft, sample_resolution);

