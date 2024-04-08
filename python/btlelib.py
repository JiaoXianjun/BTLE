# Author: Xianjun Jiao <putaoshu@msn.com>
# SPDX-FileCopyrightText: 2024 Xianjun Jiao
# SPDX-License-Identifier: Apache-2.0 license

import numpy as np
import os
# import matplotlib.pyplot as plt

SAVE_FOR_VERILOG = 0 # Change to 1 to save files for verilog test bench
SAVE_DIR = '' #The directory to store the test vector files

SAMPLE_PER_SYMBOL = 8
NUM_SYMBOL_GAUSS_FILTER_SPAN = 2
BT = 0.5
MODULATION_INDEX = 0.5

def gauss_fir_gen():
# reference: https://public.ccsds.org/Pubs/413x0g3e1.pdf page 3-2
  Ts = 1 # Normalized symbol time
  sigma = np.sqrt(np.log(2))/(2*np.pi*BT)
  t = np.arange(-(NUM_SYMBOL_GAUSS_FILTER_SPAN/2), (NUM_SYMBOL_GAUSS_FILTER_SPAN/2)+1/SAMPLE_PER_SYMBOL, 1/SAMPLE_PER_SYMBOL)
  h = np.exp(-t*t/(2*sigma*sigma*Ts*Ts))/(sigma*Ts*np.sqrt(2*np.pi))

  # Normalization: When +1/-1 NRZ filtered, the filter output max/min is also +1/-1
  h = h/SAMPLE_PER_SYMBOL

  return h

def sin_cos_gen(table_size_scale_up_factor):
# reference: https://community.silabs.com/s/article/calculation-of-the-modulation-index-for-digital-frequency-modulation?language=en_US
# freq_offset(freq deviation) = (MODULATION_INDEX/2)*symbol_rate, which means X period/circle per symbol X = freq_offset*symbol_time.
# X = (MODULATION_INDEX/2)*symbol_rate*symbol_time = (MODULATION_INDEX/2) period/circle per symbol.
# Then per sample it will be X/SAMPLE_PER_SYMBOL = (MODULATION_INDEX/2)/SAMPLE_PER_SYMBOL
# A full circle (2PI) will have SAMPLE_PER_SYMBOL/(MODULATION_INDEX/2) samples
# Above is the cos sin table size when the peak freq_offset is driven by lookup table address advancing by 1
# But actual address advancing will be driven by guassian filter output. It will have higher resolution.
# Assume the peak output of gaussian filter is table_size_scale_up_factor, then the table size will be:
# table_size_scale_up_factor*SAMPLE_PER_SYMBOL/(MODULATION_INDEX/2), which means each time when the lookup table
# address advancing by table_size_scale_up_factor (larger than 1), it will drive the cos sin table output freq_offset
  table_size = table_size_scale_up_factor*SAMPLE_PER_SYMBOL/(MODULATION_INDEX/2)
  table_address_array = 2*np.pi*np.arange(0, 1, 1/table_size)
  cos_table = np.int8(np.round(127*np.cos(table_address_array)))
  sin_table = np.int8(np.round(127*np.sin(table_address_array)))

  return cos_table, sin_table

def vco(voltage_signal):
# The max/min of voltage (gaussian filter output) is +1/-1, which generates max positive freq offset and negative freq offset
# reference: https://community.silabs.com/s/article/calculation-of-the-modulation-index-for-digital-frequency-modulation?language=en_US
# freq_offset(freq deviation) = (MODULATION_INDEX/2)*symbol_rate
# period/circle (normalized phase) per symbol = req_offset*symbol_time = (MODULATION_INDEX/2)
# period/circle (normalized phase) per sample = (MODULATION_INDEX/2)/SAMPLE_PER_SYMBOL
# So that, each sample of continuous peak voltage (+1 or -1) input should drive oscillator phase advancing (MODULATION_INDEX/2)/SAMPLE_PER_SYMBOL
  
  normalized_phase_advancing_per_sample = 2*np.pi*(MODULATION_INDEX/2)/SAMPLE_PER_SYMBOL
  integral_voltage_signal = np.cumsum(voltage_signal)

  cos_out = np.cos(integral_voltage_signal*normalized_phase_advancing_per_sample)
  sin_out = np.sin(integral_voltage_signal*normalized_phase_advancing_per_sample)

  return cos_out, sin_out

def vco_fixed_point(voltage_signal, vco_input_gain):
  if not hasattr(vco_fixed_point, "cos_table"):
    # Each cos&sin table address advancing by vco_input_gain (at sampling rate SAMPLE_PER_SYMBOL), it should generate phase advancing for max freq offset
    # Compare to the table address advancing by 1, the vco_input_gain actually is the table_size_scale_up_factor
    vco_fixed_point.cos_table, vco_fixed_point.sin_table = sin_cos_gen(vco_input_gain)
    vco_fixed_point.table_size = len(vco_fixed_point.cos_table)
    np.savetxt('../verilog/cos_table.txt', vco_fixed_point.cos_table, fmt='%d')
    np.savetxt('../verilog/sin_table.txt', vco_fixed_point.sin_table, fmt='%d')

  integral_voltage_signal = np.bitwise_and(np.cumsum(voltage_signal), np.int16(vco_fixed_point.table_size-1))

  cos_out = vco_fixed_point.cos_table[integral_voltage_signal]
  sin_out = vco_fixed_point.sin_table[integral_voltage_signal]

  # np.savetxt('voltage_signal.txt', voltage_signal, fmt='%d')
  # np.savetxt('integral_voltage_signal.txt', integral_voltage_signal, fmt='%d')

  return cos_out, sin_out

def check_realtime_fo(cos_in, sin_in, *argv):
  if len(argv) == 1: # sample_per_symbol input
    sample_per_symbol = argv[0]
  else:
    sample_per_symbol = SAMPLE_PER_SYMBOL

  # sample_per_symbol = SAMPLE_PER_SYMBOL

  iq_complex = np.double(cos_in) + 1j*np.double(sin_in)
  realtime_phase = np.angle(iq_complex)

  iq_complex_diff = iq_complex[2:len(iq_complex)]/iq_complex[1:(len(iq_complex)-1)]
  iq_complex_idff_angle = np.angle(iq_complex_diff)
  realtime_fo = sample_per_symbol*iq_complex_idff_angle/(2*np.pi)

  return realtime_fo, realtime_phase

