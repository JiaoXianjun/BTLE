clear all;
close all;

num_bit = 42*8; % 42 = 2(pdu header) + 37(maximum payload length) + 3(CRC octets)
a = zeros(40, num_bit/8);
for channel_number = 0:39
    a(channel_number+1, :) = scramble_gen(channel_number, num_bit, ' ', 1);
end

save_int_var_for_c_2d(a, 'const uint8_t const scramble_table', 'scramble_table.h', 'w');
