clear all;
close all;

% original float point version
gauss_coef = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2.231548e-14, 2.007605e-11, 7.561773e-09, 1.197935e-06, 8.050684e-05, 2.326833e-03, 2.959908e-02, 1.727474e-01, 4.999195e-01, 8.249246e-01, 9.408018e-01, 8.249246e-01, 4.999195e-01, 1.727474e-01, 2.959908e-02, 2.326833e-03, 8.050684e-05, 1.197935e-06, 7.561773e-09, 2.007605e-11, 2.231548e-14, 0];
%plot(gauss_coef, 'r+-'); axis([0 length(gauss_coef) 0 0.0001]);

% short it to 16 points:
gauss_coef = [7.561773e-09, 1.197935e-06, 8.050684e-05, 2.326833e-03, 2.959908e-02, 1.727474e-01, 4.999195e-01, 8.249246e-01, 9.408018e-01, 8.249246e-01, 4.999195e-01, 1.727474e-01, 2.959908e-02, 2.326833e-03, 8.050684e-05, 1.197935e-06];
%plot(gauss_coef, 'r+-');

SAMPLE_PER_SYMBOL = 4;
LEN_GAUSS_FILTER = length(gauss_coef)/SAMPLE_PER_SYMBOL;
MAX_NUM_PHY_BYTE  = 47;
MAX_NUM_PHY_SAMPLE = ((MAX_NUM_PHY_BYTE*8*SAMPLE_PER_SYMBOL)+(LEN_GAUSS_FILTER*SAMPLE_PER_SYMBOL));
MOD_IDX = 0.5;
AMPLITUDE = 127;
tmp_phy_bit_over_sampling = zeros(1, MAX_NUM_PHY_SAMPLE + 2*LEN_GAUSS_FILTER*SAMPLE_PER_SYMBOL);
tmp_phy_bit_over_sampling = zeros(1, MAX_NUM_PHY_SAMPLE);

num_bit = MAX_NUM_PHY_BYTE*8;
%bit = round(rand(1, num_bit));
bit = get_number;
num_bit_oversample = num_bit*SAMPLE_PER_SYMBOL;
len_gauss_oversample = LEN_GAUSS_FILTER*SAMPLE_PER_SYMBOL;
num_sample = num_bit_oversample + len_gauss_oversample;

  pre_len = len_gauss_oversample-1;
  tmp_phy_bit_over_sampling(1:pre_len) = 0.0;
  
  post_sp = num_bit_oversample + pre_len + 1;
  post_ep = post_sp + pre_len - 1;
  tmp_phy_bit_over_sampling(post_sp:post_ep) = 0.0;

  tmp_phy_bit_over_sampling((pre_len+1):(pre_len+num_bit_oversample)) = 0;
  tmp_phy_bit_over_sampling((pre_len+1):SAMPLE_PER_SYMBOL:(pre_len+num_bit_oversample)) = bit.*2 - 1;

  % len_conv_result = length(tmp_phy_bit_over_sampling) - len_gauss_oversample + 1
  % = post_ep - len_gauss_oversample + 1
  % = num_bit_oversample + pre_len + 1 + pre_len - 1  - len_gauss_oversample + 1
  % = num_bit_oversample + 2*(len_gauss_oversample-1)  - len_gauss_oversample + 1
  % = num_bit_oversample + len_gauss_oversample - 1
  len_conv_result = num_sample - 1;

% -------------------------------------- float point reference -----------------------------------------------
  for i = 1 : len_conv_result
    acc = 0;
    for j = 1 : len_gauss_oversample
      acc = acc + gauss_coef(len_gauss_oversample-j+1)*tmp_phy_bit_over_sampling(i+j-1); %num_sample - 1+len_gauss_oversample-1= length(tmp_phy_bit_over_sampling)
    end
    tmp_phy_bit_over_sampling1(i) = acc;
  end

  tmp = 0;
  sample = zeros(1, 2*num_sample);
  sample(1) = round( cos(tmp)*AMPLITUDE );
  sample(2) = round( sin(tmp)*AMPLITUDE );
  for i=2:num_sample
    tmp = tmp + (pi*MOD_IDX)*tmp_phy_bit_over_sampling1(i-1)/(SAMPLE_PER_SYMBOL);
    sample((i-1)*2 + 1) = round( cos(tmp)*AMPLITUDE );
    sample((i-1)*2 + 2) = round( sin(tmp)*AMPLITUDE );
  end