def gfsk_modulation(bit):
  if not hasattr(gfsk_modulation, "gauss_fir"):
     gfsk_modulation.gauss_fir = gauss_fir_gen()

  num_bit = len(bit)
  bit = bit*2 - 1 # Convert 1/0 to +1/-1
  bit_upsample = np.zeros(num_bit*SAMPLE_PER_SYMBOL,)
  for i in range(SAMPLE_PER_SYMBOL): # Upsample/repeatition to NRZ waveform: +1/-1 to +1+1+1.../-1-1-1...
    bit_upsample[i::SAMPLE_PER_SYMBOL] = bit

  bit_upsample_guass_filter = np.convolve(bit_upsample, gfsk_modulation.gauss_fir) # gauss filter out: max +1/-1
  cos_out, sin_out = vco(bit_upsample_guass_filter) # cos and sin: max +1/-1

  return bit_upsample, bit_upsample_guass_filter, cos_out, sin_out

def gfsk_modulation_fixed_point(bit):
  if not hasattr(gfsk_modulation_fixed_point, "gauss_fir"):
     gfsk_modulation_fixed_point.gauss_fir = gauss_fir_gen() # While input +1+1+1.../-1-1-1... NRZ, filtered out put max positive/negative is also +1+1+1.../-1-1-1...

     # Scale gauss fir to let filtered output from +1+1+1.../-1-1-1... to +gauss_fir_tap_amp_scale_up_factor.../-gauss_fir_tap_amp_scale_up_factor...
     gfsk_modulation_fixed_point.gauss_fir_tap_amp_scale_up_factor = 128 # The higher, more precise
     gfsk_modulation_fixed_point.gauss_fir = np.int8(np.round(gfsk_modulation_fixed_point.gauss_fir_tap_amp_scale_up_factor*gfsk_modulation_fixed_point.gauss_fir))
     gfsk_modulation_fixed_point.gauss_fir_out_amp_scale_down_num_bit_shift = 1 # This compbined with tap_amp_scale_up to form the vco input gain (over +1/-1), which decide the cos&sin table size
     gfsk_modulation_fixed_point.vco_input_gain = np.right_shift(np.int16(gfsk_modulation_fixed_point.gauss_fir_tap_amp_scale_up_factor), gfsk_modulation_fixed_point.gauss_fir_out_amp_scale_down_num_bit_shift)
     np.savetxt('../verilog/gauss_filter_tap.txt', gfsk_modulation_fixed_point.gauss_fir, fmt='%d')

  num_bit = len(bit)
  bit = np.int8(bit)
  bit = bit*2 - 1 # Convert 1/0 to +1/-1

  bit_upsample = np.zeros(num_bit*SAMPLE_PER_SYMBOL, dtype=np.int8)
  for i in range(SAMPLE_PER_SYMBOL): # Upsample/repeatition to NRZ waveform: +1/-1 to +1+1+1.../-1-1-1...
    bit_upsample[i::SAMPLE_PER_SYMBOL] = bit

  if SAVE_FOR_VERILOG != 0:
    bit_upsample_for_verilog = (bit_upsample>0)
    np.savetxt(SAVE_DIR+'/btle_tx_gauss_filter_test_input.txt', bit_upsample_for_verilog, fmt='%d')

  bit_upsample = np.concatenate((-np.ones(len(gfsk_modulation_fixed_point.gauss_fir), dtype=np.int8), bit_upsample))
  bit_upsample_guass_filter = np.int16(np.convolve(np.int16(bit_upsample), np.int16(gfsk_modulation_fixed_point.gauss_fir))) # gauss filter out: max +gauss_fir_tap_amp_scale_up_factor/-gauss_fir_tap_amp_scale_up_factor
  
  bit_upsample_guass_filter = bit_upsample_guass_filter[len(gfsk_modulation_fixed_point.gauss_fir):]
  bit_upsample = bit_upsample[len(gfsk_modulation_fixed_point.gauss_fir):]
  
  if SAVE_FOR_VERILOG != 0:
    np.savetxt(SAVE_DIR+'/btle_tx_gauss_filter_test_output_ref.txt', bit_upsample_guass_filter, fmt='%d')

  bit_upsample_guass_filter = np.right_shift(bit_upsample_guass_filter, gfsk_modulation_fixed_point.gauss_fir_out_amp_scale_down_num_bit_shift)
  
  # print(num_bit)
  # print(len(bit_upsample_guass_filter))
  if SAVE_FOR_VERILOG != 0:
    np.savetxt(SAVE_DIR+'/btle_tx_vco_test_input.txt', bit_upsample_guass_filter, fmt='%d')
  cos_out, sin_out = vco_fixed_point(bit_upsample_guass_filter, gfsk_modulation_fixed_point.vco_input_gain) # cos and sin: scale to int8 +127+127+127.../-127-127-127...
  if SAVE_FOR_VERILOG != 0:
    np.savetxt(SAVE_DIR+'/btle_tx_vco_test_output_cos_ref.txt', cos_out, fmt='%d')
    np.savetxt(SAVE_DIR+'/btle_tx_vco_test_output_sin_ref.txt', sin_out, fmt='%d')

  return bit_upsample, bit_upsample_guass_filter, cos_out, sin_out

def crc24_core(bit_in, state_init_bit):
  bit_store = np.zeros(24, dtype=np.int8)
  bit_store = state_init_bit
  bit_store_update = np.zeros(24, dtype=np.int8)
  num_bit = len(bit_in)

  for i in range(num_bit):
    new_bit = np.bitwise_and(bit_store[23] + bit_in[i], 1)
    # print(bit_store, bit_in[i], new_bit)
    bit_store_update[0] = new_bit
    bit_store_update[1] = np.bitwise_and(bit_store[0] + new_bit, 1)
    bit_store_update[2] = bit_store[1]
    bit_store_update[3] = np.bitwise_and(bit_store[2] + new_bit, 1)
    bit_store_update[4] = np.bitwise_and(bit_store[3] + new_bit, 1)
    bit_store_update[5] = bit_store[4]
    bit_store_update[6] = np.bitwise_and(bit_store[5] + new_bit, 1)

    bit_store_update[7] = bit_store[6]
    bit_store_update[8] = bit_store[7]

    bit_store_update[9] = np.bitwise_and(bit_store[8] + new_bit, 1)
    bit_store_update[10] = np.bitwise_and(bit_store[9] + new_bit, 1)

    bit_store_update[11:(11+13)] = bit_store[10:(10+13)]

    bit_store = bit_store_update.copy()

  crc_result = bit_store[::-1]
  return crc_result

