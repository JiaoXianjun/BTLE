# Author: Xianjun Jiao
# SPDX-FileCopyrightText: 2025 Xianjun Jiao <putaoshu@msn.com>
# SPDX-License-Identifier: Apache-2.0

# ila (might be auto upated by vivado)

create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list i_system_wrapper/system_i/clk_wiz_1/inst/clk_out2]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 32 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/rx_unique_bit_sequence[0]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_unique_bit_sequence[1]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_unique_bit_sequence[2]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_unique_bit_sequence[3]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_unique_bit_sequence[4]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_unique_bit_sequence[5]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_unique_bit_sequence[6]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_unique_bit_sequence[7]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_unique_bit_sequence[8]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_unique_bit_sequence[9]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_unique_bit_sequence[10]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_unique_bit_sequence[11]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_unique_bit_sequence[12]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_unique_bit_sequence[13]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_unique_bit_sequence[14]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_unique_bit_sequence[15]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_unique_bit_sequence[16]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_unique_bit_sequence[17]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_unique_bit_sequence[18]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_unique_bit_sequence[19]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_unique_bit_sequence[20]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_unique_bit_sequence[21]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_unique_bit_sequence[22]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_unique_bit_sequence[23]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_unique_bit_sequence[24]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_unique_bit_sequence[25]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_unique_bit_sequence[26]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_unique_bit_sequence[27]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_unique_bit_sequence[28]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_unique_bit_sequence[29]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_unique_bit_sequence[30]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_unique_bit_sequence[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 16 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/rx_q_signal[0]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_q_signal[1]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_q_signal[2]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_q_signal[3]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_q_signal[4]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_q_signal[5]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_q_signal[6]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_q_signal[7]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_q_signal[8]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_q_signal[9]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_q_signal[10]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_q_signal[11]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_q_signal[12]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_q_signal[13]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_q_signal[14]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_q_signal[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 16 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/rx_i_signal[0]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_i_signal[1]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_i_signal[2]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_i_signal[3]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_i_signal[4]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_i_signal[5]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_i_signal[6]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_i_signal[7]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_i_signal[8]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_i_signal[9]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_i_signal[10]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_i_signal[11]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_i_signal[12]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_i_signal[13]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_i_signal[14]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_i_signal[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 24 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/rx_crc_state_init_bit[0]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_crc_state_init_bit[1]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_crc_state_init_bit[2]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_crc_state_init_bit[3]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_crc_state_init_bit[4]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_crc_state_init_bit[5]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_crc_state_init_bit[6]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_crc_state_init_bit[7]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_crc_state_init_bit[8]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_crc_state_init_bit[9]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_crc_state_init_bit[10]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_crc_state_init_bit[11]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_crc_state_init_bit[12]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_crc_state_init_bit[13]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_crc_state_init_bit[14]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_crc_state_init_bit[15]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_crc_state_init_bit[16]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_crc_state_init_bit[17]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_crc_state_init_bit[18]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_crc_state_init_bit[19]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_crc_state_init_bit[20]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_crc_state_init_bit[21]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_crc_state_init_bit[22]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_crc_state_init_bit[23]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 6 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/rx_channel_number[0]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_channel_number[1]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_channel_number[2]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_channel_number[3]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_channel_number[4]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_channel_number[5]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 7 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/rf_gain[0]} {i_system_wrapper/system_i/btle_controller_0/inst/rf_gain[1]} {i_system_wrapper/system_i/btle_controller_0/inst/rf_gain[2]} {i_system_wrapper/system_i/btle_controller_0/inst/rf_gain[3]} {i_system_wrapper/system_i/btle_controller_0/inst/rf_gain[4]} {i_system_wrapper/system_i/btle_controller_0/inst/rf_gain[5]} {i_system_wrapper/system_i/btle_controller_0/inst/rf_gain[6]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 1 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/agc_lock_change]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 1 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/agc_lock_state]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
set_property port_width 1 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/rx_iq_valid]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets u_ila_0_clk_out2]