% -------------------------------------------------- fixed point ------------- -----------------------------------------------
tmp_phy_bit_over_sampling_int16 = int16(tmp_phy_bit_over_sampling);
tmp_phy_bit_over_sampling1_int16 = int16(tmp_phy_bit_over_sampling1);
gauss_coef_scale = 128;
cos_table_size = 1024; % 0 to 2PI
gauss_coef_int16 = int16(gauss_coef.*gauss_coef_scale);

  cos_table_int8 = int8(zeros(1, cos_table_size));
  sin_table_int8 = int8(zeros(1, cos_table_size));
  for i=1:cos_table_size
    cos_table_int8(i) = int8(cos(2*pi*(i-1)/cos_table_size)*127);
    sin_table_int8(i) = int8(sin(2*pi*(i-1)/cos_table_size)*127);
  end
  
  save_int_var_for_c(gauss_coef_int16./2, 'const int8_t const gauss_coef_int8', 'gauss_cos_sin_table.h', 'w');
  save_int_var_for_c(cos_table_int8, 'const int8_t const cos_table_int8', 'gauss_cos_sin_table.h', 'a');
  save_int_var_for_c(sin_table_int8, 'const int8_t const sin_table_int8', 'gauss_cos_sin_table.h', 'a');
  
  for i = 1 : len_conv_result
    acc_int16 = int16(0);
    for j = 1 : len_gauss_oversample
      acc_int16 = acc_int16 + gauss_coef_int16(len_gauss_oversample-j+1)*tmp_phy_bit_over_sampling_int16(i+j-1); 
    end
    tmp_phy_bit_over_sampling1_int16(i) = acc_int16;
  end
  
%figure; 
%subplot(2,1,1); plot(tmp_phy_bit_over_sampling1_int16); hold on;
%plot(tmp_phy_bit_over_sampling1.*128, 'r.');
%subplot(2,1,2); plot(abs(double(tmp_phy_bit_over_sampling1_int16)-tmp_phy_bit_over_sampling1.*128));

phase_per_step = 2*pi/cos_table_size;
phase_delta_orig = ((pi*MOD_IDX)/SAMPLE_PER_SYMBOL)/gauss_coef_scale;
enlarge_scale = phase_per_step/phase_delta_orig
if enlarge_scale <1
  tmp_phy_bit_over_sampling1_int16 = tmp_phy_bit_over_sampling1_int16.*int16(1/enlarge_scale);
else
  tmp_phy_bit_over_sampling1_int16 = tmp_phy_bit_over_sampling1_int16./int16(enlarge_scale);
end

  tmp_int16 = int16(0);
  sample_int16 = int8(zeros(1, 2*num_sample));
  sample_int16(1) = cos_table_int8(tmp_int16+1);
  sample_int16(2) = sin_table_int8(tmp_int16+1);
  for i=2:num_sample
    tmp_int16 = tmp_int16 + tmp_phy_bit_over_sampling1_int16(i-1);
    tmp_int16 = mod(tmp_int16, int16(cos_table_size));
    sample_int16((i-1)*2 + 1) = cos_table_int8(tmp_int16+1);
    sample_int16((i-1)*2 + 2) = sin_table_int8(tmp_int16+1);
  end

figure(1);
subplot(2,1,1); plot(sample_int16);
ref_sample = get_number1;
%ref_sample = sample;
hold on; plot(ref_sample, 'r.');
subplot(2,1,2); plot((double(sample_int16)-ref_sample));