def crc24(bit_in, state_init_bit):
  crc24_bit = crc24_core(bit_in[40:], state_init_bit)
  bit_out = np.concatenate((bit_in, crc24_bit))
  return bit_out

def scramble_core(bit_in, channel_number):
  # print('channel_number ', channel_number, ' ', type(channel_number))
  bit_store = np.zeros(7, dtype=np.int8)
  bit_store_update = np.zeros(7, dtype=np.int8)

  bit_store[0] = np.int8(1)
  # bit_store[1] = np.bitwise_and(np.right_shift(np.int8(channel_number), 5), 1)
  # bit_store[2] = np.bitwise_and(np.right_shift(np.int8(channel_number), 4), 1)
  # bit_store[3] = np.bitwise_and(np.right_shift(np.int8(channel_number), 3), 1)
  # bit_store[4] = np.bitwise_and(np.right_shift(np.int8(channel_number), 2), 1)
  # bit_store[5] = np.bitwise_and(np.right_shift(np.int8(channel_number), 1), 1)
  # bit_store[6] = np.bitwise_and(np.right_shift(np.int8(channel_number), 0), 1)
  bit_store[1] = np.bitwise_and(np.right_shift(channel_number, 5), 1)
  bit_store[2] = np.bitwise_and(np.right_shift(channel_number, 4), 1)
  bit_store[3] = np.bitwise_and(np.right_shift(channel_number, 3), 1)
  bit_store[4] = np.bitwise_and(np.right_shift(channel_number, 2), 1)
  bit_store[5] = np.bitwise_and(np.right_shift(channel_number, 1), 1)
  bit_store[6] = np.bitwise_and(np.right_shift(channel_number, 0), 1)

  num_bit = len(bit_in)
  bit_out = np.zeros(num_bit, dtype=np.int8)
  for i in range(num_bit):
    bit_out[i] = np.bitwise_and(bit_store[6] + bit_in[i], 1)

    bit_store_update[0] = bit_store[6]

    bit_store_update[1] = bit_store[0]
    bit_store_update[2] = bit_store[1]
    bit_store_update[3] = bit_store[2]

    bit_store_update[4] = np.bitwise_and(bit_store[3] + bit_store[6], 1)

    bit_store_update[5] = bit_store[4]
    bit_store_update[6] = bit_store[5]

    bit_store = bit_store_update.copy()

  return bit_out

def scramble(bit_in, channel_number):
  bit_out = bit_in.copy()
  bit_out[40:] = scramble_core(bit_out[40:], channel_number)
  return bit_out

def hex_string_to_bit(hex_string):
  hex_array = list(hex_string)
  num_4bit = len(hex_array)

  if np.mod(num_4bit, 2) != 0:
    print('hex_string_to_bit: ERROR!')
    print('It has to contain complete bytes!')
    print('But seems there are extra 4bit!')
    return -1
  
  num_bit = num_4bit*4
  bit = np.zeros(num_bit, dtype=np.int8)

  for i in range(num_4bit):
    tmp_4bit = np.unpackbits(np.uint8(int(hex_array[i], 16)), bitorder='little')
    if np.mod(i, 2) == 0: ## due to BTLE bit order
      bit_index_offset = 4
    else:
      bit_index_offset = -4
    
    bit_start_idx = i*4 + bit_index_offset
    bit_end_idx = (i+1)*4 + bit_index_offset
    bit[bit_start_idx:bit_end_idx] = tmp_4bit[0:4]
  
  return bit

def bit_to_hex_string(bit):
  num_bit = len(bit)

  # if np.mod(num_bit, 8) != 0:
  #   print('bit_to_hex_string: ERROR!')
  #   print('It has to contain complete bytes!')
  #   print('But seems mod(num_bit, 8) is not 0!')
  #   return -1

  # # Zero padding to multiple of 8 bit
  num_pad = 8 - np.mod(num_bit, 8)
  if num_pad == 8:
    num_pad = 0
  # print(num_bit, num_pad)
  num_bit = num_bit + num_pad
  bit = np.append(bit, np.int8(np.zeros(num_pad,)))
  # print(num_bit, len(bit))
  
  num_4bit = int(num_bit/4)

  hex_array = [None]*num_4bit

  for i in range(num_4bit):
    if np.mod(i, 2) == 0: ## due to BTLE bit order
      bit_index_offset = 4
    else:
      bit_index_offset = -4
    
    bit_start_idx = i*4 + bit_index_offset
    bit_end_idx = (i+1)*4 + bit_index_offset
    tmp_4bit = bit[bit_start_idx:bit_end_idx]
    tmp_int = tmp_4bit[0] + tmp_4bit[1]*2 + tmp_4bit[2]*4 + tmp_4bit[3]*8
    hex_array[i] = format(tmp_int, 'x')
  
  hex_string = "".join(hex_array)

  return hex_string

def bit_to_txt_octet_per_line(bit, filename):
  a = bit_to_hex_string(bit)
  fd = open(filename, 'w')
  
  for i in range(0, len(a), 2):
    fd.write(a[i:(i+2)])
    fd.write('\n')

  fd.close

