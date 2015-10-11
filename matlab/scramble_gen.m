function a = scramble_gen(channel_number, num_bit, filename, varargin)

  bit_store = zeros(1, 7);
  bit_store_update = zeros(1, 7);
  
  channel_number_bin = dec2bin(channel_number, 6);
  
  bit_store(1) = 1;
  bit_store(2) = ( channel_number_bin(1) == '1' );
  bit_store(3) = ( channel_number_bin(2) == '1' );
  bit_store(4) = ( channel_number_bin(3) == '1' );
  bit_store(5) = ( channel_number_bin(4) == '1' );
  bit_store(6) = ( channel_number_bin(5) == '1' );
  bit_store(7) = ( channel_number_bin(6) == '1' );
  
  bit_seq = zeros(1, num_bit);
  for i = 1 : num_bit
    bit_seq(i) =  bit_store(7);

    bit_store_update(1) = bit_store(7);

    bit_store_update(2) = bit_store(1);
    bit_store_update(3) = bit_store(2);
    bit_store_update(4) = bit_store(3);

    bit_store_update(5) = mod(bit_store(4)+bit_store(7), 2);

    bit_store_update(6) = bit_store(5);
    bit_store_update(7) = bit_store(6);

    bit_store = bit_store_update;
  end
  
  a = zeros(1, num_bit/8);
  
  for i = 0 : 8 : num_bit-1
    idx = floor(i/8) + 1;
    a(idx) = bit_seq(i+1) + bit_seq(i+2)*2 + bit_seq(i+3)*4 + bit_seq(i+4)*8 + bit_seq(i+5)*16 + bit_seq(i+6)*32 + bit_seq(i+7)*64 + bit_seq(i+8)*128;
  end
  
  if nargin == 3
    save_int_var_for_c(a, ['const uint8_t const scramble_table_ch' num2str(channel_number)], filename, 'w');
  end
  
  