function test_btle_rx

a = load('sample_iq_4msps.txt');
a = a';
a = a(:)';
a = a(1:2:end) + 1i.*a(2:2:end);

subplot(3,1,1); plot(abs(a));
subplot(3,1,2); plot(angle(a));
subplot(3,1,3); plot(angle(a(2:end)./a(1:end-1)), 'r.-');

sample_per_symbol = 4;
match_bit = de2bi(hex2dec('8E89BED6AA'), 40, 'right-msb');
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
        disp(num2str([i-demod_buf_len*sample_per_symbol j] ));
        break;
    end 
    
    i = i + sample_per_symbol;
    if (i+sample_per_symbol) > length(a)
        break;
    end
    
    demod_buf_offset = mod(demod_buf_offset+1, demod_buf_len);

end