def btle_tx(pdu_bit, *argv): # 1st arg: pdu_bit. 2nd arg: channel_number (if present). 3rd arg: crc_state_init_bit (if present)
  preamble = 'aa' # for advertisement channel; for data channel it is decided by lsb of access address
  access_address = 'D6BE898E' # for advertisement channel, 0x8E89BED6 in standard. due to byte order here needs to be D6BE898E

  channel_number = 37 # Default broadcast channel number
  crc_state_init_bit = np.array([1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0], dtype=np.int8) # bl.hex_string_to_bit('555555')
  if len(argv) >= 1:
    channel_number = argv[0]
  if len(argv) >= 2:
    if len(argv[1]) == 24:
      crc_state_init_bit = argv[1]
    elif len(argv[1]) == 0:
      crc_state_init_bit = crc_state_init_bit
    else:
      print('btle_tx: The crc_state_init_bit argument needs to have exact 24 bits!')
      print('btle_tx: Ignore the input. Use ', crc_state_init_bit)
  if len(argv) >= 3:
    if len(argv[2]) == 8:
      access_address = argv[2]
    elif len(argv[2]) == 0:
      access_address = access_address
    else:
      print('btle_tx: The access_address argument needs to be hex string with length exact 8!')
      print('btle_tx: Ignore the input. Use ', access_address)

  if channel_number != 37 and channel_number != 38 and channel_number != 39: # data pdu
    tmp = hex_string_to_bit(access_address)
    if tmp[0] == 1:
      preamble = '55'
  else: # adv pdu
    preamble = 'aa'
  
  preamble_access_address_bit = hex_string_to_bit(preamble+access_address)

  info_bit = np.concatenate((preamble_access_address_bit, pdu_bit))
  if SAVE_FOR_VERILOG != 0:
    np.savetxt(SAVE_DIR+'/btle_tx_crc24_test_input.txt', info_bit, fmt='%d')
  info_bit_after_crc24 = crc24(info_bit, crc_state_init_bit)
  if SAVE_FOR_VERILOG != 0:
    np.savetxt(SAVE_DIR+'/btle_tx_crc24_test_output_ref.txt', info_bit_after_crc24, fmt='%d')
    np.savetxt(SAVE_DIR+'/btle_tx_scramble_test_input.txt', info_bit_after_crc24, fmt='%d')
  phy_bit = scramble(info_bit_after_crc24, channel_number)
  if SAVE_FOR_VERILOG != 0:
    np.savetxt(SAVE_DIR+'/btle_tx_scramble_test_output_ref.txt', phy_bit, fmt='%d')
  # print(bit_to_hex_string(phy_bit))
  phy_bit_upsample, _, cos_out_fixed_point, sin_out_fixed_point = gfsk_modulation_fixed_point(phy_bit)

  # iq = cos_out_fixed_point + 1j*sin_out_fixed_point
  # return iq
  return cos_out_fixed_point, sin_out_fixed_point, phy_bit, phy_bit_upsample

def gfsk_demodulation_fixed_point(i, q): # i and q are at symbol rate
  signal_for_decision = np.int32(i[0:-1])*np.int32(q[1:]) - np.int32(i[1:])*np.int32(q[0:-1])

  bit = np.int8(signal_for_decision>0)

  return bit, signal_for_decision

def search_unique_bit_sequence(bit, bit_sequence):
  num_bit = len(bit)
  len_sequence = len(bit_sequence)

  start_idx = int(-1)
  for i in range(num_bit - len_sequence + 1):
    if np.sum(bit[i:(i+len_sequence)] == bit_sequence) == len_sequence:
      start_idx = int(i)
      break

  return start_idx

