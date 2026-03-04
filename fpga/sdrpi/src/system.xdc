# Author: Xianjun Jiao
# SPDX-FileCopyrightText: 2025 Xianjun Jiao <putaoshu@msn.com>
# SPDX-License-Identifier: Apache-2.0

# ila (might be auto upated by vivado)


connect_debug_port u_ila_0/probe6 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/ext_rx_best_phase[0]} {i_system_wrapper/system_i/btle_controller_0/inst/ext_rx_best_phase[1]} {i_system_wrapper/system_i/btle_controller_0/inst/ext_rx_best_phase[2]}]]
connect_debug_port u_ila_0/probe7 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/ext_rx_payload_length[0]} {i_system_wrapper/system_i/btle_controller_0/inst/ext_rx_payload_length[1]} {i_system_wrapper/system_i/btle_controller_0/inst/ext_rx_payload_length[2]} {i_system_wrapper/system_i/btle_controller_0/inst/ext_rx_payload_length[3]} {i_system_wrapper/system_i/btle_controller_0/inst/ext_rx_payload_length[4]} {i_system_wrapper/system_i/btle_controller_0/inst/ext_rx_payload_length[5]} {i_system_wrapper/system_i/btle_controller_0/inst/ext_rx_payload_length[6]}]]
connect_debug_port u_ila_0/probe11 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/ext_rx_hit_flag]]
connect_debug_port u_ila_0/probe12 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/ext_rx_decode_run]]
connect_debug_port u_ila_0/probe13 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/ext_rx_decode_end]]
connect_debug_port u_ila_0/probe14 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/ext_rx_crc_ok]]


