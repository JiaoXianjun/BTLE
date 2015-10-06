function test_btle_rx
pdy_type_str = {'ADV_IND', 'ADV_DIRECT_IND', 'ADV_NONCONN_IND', 'SCAN_REQ', 'SCAN_RSP', 'CONNECT_REQ', 'ADV_SCAN_IND', 'Reserved', 'Reserved', 'Reserved', 'Reserved', 'Reserved', 'Reserved', 'Reserved', 'Reserved'};

a = load('sample_iq_4msps.txt');
a = a';
a = a(:)';
a = a(1:2:end) + 1i.*a(2:2:end);

% subplot(3,1,1); plot(abs(a));
% subplot(3,1,2); plot(angle(a));
% subplot(3,1,3); plot(angle(a(2:end)./a(1:end-1)), 'r.-');

max_num_scramble_bits = (39 + 3)*8; % 39 is maximum pdu length in octets; 3 is the number of CRC post-fix octets.
scramble_bits = scramble_gen(37, max_num_scramble_bits);

sample_per_symbol = 4;
match_bit = de2bi(hex2dec('8E89BED6AA'), 40, 'right-msb');
num_pdu_header_bits = 16;
sp = 1;
while 1
    sp_new = search_unique_bits(a(sp:end), match_bit, sample_per_symbol);
    if sp_new == -1
        break;
    end
    sp = sp + sp_new -1 + length(match_bit)*sample_per_symbol;
    disp(['relative sp ' num2str(sp_new) ' absolute sp ' num2str(sp)]);
    
    % pdu header
    pdu_header_bits = demod_bits(a(sp:end), num_pdu_header_bits, sample_per_symbol);
    pdu_header_bits = xor(pdu_header_bits, scramble_bits(1:num_pdu_header_bits));
    [pdu_type, tx_add, rx_add, payload_len] = parse_adv_pdu_header_bits(pdu_header_bits);
    sp = sp + num_pdu_header_bits*sample_per_symbol;
    
    % pdu payload + 3 crc octets
    num_pdu_payload_crc_bits = (payload_len+3)*8;
    pdu_payload_crc_bits = demod_bits(a(sp:end), num_pdu_payload_crc_bits, sample_per_symbol);
    pdu_payload_crc_bits = xor(pdu_payload_crc_bits, scramble_bits( (num_pdu_header_bits+1) : (num_pdu_header_bits+num_pdu_payload_crc_bits)));

    crc_24bits = ble_crc([pdu_header_bits pdu_payload_crc_bits(1:(end-3*8))], '555555');
%     disp(num2str(crc_24bits));
%     disp(num2str(pdu_payload_crc_bits((end-3*8+1):end)));
    
    disp(['   PDU Type: ' pdy_type_str{pdu_type+1}]);
    disp(['     Tx Add: ' num2str(tx_add)]);
    disp(['     Rx Add: ' num2str(rx_add)]);
    disp(['Payload Len: ' num2str(payload_len)]);
    if sum(crc_24bits==pdu_payload_crc_bits((end-3*8+1):end)) == 24
        disp(' CRC Result: OK');
    else
        disp(' CRC Result: Bad');
    end
    
    sp = sp + num_pdu_payload_crc_bits*sample_per_symbol;
end

function reg_bits = ble_crc(pdu, init_reg_bits)

reg_bits = de2bi(hex2dec(init_reg_bits), 24, 'right-msb');
for i = 1 : length(pdu)
    reg_bits = LFSR_crc(reg_bits, pdu(i));
end
reg_bits = reg_bits(end:-1:1);

function [seq] = LFSR_crc(old_seq, pdu_bit)
proc_bit = xor(old_seq(24), pdu_bit);

seq(1) = proc_bit;
seq(2) = xor(old_seq(1), proc_bit);
seq(3) = old_seq(2);
seq(4) = xor(old_seq(3), proc_bit);
seq(5) = xor(old_seq(4), proc_bit);
seq(6) = old_seq(5);
seq(7) = xor(old_seq(6), proc_bit);
seq(8:9) = old_seq(7:8);
seq(10) = xor(old_seq(9), proc_bit);
seq(11) = xor(old_seq(10), proc_bit);
seq(12:24) = old_seq(11:23);