def btle_rx(i, q, *argv): # i and q at sampling rate SAMPLE_PER_SYMBOL
  access_address = 'D6BE898E' # for advertisement channel, 0x8E89BED6 in standard. due to byte order here needs to be D6BE898E
  access_address_bit = hex_string_to_bit(access_address) 

  channel_number = 37 # Default broadcast channel number
  crc_state_init_bit = np.array([1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0], dtype=np.int8) # bl.hex_string_to_bit('555555')
  if len(argv) >= 1:
    channel_number = argv[0]
  if len(argv) >= 2:
    if len(argv[1]) == 24:
      crc_state_init_bit = argv[1]
    elif len(argv[1]) == 0:
      crc_state_init_bit = crc_state_init_bit
    else:
      print('btle_rx: The crc_state_init_bit argument needs to have exact 24 bits!')
      print('btle_rx: Ignore the input. Use 0x555555')
  if len(argv) >= 3:
    if len(argv[2]) == 8:
      access_address = argv[2]
    elif len(argv[2]) == 0:
      access_address = access_address
    else:
      print('btle_rx: The access_address argument needs to be hex string with length exact 8!')
      print('btle_rx: Ignore the input. Use ', access_address)
    access_address_bit = hex_string_to_bit(access_address)

  i = np.int16(i)
  q = np.int16(q)

  num_sample = len(i)
  bit_all_sample_phase = np.zeros((SAMPLE_PER_SYMBOL, round(num_sample/SAMPLE_PER_SYMBOL)-1), dtype=np.int8)
  signal_for_decision = np.zeros((SAMPLE_PER_SYMBOL, round(num_sample/SAMPLE_PER_SYMBOL)-1), dtype=np.int32)

  # start_idx_at_symbol_rate_store = []
  # sample_phase_idx_store = []
  # start_idx_store = []

  phy_bit = []
  pdu_bit = []
  num_byte_payload = int(0)
  crc_ok = False
  pdu_bit_start_idx = 40
  num_bit_pdu_header = 16
  num_miss_unique_bit_sequence = 0
  for sample_phase_idx in range(SAMPLE_PER_SYMBOL):
    # from rx I/Q to phy bit by gfsk demodulation
    bit_all_sample_phase[sample_phase_idx,:], signal_for_decision[sample_phase_idx,:] = gfsk_demodulation_fixed_point(i[sample_phase_idx::SAMPLE_PER_SYMBOL], q[sample_phase_idx::SAMPLE_PER_SYMBOL])
    start_idx_at_symbol_rate = search_unique_bit_sequence(bit_all_sample_phase[sample_phase_idx,:], access_address_bit)
    if start_idx_at_symbol_rate != int(-1):
      phy_bit = bit_all_sample_phase[sample_phase_idx, start_idx_at_symbol_rate:]

      # from phy bit to crc
      phy_bit = np.concatenate((np.zeros(8, dtype=np.int8), phy_bit))
      info_bit_after_crc24 = scramble(phy_bit, channel_number)
      num_byte_payload = int(0)
      if channel_number == 37 or channel_number == 38 or channel_number == 39: # adv pdu
        for idx in range(6):
          num_byte_payload = num_byte_payload + int(info_bit_after_crc24[pdu_bit_start_idx+8+idx])*np.left_shift(int(1), idx)
        # print('ADV  num_byte_payload ', num_byte_payload)
      else: # data pdu
        for idx in range(5):
          num_byte_payload = num_byte_payload + int(info_bit_after_crc24[pdu_bit_start_idx+8+idx])*np.left_shift(int(1), idx)
        # print('DATA num_byte_payload ', num_byte_payload)
      
      crc_bit_start_idx = pdu_bit_start_idx+num_bit_pdu_header+num_byte_payload*8
      
      if (crc_bit_start_idx+24) > len(info_bit_after_crc24):
        # print('num_byte_payload ', num_byte_payload, ' too big!')
        crc_bit_start_idx = len(info_bit_after_crc24) - 24

      pdu_bit = info_bit_after_crc24[pdu_bit_start_idx:crc_bit_start_idx]

      crc24_bit = crc24_core(pdu_bit, crc_state_init_bit)
      crc24_bit_rx = info_bit_after_crc24[crc_bit_start_idx:(crc_bit_start_idx+24)]
      # print('crc24_bit expected ', bit_to_hex_string(crc24_bit), ' rx ', bit_to_hex_string(crc24_bit_rx))
      if np.sum(crc24_bit == crc24_bit_rx) == 24:
        crc_ok = True
      else:
        crc_ok = False

      if SAVE_FOR_VERILOG != 0:
        np.savetxt(SAVE_DIR+'/btle_rx_gfsk_demodulation_test_input_i.txt', i[sample_phase_idx::SAMPLE_PER_SYMBOL], fmt='%d')
        np.savetxt(SAVE_DIR+'/btle_rx_gfsk_demodulation_test_input_q.txt', q[sample_phase_idx::SAMPLE_PER_SYMBOL], fmt='%d')
        np.savetxt(SAVE_DIR+'/btle_rx_gfsk_demodulation_test_output_bit_ref.txt', bit_all_sample_phase[sample_phase_idx,:], fmt='%d')
        np.savetxt(SAVE_DIR+'/btle_rx_gfsk_demodulation_test_output_signal_for_decision_ref.txt', signal_for_decision[sample_phase_idx,:], fmt='%d')

        np.savetxt(SAVE_DIR+'/btle_rx_search_unique_bit_sequence_test_input.txt', bit_all_sample_phase[sample_phase_idx,:], fmt='%d')
        np.savetxt(SAVE_DIR+'/btle_rx_search_unique_bit_sequence_test_output_ref.txt', [start_idx_at_symbol_rate], fmt='%d')

        np.savetxt(SAVE_DIR+'/btle_rx_btle_rx_core_test_input_i.txt', i[sample_phase_idx::SAMPLE_PER_SYMBOL], fmt='%d')
        np.savetxt(SAVE_DIR+'/btle_rx_btle_rx_core_test_input_q.txt', q[sample_phase_idx::SAMPLE_PER_SYMBOL], fmt='%d')
        bit_to_txt_octet_per_line(pdu_bit, SAVE_DIR+'/btle_rx_btle_rx_core_test_output_ref.txt')
        np.savetxt(SAVE_DIR+'/btle_rx_btle_rx_core_test_output_bit_ref.txt', pdu_bit, fmt='%d')
        np.savetxt(SAVE_DIR+'/btle_rx_btle_rx_core_test_output_crc_ok_ref.txt', [crc_ok], fmt='%d')
      
      if crc_ok:
        break

    else:
      num_miss_unique_bit_sequence = num_miss_unique_bit_sequence + 1

  if (num_miss_unique_bit_sequence == SAMPLE_PER_SYMBOL):
    print('btle_rx: Access address NOT found!')
    if SAVE_FOR_VERILOG != 0:
      file_set_to_remove = [SAVE_DIR+'/btle_rx_gfsk_demodulation_test_input_i.txt', 
                            SAVE_DIR+'/btle_rx_gfsk_demodulation_test_input_q.txt',
                            SAVE_DIR+'/btle_rx_gfsk_demodulation_test_output_bit_ref.txt',
                            SAVE_DIR+'/btle_rx_gfsk_demodulation_test_output_signal_for_decision_ref.txt',
                            SAVE_DIR+'/btle_rx_search_unique_bit_sequence_test_input.txt',
                            SAVE_DIR+'/btle_rx_search_unique_bit_sequence_test_output_ref.txt',
                            SAVE_DIR+'/btle_rx_btle_rx_core_test_input_i.txt',
                            SAVE_DIR+'/btle_rx_btle_rx_core_test_input_q.txt',
                            SAVE_DIR+'/btle_rx_btle_rx_core_test_output_ref.txt',
                            SAVE_DIR+'/btle_rx_btle_rx_core_test_output_bit_ref.txt',
                            SAVE_DIR+'/btle_rx_btle_rx_core_test_output_crc_ok_ref.txt']
      for filename in file_set_to_remove:
        if os.path.exists(filename):
          os.remove(filename)

  return pdu_bit, crc_ok, num_byte_payload, phy_bit, bit_all_sample_phase, signal_for_decision, sample_phase_idx

