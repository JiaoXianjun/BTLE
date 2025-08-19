# Author: Xianjun Jiao <putaoshu@msn.com>
# SPDX-FileCopyrightText: 2024 Xianjun Jiao
# SPDX-License-Identifier: Apache-2.0 license

import numpy as np
# import matplotlib
# matplotlib.use('TkAgg')
import matplotlib.pyplot as plt

import btlelib as bl

import sys

if __name__ == "__main__":

  filename_csv = 'waveform.csv'
  channel_number = 37 # from the 1st field in above btle_tx command argument
  access_address = 'D6BE898E' # for advertisement channel, 0x8E89BED6 in standard. due to byte order here needs to be D6BE898E
  crc_state_init_hex = '555555' # will use default advertisement channel crc init value

  print('arguments: filename_csv channel_number access_address crc_state_init_hex')
  
  if len(sys.argv) == 2:
    filename_csv = sys.argv[1]
  elif len(sys.argv) == 3:
    filename_csv = sys.argv[1]
    channel_number = int(sys.argv[2])
  elif len(sys.argv) == 4:
    filename_csv = sys.argv[1]
    channel_number = int(sys.argv[2])
    access_address = sys.argv[3]
  elif len(sys.argv) == 5:
    filename_csv = sys.argv[1]
    channel_number = int(sys.argv[2])
    access_address = sys.argv[3]
    crc_state_init_hex = sys.argv[4]

  # start generate test vector for verilog
  bl.SAVE_FOR_VERILOG = 1
  bl.SAVE_DIR = '../verilog/'

  filename_txt = bl.SAVE_DIR+'captured_iq.txt'
  print([filename_csv, filename_txt])

  # channel_number = 9 # from the 1st field in above btle_tx command argument
  # access_address = '1B0A8560' # due to byte order, the 60850A1B in above argument needs to be 1B0A8560
  # crc_state_init_hex = 'A77B22' # from the CRCInit field in above btle_tx command argument
  # channel_number = 10 # from the 1st field in above btle_tx command argument
  # access_address = '1B0A8511' # due to byte order, the 11850A1B in above argument needs to be 1B0A8511
  # crc_state_init_hex = '123456' # from the CRCInit field in above btle_tx command argument

  crc_state_init_bit = bl.hex_string_to_bit(crc_state_init_hex)

  print('config')
  print('channel_number ', channel_number)
  print('access_address ', access_address)
  print('crc_state_init_hex ', crc_state_init_hex)
  print('')

  bl.extract_iq_from_csv_to_txt(filename_csv, filename_txt)

  rx_iq = np.loadtxt(bl.SAVE_DIR+'/'+filename_txt, dtype=int)
  # print(rx_i.shape)
  rx_i = rx_iq[::2, 0] # ::2 means take every second sample, because the FPGA ILA uses 16MHz but we need 8Msps
  rx_q = rx_iq[::2, 1]

  # plot the iq
  plt.figure(0)
  ax = plt.subplot(211)
  fo, _ = bl.check_realtime_fo(rx_i, rx_q)
  # ax.plot(fo, 'k--', label='Normalized freq offset')
  ax.plot(fo, 'k')
  # ax.legend(loc='upper right')
  ax.grid(True)
  ax.set_title('FPGA ILA IQ Normalized freq offset')

  ax = plt.subplot(212)
  ax.plot(rx_i, 'b', label='I')
  ax.plot(rx_q, 'r', label='Q')
  ax.legend(loc='upper right')
  ax.grid(True)
  ax.set_title('FPGA ILA IQ')
  plt.tight_layout()

  print('btle_rx')
  # save iq sample from channel for btle_rx verilog input
  np.savetxt(bl.SAVE_DIR+'/btle_rx_test_input_i.txt', np.int16(rx_i), fmt='%d')
  np.savetxt(bl.SAVE_DIR+'/btle_rx_test_input_q.txt', np.int16(rx_q), fmt='%d')

  # receiver decodes signal from channel
  rx_pdu_bit, crc_ok, num_byte_payload, rx_phy_bit, _, _, best_sample_phase_idx = bl.btle_rx(rx_i, rx_q, channel_number, crc_state_init_bit, access_address)

  # save crc_ok and demodulated octet for btle_rx verilog output comparison
  np.savetxt(bl.SAVE_DIR+'/btle_rx_test_output_crc_ok_ref.txt', [crc_ok], fmt='%d')
  bl.bit_to_txt_octet_per_line(rx_pdu_bit, bl.SAVE_DIR+'/btle_rx_test_output_ref.txt')

  print('rx phy bit')
  print(bl.bit_to_hex_string(rx_phy_bit[40:]))
  print('rx descramble, pdu')
  print(bl.bit_to_hex_string(rx_pdu_bit))

  # print('snr ', snr, 'dB ppm ', ppm_value, ' freq offset ', fo, 'Hz num of pdu bit (no header and crc) ', len(pdu_bit)-16)
  print('crc ok ', crc_ok, ' num_byte_payload ', num_byte_payload, ' best_sample_phase_idx ', best_sample_phase_idx)

  # plot signal level processing in receiver.
  plt.figure(1)
  ax = plt.subplot(211)
  fo, _ = bl.check_realtime_fo(rx_i, rx_q)
  # ax.plot(fo[6:], 'k--', label='Normalized freq offset')
  ax.plot(fo, 'k')
  # ax.legend(loc='upper right')
  ax.grid(True)
  ax.set_title('FPGA ILA IQ Normalized freq offset')

  ax = plt.subplot(212)
  # mimic signal_for_decision signal in receiver
  i = np.int16(rx_i)
  q = np.int16(rx_q)
  len_signal = round(len(i)/bl.SAMPLE_PER_SYMBOL)-1
  signal_for_decision = np.zeros(len_signal*bl.SAMPLE_PER_SYMBOL, dtype=np.int32)
  signal_for_decision_idx = np.linspace(0, len(signal_for_decision)-1,  len(signal_for_decision))
  for sample_phase_idx in range(bl.SAMPLE_PER_SYMBOL):
    _, signal_for_decision_tmp = bl.gfsk_demodulation_fixed_point(i[sample_phase_idx::bl.SAMPLE_PER_SYMBOL], q[sample_phase_idx::bl.SAMPLE_PER_SYMBOL])
    if len(signal_for_decision_tmp) < len_signal:
      signal_for_decision_tmp = np.concatenate((signal_for_decision_tmp, [signal_for_decision_tmp[-1]]*(len_signal - len(signal_for_decision_tmp))))
    else:
      signal_for_decision_tmp = signal_for_decision_tmp[0:len_signal]
    signal_for_decision[sample_phase_idx::bl.SAMPLE_PER_SYMBOL] = signal_for_decision_tmp
  
  idx_shift_left = 4
  ax.plot(signal_for_decision_idx - idx_shift_left, signal_for_decision, 'b', label='signal for decision')
  ax.plot(signal_for_decision_idx[best_sample_phase_idx::bl.SAMPLE_PER_SYMBOL] - idx_shift_left, signal_for_decision[best_sample_phase_idx::bl.SAMPLE_PER_SYMBOL], 'rs', label='best phase moment')
  ax.legend(loc='upper right')
  ax.grid(True)
  ax.set_title('Signal for decision in receiver')
  plt.tight_layout()

  np.savetxt('plot_signal_for_decision_x.txt', signal_for_decision_idx - idx_shift_left, fmt='%f')
  np.savetxt('plot_signal_for_decision_y.txt', signal_for_decision, fmt='%f')
  np.savetxt('plot_signal_for_decision_best_phase_x.txt', signal_for_decision_idx[best_sample_phase_idx::bl.SAMPLE_PER_SYMBOL] - idx_shift_left, fmt='%f')
  np.savetxt('plot_signal_for_decision_best_phase_y.txt', signal_for_decision[best_sample_phase_idx::bl.SAMPLE_PER_SYMBOL], fmt='%f')

  plt.show()
  