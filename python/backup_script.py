# Author: Xianjun Jiao <putaoshu@msn.com>
# SPDX-FileCopyrightText: 2024 Xianjun Jiao
# SPDX-License-Identifier: Apache-2.0 license

import numpy as np
import matplotlib
matplotlib.use('TkAgg')
import matplotlib.pyplot as plt

import btlelib as bl

# # # --------------------test receiver-----------------------------
channel_number = 37
crc_state_init_bit = []

# pdu_bit_in_hex = '422506050403020119095344522f426c7565746f6f74682f4c6f772f456e657267791234567890' # ADV payload length 37. pdu len = 37+2=39 (maximum)
# pdu_bit_in_hex = '422006050403020119095344522f426c7565746f6f74682f4c6f772f456e65726779' # ADV payload length 32. pdu bits. no need to put preamble 'aa' and access address 'd6be898e'
pdu_bit_in_hex = '421f06050403020118095344522f426c7565746f6f74682f4c6f772f456e657267' # ADV payload length 31
# pdu_bit_in_hex = '42210605040302011a095344522f426c7565746f6f74682f4c6f772f456e6572676572' # ADV payload length 33
# pdu_bit_in_hex = '421806050403020111095344522f426c7565746f6f74682f4c6f' # ADV payload length 24
# pdu_bit_in_hex = '420a06050403020103095344' # ADV payload length 10
# pdu_bit_in_hex = '42200605'

# channel_number = 9
# crc_state_init_bit = bl.hex_string_to_bit('A77B22')
# pdu_bit_in_hex = '0100323a13' # DATA payload length 0 -- channel 9

# print(pdu_bit_in_hex)

bl.SAMPLE_PER_SYMBOL = 4

ppm_value = -20
snr = 12
num_pkt_total = 0
num_pkt_err = 0
num_bit_total = 0
num_bit_err = 0

for idx in range(1):
  pdu_bit = bl.hex_string_to_bit(pdu_bit_in_hex)
  pdu_bit[16:] = np.int8(np.random.randint(2, size=len(pdu_bit)-16)) # generate random payload
  btle_rx_core_test_output_octet_ref_at_tx_fd = open('../verilog/btle_rx_core_test_output_octet_ref_at_tx.txt', 'w')
  btle_rx_core_test_output_octet_ref_at_tx_fd.write(bl.bit_to_hex_string(pdu_bit[16:]))
  btle_rx_core_test_output_octet_ref_at_tx_fd.close
  # print(pdu_bit[16:])
  # btle_tx_test_input_octet_ref_fd = open('../verilog/btle_tx_test_input_octet_string_ref.txt', 'w')
  # btle_tx_test_input_octet_ref_fd.write(bl.bit_to_hex_string(pdu_bit))
  # btle_tx_test_input_octet_ref_fd.close
  bl.bit_to_txt_octet_per_line(pdu_bit, '../verilog/btle_tx_test_input.txt')
  tx_i, tx_q, phy_bit, phy_bit_upsample = bl.btle_tx(pdu_bit, channel_number, crc_state_init_bit)
  np.savetxt('../verilog/btle_tx_test_output_i_ref.txt', tx_i, fmt='%d')
  np.savetxt('../verilog/btle_tx_test_output_q_ref.txt', tx_q, fmt='%d')
  print('len pdu_bit ', len(pdu_bit), ' len phy_bit ', len(phy_bit), ' len sample ', len(tx_i))

  tx_i_error, tx_q_error, _ = bl.add_freq_sampling_error(tx_i, tx_q, ppm_value)
  # plt.plot(np.angle(freq_shift_vec))
  # plt.plot(tx_i)
  # plt.plot(tx_i_error)
  # plt.show()

  rx_i, rx_q = bl.add_noise(tx_i_error, tx_q_error, snr)

  rx_pdu_bit, crc_ok, num_byte_payload, _, bit_all_sample_phase, signal_for_decision = bl.btle_rx(rx_i, rx_q, channel_number, crc_state_init_bit)
  btle_rx_core_test_output_octet_ref_fd = open('../verilog/btle_rx_core_test_output_octet_ref.txt', 'w')
  btle_rx_core_test_output_octet_ref_fd.write(bl.bit_to_hex_string(rx_pdu_bit[16:]))
  btle_rx_core_test_output_octet_ref_fd.close

  btle_rx_test_output_octet_ref_fd = open('../verilog/btle_rx_test_output_octet_ref.txt', 'w')
  btle_rx_test_output_octet_ref_fd.write(bl.bit_to_hex_string(rx_pdu_bit))
  btle_rx_test_output_octet_ref_fd.close

  num_pkt_total = num_pkt_total + 1
  num_bit_total = num_bit_total + len(pdu_bit)

  if not crc_ok:
    num_pkt_err = num_pkt_err + 1
    if len(rx_pdu_bit) == 0:
      num_bit_err = num_bit_err + len(pdu_bit)
    else:
      min_len = min(len(pdu_bit), len(rx_pdu_bit))
      num_bit_err = num_bit_err + np.sum(pdu_bit[0:min_len] != rx_pdu_bit[0:min_len])
      # if len(pdu_bit) != len(rx_pdu_bit):
      #   print('tx ', len(pdu_bit), 'bit rx ', len(rx_pdu_bit), 'bit')
      #   print(num_byte_payload)