def btle_rx_old(i, q, *argv): # i and q at sampling rate SAMPLE_PER_SYMBOL
  access_address = 'D6BE898E' # for advertisement channel, 0x8E89BED6 in standard. due to byte order here needs to be D6BE898E
  access_address_bit = hex_string_to_bit(access_address) 

  channel_number = 37 # Default broadcast channel number
  crc_state_init_bit = np.array([1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0], dtype=np.int8) # bl.hex_string_to_bit('555555')
  if len(argv) >= 1:
    channel_number = argv[0]
  if len(argv) >= 2:
    if len(argv[1]) == 24:
      crc_state_init_bit = argv[1]
    elif len(argv[1]) == 0:
      crc_state_init_bit = crc_state_init_bit
    else:
      print('btle_rx: The crc_state_init_bit argument needs to have exact 24 bits!')
      print('btle_rx: Ignore the input. Use 0x555555')
  if len(argv) >= 3:
    if len(argv[2]) == 8:
      access_address = argv[2]
    elif len(argv[2]) == 0:
      access_address = access_address
    else:
      print('btle_rx: The access_address argument needs to be hex string with length exact 8!')
      print('btle_rx: Ignore the input. Use ', access_address)
    access_address_bit = hex_string_to_bit(access_address)

  i = np.int16(i)
  q = np.int16(q)

  num_sample = len(i)
  bit_all_sample_phase = np.zeros((SAMPLE_PER_SYMBOL, round(num_sample/SAMPLE_PER_SYMBOL)-1), dtype=np.int8)
  signal_for_decision = np.zeros((SAMPLE_PER_SYMBOL, round(num_sample/SAMPLE_PER_SYMBOL)-1), dtype=np.int32)

  start_idx_at_symbol_rate_store = []
  sample_phase_idx_store = []
  start_idx_store = []

  for sample_phase_idx in range(SAMPLE_PER_SYMBOL):
    bit_all_sample_phase[sample_phase_idx,:], signal_for_decision[sample_phase_idx,:] = gfsk_demodulation_fixed_point(i[sample_phase_idx::SAMPLE_PER_SYMBOL], q[sample_phase_idx::SAMPLE_PER_SYMBOL])
    start_idx_at_symbol_rate = search_unique_bit_sequence(bit_all_sample_phase[sample_phase_idx,:], access_address_bit)
    if start_idx_at_symbol_rate != int(-1):
      start_idx_at_symbol_rate_store.append(start_idx_at_symbol_rate)
      sample_phase_idx_store.append(int(sample_phase_idx))
      start_idx_store.append(start_idx_at_symbol_rate*SAMPLE_PER_SYMBOL + sample_phase_idx)

  phy_bit = []
  pdu_bit = []
  num_byte_payload = int(0)
  crc_ok = False
  if len(start_idx_store) > 0:
    # print('Access address at sample ', start_idx_store, ' with phase idx ', sample_phase_idx_store)
    start_idx = int(np.floor(np.mean(start_idx_store)))

    # Find the idx in the hit set for the optimal start_idx
    found = False
    for idx_for_optimal_pick in range(len(start_idx_store)):
      tmp_idx = start_idx_store[idx_for_optimal_pick]
      if tmp_idx == start_idx:
        found = True
        break
    if found:
      idx_for_optimal_pick = idx_for_optimal_pick
      # print('Optimal sample idx '+str(start_idx)+'; idx in the hit set '+str(idx_for_optimal_pick))
    else:
      idx_for_optimal_pick = 0
      # print('Optimal sample idx '+str(start_idx)+'; NOT in the hit set! Just select the 1st one: idx 0')

    ### # if len(idx_for_optimal_pick) == 1:
      
    sample_phase_idx = sample_phase_idx_store[idx_for_optimal_pick]
    start_idx_at_symbol_rate = start_idx_at_symbol_rate_store[idx_for_optimal_pick]
    phy_bit = bit_all_sample_phase[sample_phase_idx, start_idx_at_symbol_rate:]
    if SAVE_FOR_VERILOG != 0:
      np.savetxt(SAVE_DIR+'/btle_rx_gfsk_demodulation_test_input_i.txt', i[sample_phase_idx::SAMPLE_PER_SYMBOL], fmt='%d')
      np.savetxt(SAVE_DIR+'/btle_rx_gfsk_demodulation_test_input_q.txt', q[sample_phase_idx::SAMPLE_PER_SYMBOL], fmt='%d')
      np.savetxt(SAVE_DIR+'/btle_rx_gfsk_demodulation_test_output_bit_ref.txt', bit_all_sample_phase[sample_phase_idx,:], fmt='%d')
      np.savetxt(SAVE_DIR+'/btle_rx_gfsk_demodulation_test_output_signal_for_decision_ref.txt', signal_for_decision[sample_phase_idx,:], fmt='%d')

      np.savetxt(SAVE_DIR+'/btle_rx_search_unique_bit_sequence_test_input.txt', bit_all_sample_phase[sample_phase_idx,:], fmt='%d')
      np.savetxt(SAVE_DIR+'/btle_rx_search_unique_bit_sequence_test_output_ref.txt', [start_idx_at_symbol_rate], fmt='%d')

      np.savetxt(SAVE_DIR+'/btle_rx_btle_rx_core_test_input_i.txt', i[sample_phase_idx::SAMPLE_PER_SYMBOL], fmt='%d')
      np.savetxt(SAVE_DIR+'/btle_rx_btle_rx_core_test_input_q.txt', q[sample_phase_idx::SAMPLE_PER_SYMBOL], fmt='%d')
    # print('Optimal start_idx ', start_idx, ' sample_phase_idx ', sample_phase_idx, ' start_idx_at_symbol_rate ', start_idx_at_symbol_rate)
    # print(bit_to_hex_string(phy_bit))
    
    ### # else:
    ### #   abs_diff_vec = np.abs(start_idx_store - start_idx)
    ### #   idx_for_optimal_pick = np.argmin(abs_diff_vec)
    ### #   sample_phase_idx = sample_phase_idx_store[idx_for_optimal_pick]
    ### #   start_idx_at_symbol_rate = start_idx_at_symbol_rate_store[idx_for_optimal_pick]
    ### #   print('Optimal start_idx ', start_idx_store[idx_for_optimal_pick], ' sample_phase_idx ', sample_phase_idx, ' start_idx_at_symbol_rate ', start_idx_at_symbol_rate)
    ### #   print(bit_to_hex_string(bit_all_sample_phase[sample_phase_idx, start_idx_at_symbol_rate:]))
    ### #   start_idx_store_new = np.append(start_idx_store, int(start_idx))
    ### #   print(start_idx_store_new, int(start_idx))
    ### #   for idx in range(len(start_idx_store_new)):
    ### #     start_idx = start_idx_store_new[idx]
    ### #     print(start_idx)
    ### #     sample_phase_idx = sample_phase_idx_store[idx]
    ### #     start_idx_at_symbol_rate = start_idx_at_symbol_rate_store[idx]
    ### #     print(bit_to_hex_string(bit_all_sample_phase[sample_phase_idx, start_idx_at_symbol_rate:]))

    # this phy_bit has access address d6be898e, but no preamble. add a fake one to align the processing inside scramble and crc
    phy_bit = np.concatenate((np.zeros(8, dtype=np.int8), phy_bit))
    info_bit_after_crc24 = scramble(phy_bit, channel_number)
    pdu_bit_start_idx = 40
    num_byte_payload = int(0)
    if channel_number == 37 or channel_number == 38 or channel_number == 39: # adv pdu
      for idx in range(6):
        num_byte_payload = num_byte_payload + int(info_bit_after_crc24[pdu_bit_start_idx+8+idx])*np.left_shift(int(1), idx)
      # print('ADV  num_byte_payload ', num_byte_payload)
    else: # data pdu
      for idx in range(5):
        num_byte_payload = num_byte_payload + int(info_bit_after_crc24[pdu_bit_start_idx+8+idx])*np.left_shift(int(1), idx)
      # print('DATA num_byte_payload ', num_byte_payload)
    
    num_bit_pdu_header = 16
    crc_bit_start_idx = pdu_bit_start_idx+num_bit_pdu_header+num_byte_payload*8
    
    if (crc_bit_start_idx+24) > len(info_bit_after_crc24):
      # print('num_byte_payload ', num_byte_payload, ' too big!')
      crc_bit_start_idx = len(info_bit_after_crc24) - 24

    pdu_bit = info_bit_after_crc24[pdu_bit_start_idx:crc_bit_start_idx]
    if SAVE_FOR_VERILOG != 0:
      bit_to_txt_octet_per_line(pdu_bit, SAVE_DIR+'/btle_rx_btle_rx_core_test_output_ref.txt')
      np.savetxt(SAVE_DIR+'/btle_rx_btle_rx_core_test_output_bit_ref.txt', pdu_bit, fmt='%d')

    crc24_bit = crc24_core(pdu_bit, crc_state_init_bit)
    crc24_bit_rx = info_bit_after_crc24[crc_bit_start_idx:(crc_bit_start_idx+24)]
    # print('crc24_bit expected ', bit_to_hex_string(crc24_bit), ' rx ', bit_to_hex_string(crc24_bit_rx))
    if np.sum(crc24_bit == crc24_bit_rx) == 24:
      crc_ok = True
    else:
      crc_ok = False
    # print('crc_ok ', crc_ok)
  else:
    print('Access address NOT found!')
    if SAVE_FOR_VERILOG != 0:
      file_set_to_remove = [SAVE_DIR+'/btle_rx_gfsk_demodulation_test_input_i.txt', 
                            SAVE_DIR+'/btle_rx_gfsk_demodulation_test_input_q.txt',
                            SAVE_DIR+'/btle_rx_gfsk_demodulation_test_output_bit_ref.txt',
                            SAVE_DIR+'/btle_rx_gfsk_demodulation_test_output_signal_for_decision_ref.txt',
                            SAVE_DIR+'/btle_rx_search_unique_bit_sequence_test_input.txt',
                            SAVE_DIR+'/btle_rx_search_unique_bit_sequence_test_output_ref.txt',
                            SAVE_DIR+'/btle_rx_btle_rx_core_test_input_i.txt',
                            SAVE_DIR+'/btle_rx_btle_rx_core_test_input_q.txt',
                            SAVE_DIR+'/btle_rx_btle_rx_core_test_output_ref.txt',
                            SAVE_DIR+'/btle_rx_btle_rx_core_test_output_bit_ref.txt']
      for filename in file_set_to_remove:
        if os.path.exists(filename):
          os.remove(filename)

  return pdu_bit, crc_ok, num_byte_payload, phy_bit, bit_all_sample_phase, signal_for_decision, sample_phase_idx

