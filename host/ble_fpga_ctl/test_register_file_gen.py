# please run test_vector_for_btle_verilog.py in python directory firstly!

import numpy as np

SAVE_DIR = '../../verilog/'

btle_config = np.loadtxt(SAVE_DIR+'/btle_config.txt', dtype=np.uint32, converters={0: lambda s: int(s, 16)})

# with open(SAVE_DIR+'/btle_config.txt') as f:
#     lines = [line.strip() for line in f]

# # convert values
# num_pdu_bit = int(lines[0])        # decimal
# channel_number = int(lines[1])     # decimal
# crc_state_init = int(lines[2], 16) # hex
# access_address = int(lines[3], 16) # hex

preamble = 0xAA

gauss_filter_tap_value = np.loadtxt(SAVE_DIR+'/gauss_filter_tap.txt', dtype=int)
cos_table_write_data = np.loadtxt(SAVE_DIR+'/cos_table.txt', dtype=int)
sin_table_write_data = np.loadtxt(SAVE_DIR+'/sin_table.txt', dtype=int)

tx_pdu_octet_mem_data = np.loadtxt(SAVE_DIR+'/btle_tx_test_input.txt', dtype=np.uint8, converters={0: lambda s: int(s, 16)})

print('num_pdu_bit:', btle_config[0])
print('channel_number:', btle_config[1])
print('crc_state_init:', hex(btle_config[2]))
print('access_address:', hex(btle_config[3]))
print('preamble:', hex(preamble))
print('gauss_filter_tap_value:', gauss_filter_tap_value)
print('cos_table_write_data:', cos_table_write_data)
print('sin_table_write_data:', sin_table_write_data)
print('tx_pdu_octet_mem_data:', tx_pdu_octet_mem_data)