ber = num_bit_err/num_bit_total
print('ber ', ber, ' num_bit_total ', num_bit_total, ' num_bit_err ', num_bit_err)
per = num_pkt_err/num_pkt_total
print('per ', per, ' num_pkt_total ', num_pkt_total, ' num_pkt_err ', num_pkt_err)

print(bl.vco_fixed_point.table_size)
print('bl.SAMPLE_PER_SYMBOL ', bl.SAMPLE_PER_SYMBOL)
bl.tmp_test(1)

# #---------------plot-------------------
plt.figure(0)
fo, _ = bl.check_realtime_fo(tx_i, tx_q)
ax = plt.subplot(211)
ax.plot(fo, 'b')
ax.plot(np.concatenate((np.zeros(6, dtype=np.int8), phy_bit_upsample))/4, 'r')
ax.grid(True)
ax.set_title('Tx phy_bit VS freq offset at rx (no noise)')
rx_fo, _ = bl.check_realtime_fo(rx_i, rx_q)
ax = plt.subplot(212)
ax.plot(rx_fo, 'b')
ax.plot(np.concatenate((np.zeros(6, dtype=np.int8), phy_bit_upsample))/4, 'r')
ax.grid(True)
ax.set_title('Tx phy_bit VS freq offset at rx (has noise)')

plt.figure(1)
for idx in range(8):
  ax = plt.subplot(4,2,idx+1)
  ax.plot(phy_bit, 'b')
  offset = 0
  if idx < 4:
    offset = 1
  ax.plot(bit_all_sample_phase[idx,offset:], 'r.')
  ax.grid(True)
  ax.set_title('phase'+str(idx))
plt.suptitle('Tx phy_bit VS rx decision')

plt.figure(2)
for idx in range(8):
  ax = plt.subplot(4,2,idx+1)
  ax.plot((phy_bit*2-1)*127*127.0, 'b')
  offset = 0
  if idx < 4:
    offset = 1
  ax.plot(signal_for_decision[idx,offset:], 'r.')
  ax.grid(True)
  ax.set_title('phase'+str(idx))
plt.suptitle('Tx phy_bit VS signal_for_decision')
# # ------------------------------------------------

# print(bl.vco_fixed_point.table_size)
# plt.figure(1)
# plt.plot(bl.vco_fixed_point.cos_table, 'r+')
# plt.plot(bl.vco_fixed_point.sin_table, 'r+')
# plt.grid()
# np.savetxt('tx_i.txt', tx_i, fmt='%d')
# np.savetxt('tx_q.txt', tx_q, fmt='%d')
# np.savetxt('tx_power.txt', np.double(tx_i)*np.double(tx_i)+np.double(tx_q)*np.double(tx_q), fmt='%f')

plt.show()

# b = bl.tmp_test(1)
# print(b)
# bl.tmp_test.sample_per_symbol = bl.tmp_test.sample_per_symbol + 1
# b = bl.tmp_test(1)
# print(b)

# # # -------------------test full transmitter--------------------
# pdu_bit_in_hex = '422006050403020119095344522f426c7565746f6f74682f4c6f772f456e65726779' # pdu bits. no need to put preamble 'aa' and access address 'd6be898e'
# python_i, python_q = bl.btle_tx(bl.hex_string_to_bit(pdu_bit_in_hex))
# btle_tx_sample = np.loadtxt('/home/xjiao/git/BTLE/host/build/phy_sample.txt', dtype=np.int8)
# btle_cos_out = btle_tx_sample[0::2]
# btle_sin_out = btle_tx_sample[1::2]
# btle_tx_iq = btle_tx_sample[0::2] + 1j*btle_tx_sample[1::2]
# btle_fo, _ = bl.check_realtime_fo(btle_cos_out, btle_sin_out)
# python_fo, _ = bl.check_realtime_fo(python_i, python_q)

# plt.figure(0)
# plt.plot(btle_fo[3:], 'b')
# plt.plot(python_fo, 'r')
# plt.show()

# # # -------------test bit level processing--------------------
# channel_number = 37
# pdu_bit_in_hex = 'aad6be898e422006050403020119095344522f426c7565746f6f74682f4c6f772f456e65726779'
# # pdu_bit_in_hex = 'aad6be898e'
# info_bit = bl.hex_string_to_bit(pdu_bit_in_hex)
# print(pdu_bit_in_hex)
# hex_string = bl.bit_to_hex_string(info_bit)
# print(hex_string)

# info_bit_after_crc24 = bl.crc24(info_bit, bl.hex_string_to_bit('555555'))
# print(bl.bit_to_hex_string(info_bit_after_crc24))

# phy_bit = bl.scramble(info_bit_after_crc24, channel_number)
# print(bl.bit_to_hex_string(phy_bit))

