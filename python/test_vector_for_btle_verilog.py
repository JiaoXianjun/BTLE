import numpy as np
import matplotlib
matplotlib.use('TkAgg')
import matplotlib.pyplot as plt

import btlelib as bl

import sys

# #############################test vector generation method###########################################
# Create btle_tx program by following https://github.com/JiaoXianjun/BTLE (sdr hardware is NOT needed!)
# Run the example in README (An advertisement packet in channel 37):
# # cd BTLE/host/build
# # ./btle-tools/src/btle_tx 37-DISCOVERY-TxAdd-1-RxAdd-0-AdvA-010203040506-LOCAL_NAME09-SDR/Bluetooth/Low/Energy r500
# The pdu input to PHY is printed by btle_tx as:
# # ...
# # before crc24, pdu
# # 422006050403020119095344522f426c7565746f6f74682f4c6f772f456e65726779
# # ...
# From the above btle_tx config and output, we can set
# channel_number = 37
# crc_state_init_bit = []
# pdu_bit_in_hex = '422006050403020119095344522f426c7565746f6f74682f4c6f772f456e65726779'
# The btle_tx output IQ sample are in phy_sample.txt which will be compared with our python transmitter in btlelib.py

if __name__ == "__main__":
  example_idx = 0
  snr = 20
  ppm_value = 0
  num_sample_delay = 0 # change this to >8 to see different starting idx in search_unique_bit_sequence_tb

  print('arguments: example_idx snr ppm_value num_sample_delay')

  if len(sys.argv) == 2:
    example_idx = int(sys.argv[1])
  elif len(sys.argv) == 3:
    example_idx = int(sys.argv[1])
    snr = float(sys.argv[2])
  elif len(sys.argv) == 4:
    example_idx = int(sys.argv[1])
    snr = float(sys.argv[2])
    ppm_value = float(sys.argv[3])
  elif len(sys.argv) == 5:
    example_idx = int(sys.argv[1])
    snr = float(sys.argv[2])
    ppm_value = float(sys.argv[3])
    num_sample_delay = int(sys.argv[4])

  print([example_idx, snr, ppm_value, num_sample_delay])

  if example_idx == 0:
    # ######################################### example 1 by: ##########################################
    print('btle_tx command for current example:')
    print('../host/build/btle-tools/src/btle_tx 37-DISCOVERY-TxAdd-1-RxAdd-0-AdvA-010203040506-LOCAL_NAME09-SDR/Bluetooth/Low/Energy r500')
    channel_number = 37 # from the 1st field in above btle_tx command argument
    access_address = 'D6BE898E' # for advertisement channel, 0x8E89BED6 in standard. due to byte order here needs to be D6BE898E
    crc_state_init_hex = '555555' # will use default advertisement channel crc init value
    crc_state_init_bit = bl.hex_string_to_bit(crc_state_init_hex) 
    pdu_bit_in_hex = '422006050403020119095344522f426c7565746f6f74682f4c6f772f456e65726779'
  elif example_idx == 1:
    # ######################################### example 2 by: ##########################################
    print('btle_tx command for current example:')
    print('../host/build/btle-tools/src/btle_tx 9-LL_CONNECTION_UPDATE_REQ-AA-60850A1B-LLID-3-NESN-0-SN-0-MD-0-WinSize-02-WinOffset-0e0F-Interval-0450-Latency-0607-Timeout-07D0-Instant-eeff-CRCInit-A77B22')
    channel_number = 9 # from the 1st field in above btle_tx command argument
    access_address = '1B0A8560' # due to byte order, the 60850A1B in above argument needs to be 1B0A8560
    crc_state_init_hex = 'A77B22' # from the CRCInit field in above btle_tx command argument
    crc_state_init_bit = bl.hex_string_to_bit(crc_state_init_hex)
    pdu_bit_in_hex = '030c00020f0e50040706d007ffee' # from the output of above btle_tx command
  elif example_idx == 2:
    # ######################################### example 2 by: ##########################################
    print('btle_tx command for current example:')
    print('../host/build/btle-tools/src/btle_tx 10-LL_DATA-AA-11850A1B-LLID-1-NESN-0-SN-0-MD-0-DATA-XX-CRCInit-123456')
    channel_number = 10 # from the 1st field in above btle_tx command argument
    access_address = '1B0A8511' # due to byte order, the 11850A1B in above argument needs to be 1B0A8511
    crc_state_init_hex = '123456' # from the CRCInit field in above btle_tx command argument
    crc_state_init_bit = bl.hex_string_to_bit(crc_state_init_hex)
    pdu_bit_in_hex = '0100' # from the output of above btle_tx command
  else:
    print('the argument example_idx needs to be 0, 1 or 2!')
    exit()

  print('config')
  print('channel_number ', channel_number)
  print('access_address ', access_address)
  print('crc_state_init_hex ', crc_state_init_hex)
  print('')

  # start generate test vector for verilog
  bl.SAVE_FOR_VERILOG = 1
  bl.SAVE_DIR = '../verilog/'

  pdu_bit = bl.hex_string_to_bit(pdu_bit_in_hex)
  # pdu_bit[16:] = np.int8(np.random.randint(2, size=len(pdu_bit)-16)) # generate random payload

  # save the meta config to config.txt
  btle_config_fd = open(bl.SAVE_DIR+'/btle_config.txt', 'w')
  btle_config_fd.write(format(len(pdu_bit), 'x')+'\n')
  btle_config_fd.write(format(channel_number, 'x')+'\n')
  btle_config_fd.write(crc_state_init_hex+'\n')
  btle_config_fd.write(access_address+'\n')
  btle_config_fd.close

  print('btle_tx')

  # save pdu_bit as btle_tx verilog input
  bl.bit_to_txt_octet_per_line(pdu_bit, bl.SAVE_DIR+'/btle_tx_test_input.txt')

  # generate tx packet iq sample
  tx_i, tx_q, phy_bit, phy_bit_upsample = bl.btle_tx(pdu_bit, channel_number, crc_state_init_bit, access_address)

  # save iq sample for btle_tx verilog output comparison
  np.savetxt(bl.SAVE_DIR+'/btle_tx_test_output_i_ref.txt', tx_i, fmt='%d')
  np.savetxt(bl.SAVE_DIR+'/btle_tx_test_output_q_ref.txt', tx_q, fmt='%d')

  # print the bit level processing in transmitter. they are aligned with btle_tx C SDR program
  print('before crc24, pdu')
  print(bl.bit_to_hex_string(pdu_bit))
  print('after crc24, pdu+crc')
  btle_tx_crc24_test_output_ref = np.loadtxt(bl.SAVE_DIR+'/btle_tx_crc24_test_output_ref.txt', dtype=int)
  print(bl.bit_to_hex_string(btle_tx_crc24_test_output_ref[40:]))
  print('after scramble, pdu+crc')
  btle_tx_scramble_test_output_ref = np.loadtxt(bl.SAVE_DIR+'/btle_tx_scramble_test_output_ref.txt', dtype=int)
  print(bl.bit_to_hex_string(btle_tx_scramble_test_output_ref[40:]))
  print('')

  # plot signal level processing in transmitter.
  plt.figure(0)
  ax = plt.subplot(211)
  ax.plot(phy_bit_upsample, 'b', label='Upsampled phy bit')
  btle_tx_vco_test_input = np.loadtxt(bl.SAVE_DIR+'/btle_tx_vco_test_input.txt', dtype=int)
  ax.plot(btle_tx_vco_test_input[8:]/64.0, 'r', label='Guass filter out')
  fo, _ = bl.check_realtime_fo(tx_i, tx_q)
  ax.plot(fo[6:], 'k--', label='Normalized freq offset')
  ax.legend(loc='upper right')
  ax.grid(True)
  ax.set_title('Signals in BTLE transmitter')

  ax = plt.subplot(212)
  ax.plot(tx_i[8:], 'b', label='I')
  ax.plot(tx_q[8:], 'r', label='Q')
  ax.legend(loc='upper right')
  ax.grid(True)
  ax.set_title('BTLE transmitter I and Q')

  # add extra delay by number of sample:
  tx_i = np.concatenate((np.zeros(num_sample_delay, dtype=np.int8), tx_i))
  tx_q = np.concatenate((np.zeros(num_sample_delay, dtype=np.int8), tx_q))

  # add sampling frequency offset, carrier frequency offset
  tx_i_error, tx_q_error, _, fo = bl.add_freq_sampling_error(tx_i, tx_q, ppm_value)

  # add AWGN noise
  rx_i, rx_q = bl.add_noise(tx_i_error, tx_q_error, snr)

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

  print('snr ', snr, 'dB ppm ', ppm_value, ' freq offset ', fo, 'Hz num of pdu bit (no header and crc) ', len(pdu_bit)-16)
  print('crc ok ', crc_ok, ' num_byte_payload ', num_byte_payload, ' best_sample_phase_idx ', best_sample_phase_idx)

  # plot signal level processing in receiver.
  plt.figure(1)
  ax = plt.subplot(211)
  ax.plot(phy_bit_upsample, 'b', label='Upsampled phy bit')
  btle_tx_vco_test_input = np.loadtxt(bl.SAVE_DIR+'/btle_tx_vco_test_input.txt', dtype=int)
  ax.plot(btle_tx_vco_test_input[8:]/64.0, 'r', label='Guass filter out')
  fo, _ = bl.check_realtime_fo(tx_i, tx_q)
  ax.plot(fo[6:], 'k--', label='Normalized freq offset')
  ax.legend(loc='upper right')
  ax.grid(True)
  ax.set_title('Signals in BTLE transmitter')

  ax = plt.subplot(212)
  # mimic signal_for_decision signal in receiver
  i = np.int16(rx_i)
  q = np.int16(rx_q)
  signal_for_decision = np.zeros((round(len(i)/bl.SAMPLE_PER_SYMBOL)-1)*bl.SAMPLE_PER_SYMBOL, dtype=np.int32)
  signal_for_decision_idx = np.linspace(0, len(signal_for_decision)-1,  len(signal_for_decision))
  for sample_phase_idx in range(bl.SAMPLE_PER_SYMBOL):
    _, signal_for_decision[sample_phase_idx::bl.SAMPLE_PER_SYMBOL] = bl.gfsk_demodulation_fixed_point(i[sample_phase_idx::bl.SAMPLE_PER_SYMBOL], q[sample_phase_idx::bl.SAMPLE_PER_SYMBOL])
  
  ax.plot(signal_for_decision_idx, signal_for_decision, 'b', label='signal for decision')
  ax.plot(signal_for_decision_idx[best_sample_phase_idx::bl.SAMPLE_PER_SYMBOL], signal_for_decision[best_sample_phase_idx::bl.SAMPLE_PER_SYMBOL], 'rs', label='best phase moment')
  ax.legend(loc='upper right')
  ax.grid(True)
  ax.set_title('signal for decision in receiver')

  plt.show()
  
