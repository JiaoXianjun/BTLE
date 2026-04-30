% Xianjun Jiao; putaoshu@msn.com
function a = water_fall(iq, fft_size, num_sample_feed_to_fft, sample_resolution, sampling_rate_hz)
num_col = floor((length(iq)-num_sample_feed_to_fft+1)/sample_resolution);
a = zeros(fft_size, num_col);
for i = 1 : num_col
    sp = (i-1)*sample_resolution + 1;
    ep = sp + num_sample_feed_to_fft - 1;
    a(:, i) = abs(fft(iq(sp:ep), fft_size)).^2;
end

fft_size_half = fft_size/2;
a = [a((fft_size_half+1):end,:); a(1:fft_size_half,:)];

x = [1, size(a,2)];
y = [1, size(a,1)];

if exist('sampling_rate_hz', 'var')
  time_resolution_us = (sample_resolution*(1/sampling_rate_hz))*1e6;
  x = [0, size(a,2).*time_resolution_us];
  y = [-sampling_rate_hz/2, sampling_rate_hz/2];
end

% pcolor(a);
figure;
vmin = prctile(a(:), 0.1);
vmax = prctile(a(:),99.9);
#image(x, y, a, 'CDataMapping','scaled');
imagesc(x, y, a, [vmin, vmax], 'CDataMapping','scaled');
#imshow(x, y, a, 'CDataMapping','scaled');
colorbar;

if exist('sampling_rate_hz', 'var')
  xlabel('Time(us)');
  ylabel('Freq(Hz)');
end

set(gca, 'YDir', 'normal');