# btle_tx_sample = np.loadtxt('/home/xjiao/git/BTLE/host/build/phy_sample.txt', dtype=np.int8)
# # print(btle_tx_sample[0:24])
# btle_cos_out = btle_tx_sample[0::2]
# btle_sin_out = btle_tx_sample[1::2]
# btle_tx_sample_complex = btle_tx_sample[0::2] + 1j*btle_tx_sample[1::2]
# print(btle_cos_out.shape)
# print(btle_sin_out.dtype)

# # phy_bit = np.array([0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1])
# bit_upsample_fixed_point, bit_upsample_guass_filter_fixed_point, cos_out_fixed_point, sin_out_fixed_point = bl.gfsk_modulation_fixed_point(phy_bit)
# python_tx_sample_complex = cos_out_fixed_point + 1j*sin_out_fixed_point
# print(cos_out_fixed_point.shape)
# print(cos_out_fixed_point.dtype)

# btle_fo, btle_phase = bl.check_realtime_fo(btle_cos_out, btle_sin_out)
# python_fo, python_phase = bl.check_realtime_fo(cos_out_fixed_point, sin_out_fixed_point)
# # print(btle_fo.shape)
# # plt.plot(btle_fo, 'b')

# plt.figure(0)
# plt.plot(btle_fo[3:], 'b')
# plt.plot(python_fo, 'r')
# # plt.plot(np.angle(btle_tx_sample_complex[3:]), 'b')
# # plt.plot(np.angle(python_tx_sample_complex[0::2]), 'r')
# # plt.figure(1)
# # plt.plot(btle_tx_sample[6::2], 'b')
# # plt.plot(cos_out_fixed_point[0::2], 'r')

# plt.show()

# # ax = plt.subplot(211)
# # ax.plot(cos_out*127, 'b-')
# # ax.plot(cos_out_fixed_point, 'r+')
# # ax.grid(True)
# # ax.set_title('cos_out')

# # ax = plt.subplot(212)
# # ax.plot(sin_out*127, 'b-')
# # ax.plot(sin_out_fixed_point, 'r+')
# # ax.grid(True)
# # ax.set_title('sin_out')

# # # -------------test GFSK modulation-------------------------
# # bit = np.array([1, 0, 1, 0, 1, 0, 1, 0, 1, 0])
# bit = np.array([0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1])
# bit_upsample, bit_upsample_guass_filter, cos_out, sin_out = bl.gfsk_modulation(bit)
# bit_upsample_fixed_point, bit_upsample_guass_filter_fixed_point, cos_out_fixed_point, sin_out_fixed_point = bl.gfsk_modulation_fixed_point(bit)

# print(bl.vco_fixed_point.table_size)
# # print(bl.vco_fixed_point.cos_table)
# np.savetxt('./cos_table.txt', bl.vco_fixed_point.cos_table, delimiter=',', fmt='%d')
# np.savetxt('./sin_table.txt', bl.vco_fixed_point.sin_table, delimiter=',', fmt='%d')

# plt.figure(0)
# plt.title('bit_upsample')
# plt.plot(bit_upsample, 'b')
# plt.plot(bit_upsample_fixed_point, 'r+')
# plt.grid()

# plt.figure(1)
# plt.title('bit_upsample_guass_filter')
# # print(bl.gfsk_modulation_fixed_point.gauss_fir_scale_up_factor)
# plt.plot(bit_upsample_guass_filter*bl.gfsk_modulation_fixed_point.vco_input_gain, 'b+-')
# plt.plot(bit_upsample_guass_filter_fixed_point, 'r+')
# plt.grid()

# plt.figure(2)
# ax = plt.subplot(211)
# ax.plot(cos_out*127, 'b-')
# ax.plot(cos_out_fixed_point, 'r+')
# ax.grid(True)
# ax.set_title('cos_out')

# ax = plt.subplot(212)
# ax.plot(sin_out*127, 'b-')
# ax.plot(sin_out_fixed_point, 'r+')
# ax.grid(True)
# ax.set_title('sin_out')

# realtime_fo, realtime_phase = bl.check_realtime_fo(cos_out, sin_out)
# realtime_fo_fixed_point, realtime_phase_fixed_point = bl.check_realtime_fo(cos_out_fixed_point, sin_out_fixed_point)
# print(cos_out_fixed_point.shape)
# print(cos_out_fixed_point.dtype)
# plt.figure(3)
# ax = plt.subplot(211)
# ax.plot(realtime_fo, 'b-')
# ax.plot(realtime_fo_fixed_point, 'r+')
# ax.grid(True)
# ax.set_title('realtime_fo')
# np.savetxt('./realtime_fo.txt', realtime_fo_fixed_point, delimiter=',', fmt='%f')

# ax = plt.subplot(212)
# ax.plot(realtime_phase, 'b-')
# ax.plot(realtime_phase_fixed_point, 'r+')
# ax.grid(True)
# ax.set_title('realtime_phase')

# plt.figure(4)
# plt.title('gauss_fir')
# plt.plot(bl.gfsk_modulation.gauss_fir*bl.gfsk_modulation_fixed_point.gauss_fir_tap_amp_scale_up_factor, 'b-')
# plt.plot(bl.gfsk_modulation_fixed_point.gauss_fir, 'r+')
# plt.grid()
# plt.show()
# # print(bit_upsample)