# def btle_rx_filtered(i, q, *argv): # i and q at sampling rate SAMPLE_PER_SYMBOL
#   if not hasattr(btle_rx, "access_address_bit"):
#     access_address_bit = hex_string_to_bit('d6be898e')

#   channel_number = 37 # Default broadcast channel number
#   crc_state_init_bit = np.array([1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0], dtype=np.int8) # bl.hex_string_to_bit('555555')
#   if len(argv) == 1:
#     channel_number = argv[0]
#   if len(argv) == 2:
#     if len(argv[1]) == 24:
#       crc_state_init_bit = argv[1]
#     elif len(argv[1]) == 0:
#       crc_state_init_bit = crc_state_init_bit
#     else:
#       print('btle_rx: The crc_state_init_bit argument needs to have exact 24 bits!')
#       print('btle_rx: Ignore the input. Use 0x555555')

#   # i = np.int16(np.concatenate(i, np.zeros(1, dtype=np.int16)))
#   # q = np.int16(np.concatenate(q, np.zeros(1, dtype=np.int16)))
#   i = np.int16(i)
#   q = np.int16(q)

#   # generate filtered fo signal
#   fo_signal_raw = np.int32(i[0:-1])*np.int32(q[1:]) - np.int32(i[1:])*np.int32(q[0:-1])
#   fo_signal_raw = np.convolve(fo_signal_raw, np.ones(2, dtype=np.int32), 'same')

#   num_sample = len(fo_signal_raw)
#   bit_all_sample_phase = np.zeros((SAMPLE_PER_SYMBOL, round(num_sample/SAMPLE_PER_SYMBOL)), dtype=np.int8)
#   signal_for_decision = np.zeros((SAMPLE_PER_SYMBOL, round(num_sample/SAMPLE_PER_SYMBOL)), dtype=np.int32)

#   start_idx_at_symbol_rate_store = []
#   sample_phase_idx_store = []
#   start_idx_store = []

#   for sample_phase_idx in range(SAMPLE_PER_SYMBOL):
#     signal_for_decision[sample_phase_idx,0:len(fo_signal_raw[sample_phase_idx::SAMPLE_PER_SYMBOL])] = fo_signal_raw[sample_phase_idx::SAMPLE_PER_SYMBOL]
#     bit_all_sample_phase[sample_phase_idx,0:len(signal_for_decision[sample_phase_idx,:])] = np.int8(signal_for_decision[sample_phase_idx,:]>0)
#     start_idx_at_symbol_rate = search_unique_bit_sequence(bit_all_sample_phase[sample_phase_idx,:], access_address_bit)
#     if start_idx_at_symbol_rate != int(-1):
#       start_idx_at_symbol_rate_store.append(start_idx_at_symbol_rate)
#       sample_phase_idx_store.append(int(sample_phase_idx))
#       start_idx_store.append(start_idx_at_symbol_rate*SAMPLE_PER_SYMBOL + sample_phase_idx)

#   phy_bit = []
#   pdu_bit = []
#   num_byte_payload = int(0)
#   crc_ok = False
#   if len(start_idx_store) > 0:
#     # print('Access address at sample ', start_idx_store, ' with phase idx ', sample_phase_idx_store)
#     start_idx = int(np.floor(np.mean(start_idx_store)))

#     # Find the idx in the hit set for the optimal start_idx
#     found = False
#     for idx_for_optimal_pick in range(len(start_idx_store)):
#       tmp_idx = start_idx_store[idx_for_optimal_pick]
#       if tmp_idx == start_idx:
#         found = True
#         break
#     if found:
#       idx_for_optimal_pick = idx_for_optimal_pick
#       # print('Optimal sample idx '+str(start_idx)+'; idx in the hit set '+str(idx_for_optimal_pick))
#     else:
#       idx_for_optimal_pick = 0
#       # print('Optimal sample idx '+str(start_idx)+'; NOT in the hit set! Just select the 1st one: idx 0')

#     ### # if len(idx_for_optimal_pick) == 1:
      
