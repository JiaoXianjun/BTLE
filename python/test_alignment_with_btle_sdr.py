# Author: Xianjun Jiao <putaoshu@msn.com>
# SPDX-FileCopyrightText: 2024 Xianjun Jiao
# SPDX-License-Identifier: Apache-2.0 license

import numpy as np
# import matplotlib
# matplotlib.use('TkAgg')
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

# def test_alignment_with_btle_sdr(argv):
if __name__ == "__main__":
  if len(sys.argv) == 1:
    example_idx = 0
  else:
    example_idx = int(sys.argv[1])
  
  print('argument: example_idx')
  print(example_idx)

  if example_idx == 0:
    # ######################################### example 1 by: ##########################################
    print('Plese run firstly:')
    print('../host/build/btle-tools/src/btle_tx 37-DISCOVERY-TxAdd-1-RxAdd-0-AdvA-010203040506-LOCAL_NAME09-SDR/Bluetooth/Low/Energy r500')
    channel_number = 37 # from the 1st field in above btle_tx command argument
    access_address = [] # will use default advertisement channel access address 0x8E89BED6
    crc_state_init_bit = [] # will use default advertisement channel crc init value
    pdu_bit_in_hex = '422006050403020119095344522f426c7565746f6f74682f4c6f772f456e65726779'
  elif example_idx == 1:
    # ######################################### example 2 by: ##########################################
    print('Plese run firstly:')
    print('../host/build/btle-tools/src/btle_tx 9-LL_CONNECTION_UPDATE_REQ-AA-60850A1B-LLID-3-NESN-0-SN-0-MD-0-WinSize-02-WinOffset-0e0F-Interval-0450-Latency-0607-Timeout-07D0-Instant-eeff-CRCInit-A77B22')
    channel_number = 9 # from the 1st field in above btle_tx command argument
    access_address = '1B0A8560' # due to byte order, the 60850A1B in above argument needs to be 1B0A8560
    crc_state_init_hex = 'A77B22' # from the CRCInit field in above btle_tx command argument
    crc_state_init_bit = bl.hex_string_to_bit(crc_state_init_hex) # from the CRCInit field in above btle_tx command argument
    pdu_bit_in_hex = '030c00020f0e50040706d007ffee' # from the output of above btle_tx command
  elif example_idx == 2:
    # ######################################### example 2 by: ##########################################
    print('Plese run firstly:')
    print('../host/build/btle-tools/src/btle_tx 10-LL_DATA-AA-11850A1B-LLID-1-NESN-0-SN-0-MD-0-DATA-XX-CRCInit-123456')
    channel_number = 10 # from the 1st field in above btle_tx command argument
    access_address = '1B0A8511' # due to byte order, the 11850A1B in above argument needs to be 1B0A8511
    crc_state_init_hex = '123456' # from the CRCInit field in above btle_tx command argument
    crc_state_init_bit = bl.hex_string_to_bit(crc_state_init_hex) # from the CRCInit field in above btle_tx command argument
    pdu_bit_in_hex = '0100' # from the output of above btle_tx command
  else:
    print('the argument example_idx needs to be 0, 1 or 2!')
    exit()

  # Start check alignment
  pdu_bit = bl.hex_string_to_bit(pdu_bit_in_hex)
  python_i, python_q, phy_bit, phy_bit_upsample = bl.btle_tx(pdu_bit, channel_number, crc_state_init_bit, access_address)

  btle_tx_sample = np.loadtxt('phy_sample.txt', dtype=np.int8)
  btle_i = btle_tx_sample[0::2]
  btle_q = btle_tx_sample[1::2]

  btle_fo, _ = bl.check_realtime_fo(btle_i, btle_q, 4) # in btle_tx C program, 4x oversampling is used. the python use 8x by default
  python_fo, _ = bl.check_realtime_fo(python_i, python_q) # no input means 8x oversampling is assumed

  plt.figure(0)
  plt.plot(btle_fo[2:], 'b', label='sdr btle_tx')
  plt.plot(python_fo[0::2], 'r', label='python btlelib') # decimate to 4x oversampling
  plt.legend(loc="upper right")
  plt.title('btle_tx C sdr VS python btlelib. example '+str(example_idx))
  plt.xlabel('sample idx')
  plt.ylabel('freq offset (normalized)')
  plt.grid()
  plt.show()

  np.savetxt('btle_fo.txt', btle_fo, fmt='%f')
  np.savetxt('python_fo.txt', python_fo, fmt='%f')