create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 16384 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list i_system_wrapper/system_i/clk_wiz_1/inst/clk_out2]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 2 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/phy_tx_state[0]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/phy_tx_state[1]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 9 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/payload_length[0]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/payload_length[1]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/payload_length[2]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/payload_length[3]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/payload_length[4]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/payload_length[5]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/payload_length[6]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/payload_length[7]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/payload_length[8]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 8 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/octet[0]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/octet[1]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/octet[2]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/octet[3]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/octet[4]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/octet[5]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/octet[6]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/octet[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 8 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/i_internal[0]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/i_internal[1]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/i_internal[2]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/i_internal[3]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/i_internal[4]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/i_internal[5]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/i_internal[6]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/i_internal[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 16 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/gauss_filter_tap_value[0]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/gauss_filter_tap_value[1]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/gauss_filter_tap_value[2]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/gauss_filter_tap_value[3]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/gauss_filter_tap_value[4]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/gauss_filter_tap_value[5]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/gauss_filter_tap_value[6]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/gauss_filter_tap_value[7]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/gauss_filter_tap_value[8]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/gauss_filter_tap_value[9]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/gauss_filter_tap_value[10]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/gauss_filter_tap_value[11]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/gauss_filter_tap_value[12]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/gauss_filter_tap_value[13]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/gauss_filter_tap_value[14]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/gauss_filter_tap_value[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 4 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/gauss_filter_tap_index[0]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/gauss_filter_tap_index[1]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/gauss_filter_tap_index[2]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/gauss_filter_tap_index[3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 8 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/cos_table_write_data[0]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/cos_table_write_data[1]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/cos_table_write_data[2]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/cos_table_write_data[3]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/cos_table_write_data[4]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/cos_table_write_data[5]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/cos_table_write_data[6]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/cos_table_write_data[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 11 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/cos_table_write_address[0]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/cos_table_write_address[1]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/cos_table_write_address[2]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/cos_table_write_address[3]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/cos_table_write_address[4]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/cos_table_write_address[5]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/cos_table_write_address[6]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/cos_table_write_address[7]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/cos_table_write_address[8]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/cos_table_write_address[9]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/cos_table_write_address[10]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
set_property port_width 7 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/clk_count[0]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/clk_count[1]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/clk_count[2]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/clk_count[3]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/clk_count[4]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/clk_count[5]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/clk_count[6]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
set_property port_width 6 [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/bit_count_preamble_access[0]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/bit_count_preamble_access[1]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/bit_count_preamble_access[2]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/bit_count_preamble_access[3]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/bit_count_preamble_access[4]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/bit_count_preamble_access[5]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
set_property port_width 12 [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/bit_count[0]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/bit_count[1]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/bit_count[2]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/bit_count[3]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/bit_count[4]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/bit_count[5]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/bit_count[6]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/bit_count[7]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/bit_count[8]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/bit_count[9]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/bit_count[10]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/bit_count[11]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe11]
set_property port_width 9 [get_debug_ports u_ila_0/probe11]
connect_debug_port u_ila_0/probe11 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/addr[0]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/addr[1]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/addr[2]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/addr[3]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/addr[4]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/addr[5]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/addr[6]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/addr[7]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/addr[8]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe12]
set_property port_width 24 [get_debug_ports u_ila_0/probe12]
connect_debug_port u_ila_0/probe12 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/crc24_i/crc_state_init_bit[0]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/crc24_i/crc_state_init_bit[1]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/crc24_i/crc_state_init_bit[2]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/crc24_i/crc_state_init_bit[3]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/crc24_i/crc_state_init_bit[4]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/crc24_i/crc_state_init_bit[5]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/crc24_i/crc_state_init_bit[6]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/crc24_i/crc_state_init_bit[7]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/crc24_i/crc_state_init_bit[8]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/crc24_i/crc_state_init_bit[9]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/crc24_i/crc_state_init_bit[10]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/crc24_i/crc_state_init_bit[11]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/crc24_i/crc_state_init_bit[12]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/crc24_i/crc_state_init_bit[13]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/crc24_i/crc_state_init_bit[14]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/crc24_i/crc_state_init_bit[15]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/crc24_i/crc_state_init_bit[16]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/crc24_i/crc_state_init_bit[17]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/crc24_i/crc_state_init_bit[18]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/crc24_i/crc_state_init_bit[19]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/crc24_i/crc_state_init_bit[20]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/crc24_i/crc_state_init_bit[21]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/crc24_i/crc_state_init_bit[22]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/crc24_i/crc_state_init_bit[23]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe13]
set_property port_width 1 [get_debug_ports u_ila_0/probe13]
connect_debug_port u_ila_0/probe13 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/crc24_i/crc_state_init_bit_load]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe14]
set_property port_width 1 [get_debug_ports u_ila_0/probe14]
connect_debug_port u_ila_0/probe14 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/tx_start]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe15]
set_property port_width 1 [get_debug_ports u_ila_0/probe15]
connect_debug_port u_ila_0/probe15 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/iq_valid]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe16]
set_property port_width 1 [get_debug_ports u_ila_0/probe16]
connect_debug_port u_ila_0/probe16 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/iq_valid_last]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe17]
set_property port_width 1 [get_debug_ports u_ila_0/probe17]
connect_debug_port u_ila_0/probe17 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/phy_bit_valid]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe18]
set_property port_width 1 [get_debug_ports u_ila_0/probe18]
connect_debug_port u_ila_0/probe18 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/phy_bit_valid_last]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe19]
set_property port_width 1 [get_debug_ports u_ila_0/probe19]
connect_debug_port u_ila_0/probe19 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/bit_upsample_valid]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe20]
set_property port_width 1 [get_debug_ports u_ila_0/probe20]
connect_debug_port u_ila_0/probe20 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/bit_upsample_valid_last]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe21]
set_property port_width 1 [get_debug_ports u_ila_0/probe21]
connect_debug_port u_ila_0/probe21 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/bit_upsample_gauss_filter_valid]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe22]
set_property port_width 1 [get_debug_ports u_ila_0/probe22]
connect_debug_port u_ila_0/probe22 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/bit_upsample_gauss_filter_valid_last]]
create_debug_core u_ila_1 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_1]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_1]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_1]
set_property C_DATA_DEPTH 16384 [get_debug_cores u_ila_1]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_1]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_1]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_1]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_1]
set_property port_width 1 [get_debug_ports u_ila_1/clk]
connect_debug_port u_ila_1/clk [get_nets [list i_system_wrapper/system_i/sys_ps7/inst/FCLK_CLK0]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe0]
set_property port_width 8 [get_debug_ports u_ila_1/probe0]
connect_debug_port u_ila_1/probe0 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/pdu_octet_mem_data[0]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/pdu_octet_mem_data[1]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/pdu_octet_mem_data[2]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/pdu_octet_mem_data[3]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/pdu_octet_mem_data[4]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/pdu_octet_mem_data[5]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/pdu_octet_mem_data[6]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/pdu_octet_mem_data[7]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe1]
set_property port_width 9 [get_debug_ports u_ila_1/probe1]
connect_debug_port u_ila_1/probe1 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/pdu_octet_mem_addr[0]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/pdu_octet_mem_addr[1]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/pdu_octet_mem_addr[2]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/pdu_octet_mem_addr[3]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/pdu_octet_mem_addr[4]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/pdu_octet_mem_addr[5]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/pdu_octet_mem_addr[6]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/pdu_octet_mem_addr[7]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/pdu_octet_mem_addr[8]}]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets u_ila_1_FCLK_CLK0]
