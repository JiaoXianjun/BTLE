% Xianjun Jiao; putaoshu@msn.com

function test_rx_iq_show(freq_hz, duration_ms, sampling_rate_hz)
default_freq_hz = 2402e6;
default_duration_ms = 10;
default_sampling_rate_hz = 8e6;
if exist('freq_hz', 'var') ~= 1
  freq_hz = default_freq_hz;
elseif isstr(freq_hz)
  rx_iq_filename = freq_hz;
elseif isempty(freq_hz) || freq_hz == 0
  freq_hz = default_freq_hz;
end

if exist('duration_ms', 'var') ~= 1
  duration_ms = default_duration_ms;
elseif isempty(duration_ms) || duration_ms == 0
  duration_ms = default_duration_ms;
end

if exist('sampling_rate_hz', 'var') ~= 1
  sampling_rate_hz = default_sampling_rate_hz;
elseif isempty(sampling_rate_hz) || sampling_rate_hz == 0
  sampling_rate_hz = default_sampling_rate_hz;
end

if ~exist('rx_iq_filename', 'var')
  rx_iq_filename = ['rx_iq_' num2str(freq_hz) 'Hz_' num2str(sampling_rate_hz) 'sps.bin'];

  ssh_cmd  = ['ssh root@10.10.10.10 ./btle_ll -q ' num2str(duration_ms) ' -o 1 -n ' num2str(freq_hz)]

  [status, output] = system(ssh_cmd);
  if status ~= 0
    error('SSH command failed: %s', output);
  end

  disp(output);

  [status, output] = system(['scp root@10.10.10.10:' rx_iq_filename ' ./']);
  if status ~= 0
    error('SCP command failed: %s', output);
  end
end

disp(rx_iq_filename);

iq = bin_file_to_iq(rx_iq_filename);

if length(iq) > 0
  fft_size = 128;
  num_sample_feed_to_fft = 10;
  sample_resolution = 2;
  a = water_fall(iq, fft_size, num_sample_feed_to_fft, sample_resolution, sampling_rate_hz);
else
  disp('NO IQ data captured!');
end