function scramble_bits = scramble_gen(channel_number, num_bit)

bit_store = zeros(1, 7);
bit_store_update = zeros(1, 7);

% channel_number_bin = dec2bin(channel_number, 6);
% 
% bit_store(1) = 1;
% bit_store(2) = ( channel_number_bin(1) == '1' );
% bit_store(3) = ( channel_number_bin(2) == '1' );
% bit_store(4) = ( channel_number_bin(3) == '1' );
% bit_store(5) = ( channel_number_bin(4) == '1' );
% bit_store(6) = ( channel_number_bin(5) == '1' );
% bit_store(7) = ( channel_number_bin(6) == '1' );

channel_number_bin = de2bi(channel_number, 6, 'left-msb');

bit_store(1) = 1;
bit_store(2:7) = channel_number_bin;

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

scramble_bits = bit_seq;

  
function [pdu_type, tx_add, rx_add, payload_len] = parse_adv_pdu_header_bits(bits)
% pdy_type_str = {'ADV_IND', 'ADV_DIRECT_IND', 'ADV_NONCONN_IND', 'SCAN_REQ', 'SCAN_RSP', 'CONNECT_REQ', 'ADV_SCAN_IND', 'Reserved', 'Reserved', 'Reserved', 'Reserved', 'Reserved', 'Reserved', 'Reserved', 'Reserved'};
pdu_type = bi2de(bits(1:4), 'right-msb');
% disp(['   PDU Type: ' pdy_type_str{pdu_type+1}]);

tx_add = bits(7);
% disp(['     Tx Add: ' num2str(tx_add)]);

rx_add = bits(8);
% disp(['     Rx Add: ' num2str(rx_add)]);

payload_len = bi2de(bits(9:15), 'right-msb');
% disp(['Payload Len: ' num2str(payload_len)]);


function bits = demod_bits(a, num_bits, sample_per_symbol)

bits = zeros(1, num_bits);
k = 1;
for i = 1 : sample_per_symbol : (1 + (num_bits-1)*sample_per_symbol)
    I0 = real(a(i));
    Q0 = imag(a(i));
    I1 = real(a(i+1));
    Q1 = imag(a(i+1));

    if (I0*Q1 - I1*Q0) > 0
        bits(k) = 1;
    else
        bits(k) = 0;
    end
    k = k + 1;
end

function sp = search_unique_bits(a, match_bit, sample_per_symbol)

demod_buf_len = length(match_bit); % in bits
demod_buf_offset = 0;

demod_buf = zeros(sample_per_symbol, demod_buf_len);
i = 1;
while 1
    
    sp = mod(demod_buf_offset-demod_buf_len+1, demod_buf_len);
    
    for j = 1 : sample_per_symbol
        I0 = real(a(i+j-1));
        Q0 = imag(a(i+j-1));
        I1 = real(a(i+j-1+1));
        Q1 = imag(a(i+j-1+1));

        if (I0*Q1 - I1*Q0) > 0
            demod_buf(j, demod_buf_offset+1) = 1;
        else
            demod_buf(j, demod_buf_offset+1) = 0;
        end
        
        k = sp;
        unequal_flag = 0;
        for p = 1 : demod_buf_len
            if demod_buf(j, k+1) ~= match_bit(p);
                unequal_flag = 1;
                break;
            end
            k = mod(k + 1, demod_buf_len);
        end
        
        if unequal_flag==0
            break;
        end
        
    end
    
    if unequal_flag==0
        sp = i+j-1-(demod_buf_len-1)*sample_per_symbol;
%         disp(num2str(sp));
        return;
    end 
    
    i = i + sample_per_symbol;
    if (i+sample_per_symbol) > length(a)
        break;
    end
    
    demod_buf_offset = mod(demod_buf_offset+1, demod_buf_len);

end

sp = -1;
phase = -1;
