% Xianjun Jiao; putaoshu@msn.com
function a = water_fall(iq, fft_size, num_sample_feed_to_fft, sample_resolution)
num_col = floor((length(iq)-num_sample_feed_to_fft+1)/sample_resolution);
a = zeros(fft_size, num_col);
for i = 1 : num_col
    sp = (i-1)*sample_resolution + 1;
    ep = sp + num_sample_feed_to_fft - 1;
    a(:, i) = abs(fft(iq(sp:ep), fft_size)).^2;
end

fft_size_half = fft_size/2;
a = [a((fft_size_half+1):end,:); a(1:fft_size_half,:)];

% pcolor(a);
figure;
image(a, 'CDataMapping','scaled');
colorbar;