#     sample_phase_idx = sample_phase_idx_store[idx_for_optimal_pick]
#     start_idx_at_symbol_rate = start_idx_at_symbol_rate_store[idx_for_optimal_pick]
#     phy_bit = bit_all_sample_phase[sample_phase_idx, start_idx_at_symbol_rate:]
#     # print('Optimal start_idx ', start_idx, ' sample_phase_idx ', sample_phase_idx, ' start_idx_at_symbol_rate ', start_idx_at_symbol_rate)
#     # print(bit_to_hex_string(phy_bit))
    
#     ### # else:
#     ### #   abs_diff_vec = np.abs(start_idx_store - start_idx)
#     ### #   idx_for_optimal_pick = np.argmin(abs_diff_vec)
#     ### #   sample_phase_idx = sample_phase_idx_store[idx_for_optimal_pick]
#     ### #   start_idx_at_symbol_rate = start_idx_at_symbol_rate_store[idx_for_optimal_pick]
#     ### #   print('Optimal start_idx ', start_idx_store[idx_for_optimal_pick], ' sample_phase_idx ', sample_phase_idx, ' start_idx_at_symbol_rate ', start_idx_at_symbol_rate)
#     ### #   print(bit_to_hex_string(bit_all_sample_phase[sample_phase_idx, start_idx_at_symbol_rate:]))
#     ### #   start_idx_store_new = np.append(start_idx_store, int(start_idx))
#     ### #   print(start_idx_store_new, int(start_idx))
#     ### #   for idx in range(len(start_idx_store_new)):
#     ### #     start_idx = start_idx_store_new[idx]
#     ### #     print(start_idx)
#     ### #     sample_phase_idx = sample_phase_idx_store[idx]
#     ### #     start_idx_at_symbol_rate = start_idx_at_symbol_rate_store[idx]
#     ### #     print(bit_to_hex_string(bit_all_sample_phase[sample_phase_idx, start_idx_at_symbol_rate:]))

#     # this phy_bit has access address d6be898e, but no preamble. add a fake one to align the processing inside scramble and crc
#     phy_bit = np.concatenate((np.zeros(8, dtype=np.int8), phy_bit))
#     info_bit_after_crc24 = scramble(phy_bit, channel_number)
#     pdu_bit_start_idx = 40
#     num_byte_payload = int(0)
#     if channel_number == 37 or channel_number == 38 or channel_number == 39: # adv pdu
#       for idx in range(6):
#         num_byte_payload = num_byte_payload + int(info_bit_after_crc24[pdu_bit_start_idx+8+idx])*np.left_shift(int(1), idx)
#       # print('ADV  num_byte_payload ', num_byte_payload)
#     else: # data pdu
#       for idx in range(5):
#         num_byte_payload = num_byte_payload + int(info_bit_after_crc24[pdu_bit_start_idx+8+idx])*np.left_shift(int(1), idx)
#       # print('DATA num_byte_payload ', num_byte_payload)
    
#     num_bit_pdu_header = 16
#     crc_bit_start_idx = pdu_bit_start_idx+num_bit_pdu_header+num_byte_payload*8
    
#     if (crc_bit_start_idx+24) > len(info_bit_after_crc24):
#       print('num_byte_payload ', num_byte_payload, ' too big!')
#       crc_bit_start_idx = len(info_bit_after_crc24) - 24

#     pdu_bit = info_bit_after_crc24[pdu_bit_start_idx:crc_bit_start_idx]
#     # print(bit_to_hex_string(pdu_bit))
#     crc24_bit = crc24_core(pdu_bit, crc_state_init_bit)
#     crc24_bit_rx = info_bit_after_crc24[crc_bit_start_idx:(crc_bit_start_idx+24)]
#     print('crc24_bit expected ', bit_to_hex_string(crc24_bit), ' rx ', bit_to_hex_string(crc24_bit_rx))
#     if np.sum(crc24_bit == crc24_bit_rx) == 24:
#       crc_ok = True
#     else:
#       crc_ok = False
#     # print('crc_ok ', crc_ok)
#   else:
#     print('Access address NOT found!')

#   return pdu_bit, crc_ok, num_byte_payload, phy_bit, bit_all_sample_phase, signal_for_decision

def add_freq_sampling_error(i, q, ppm_value):
  i = np.double(i)
  q = np.double(q)

  # The normalized sampling frequency error:
  sampling_freq_error = np.double(ppm_value/1e6)

  xp = np.linspace(0, len(i)-1, len(i))
  x = xp*(1.0+sampling_freq_error)

  i = np.interp(x, xp, i)
  q = np.interp(x, xp, q)

  # return i, q

  # The center frequency is 2450e6
  # The carrier frequency offset:
  fo = sampling_freq_error*2450e6

  # The original sampling frequency: SAMPLE_PER_SYMBOL MHz
  # The original sampling time: 
  orig_sampling_time = (1.0/SAMPLE_PER_SYMBOL)*1e-6
  # The new sampling time: 
  new_sampling_time = orig_sampling_time*(1+sampling_freq_error)
  # print(fo, orig_sampling_time, new_sampling_time)

  # The frequency shift vector
  freq_shift_vec = np.exp(1j*2.0*np.pi*fo*new_sampling_time*np.linspace(0, len(i)-1, len(i)))

  iq = (i + 1j*q)*freq_shift_vec

  i_new = np.real(iq)
  q_new = np.imag(iq)

  return i_new, q_new, freq_shift_vec, fo

def add_noise(tx_i, tx_q, snr):
  # # Add noise according to SNR
  # # sin&cos peak is 127, power is 127*127 (int8)
  # # SNR(dB) = 10*log10(127*127/noise_sigma2)
  # # noise_sigma = sqrt(127*127/(10^(SNR/10))) = 127/(10^(SNR/20))
  sigma_total = 127/np.power(10, snr/20)
  # print(sigma_total)
  # print(np.sqrt(127*127/np.power(10, snr/10)))
  
  sigma = sigma_total/np.sqrt(2) # i and q each has half noise power

  rx_i = np.double(tx_i) + np.random.normal(0, sigma, len(tx_i))
  rx_q = np.double(tx_q) + np.random.normal(0, sigma, len(tx_q))

  return rx_i, rx_q

def tmp_test(a):
  if not hasattr(tmp_test, "sample_per_symbol"):
    tmp_test.sample_per_symbol = SAMPLE_PER_SYMBOL
  
  b = a + tmp_test.sample_per_symbol

  print('bl.tmp_test ', SAMPLE_PER_SYMBOL)

  return b
