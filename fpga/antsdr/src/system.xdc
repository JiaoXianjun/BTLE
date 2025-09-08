# Author: Xianjun Jiao
# SPDX-FileCopyrightText: 2025 Xianjun Jiao <putaoshu@msn.com>
# SPDX-License-Identifier: Apache-2.0

# ila (might be auto upated by vivado)



create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 8192 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list i_system_wrapper/system_i/clk_wiz_0/inst/clk_out1]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 3 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/reg_gpio[0]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/reg_gpio[1]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/reg_gpio[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 32 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event1_counter[0]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event1_counter[1]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event1_counter[2]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event1_counter[3]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event1_counter[4]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event1_counter[5]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event1_counter[6]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event1_counter[7]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event1_counter[8]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event1_counter[9]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event1_counter[10]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event1_counter[11]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event1_counter[12]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event1_counter[13]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event1_counter[14]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event1_counter[15]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event1_counter[16]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event1_counter[17]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event1_counter[18]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event1_counter[19]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event1_counter[20]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event1_counter[21]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event1_counter[22]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event1_counter[23]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event1_counter[24]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event1_counter[25]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event1_counter[26]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event1_counter[27]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event1_counter[28]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event1_counter[29]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event1_counter[30]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event1_counter[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 32 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event0_counter[0]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event0_counter[1]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event0_counter[2]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event0_counter[3]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event0_counter[4]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event0_counter[5]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event0_counter[6]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event0_counter[7]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event0_counter[8]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event0_counter[9]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event0_counter[10]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event0_counter[11]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event0_counter[12]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event0_counter[13]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event0_counter[14]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event0_counter[15]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event0_counter[16]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event0_counter[17]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event0_counter[18]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event0_counter[19]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event0_counter[20]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event0_counter[21]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event0_counter[22]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event0_counter[23]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event0_counter[24]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event0_counter[25]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event0_counter[26]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event0_counter[27]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event0_counter[28]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event0_counter[29]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event0_counter[30]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event0_counter[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe3]
set_property port_width 16 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/rx_q_signal[0]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_q_signal[1]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_q_signal[2]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_q_signal[3]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_q_signal[4]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_q_signal[5]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_q_signal[6]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_q_signal[7]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_q_signal[8]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_q_signal[9]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_q_signal[10]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_q_signal[11]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_q_signal[12]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_q_signal[13]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_q_signal[14]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_q_signal[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe4]
set_property port_width 16 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/rx_i_signal[0]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_i_signal[1]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_i_signal[2]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_i_signal[3]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_i_signal[4]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_i_signal[5]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_i_signal[6]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_i_signal[7]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_i_signal[8]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_i_signal[9]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_i_signal[10]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_i_signal[11]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_i_signal[12]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_i_signal[13]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_i_signal[14]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_i_signal[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 7 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/ext_rx_payload_length[0]} {i_system_wrapper/system_i/btle_controller_0/inst/ext_rx_payload_length[1]} {i_system_wrapper/system_i/btle_controller_0/inst/ext_rx_payload_length[2]} {i_system_wrapper/system_i/btle_controller_0/inst/ext_rx_payload_length[3]} {i_system_wrapper/system_i/btle_controller_0/inst/ext_rx_payload_length[4]} {i_system_wrapper/system_i/btle_controller_0/inst/ext_rx_payload_length[5]} {i_system_wrapper/system_i/btle_controller_0/inst/ext_rx_payload_length[6]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 3 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/ext_rx_best_phase[0]} {i_system_wrapper/system_i/btle_controller_0/inst/ext_rx_best_phase[1]} {i_system_wrapper/system_i/btle_controller_0/inst/ext_rx_best_phase[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 7 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/payload_length_internal[4][0]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/payload_length_internal[4][1]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/payload_length_internal[4][2]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/payload_length_internal[4][3]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/payload_length_internal[4][4]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/payload_length_internal[4][5]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/payload_length_internal[4][6]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
set_property port_width 7 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/payload_length_internal[0][0]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/payload_length_internal[0][1]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/payload_length_internal[0][2]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/payload_length_internal[0][3]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/payload_length_internal[0][4]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/payload_length_internal[0][5]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/payload_length_internal[0][6]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
set_property port_width 2 [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_valid[0]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_valid[4]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
set_property port_width 8 [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_internal[4][0]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_internal[4][1]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_internal[4][2]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_internal[4][3]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_internal[4][4]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_internal[4][5]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_internal[4][6]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_internal[4][7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe11]
set_property port_width 8 [get_debug_ports u_ila_0/probe11]
connect_debug_port u_ila_0/probe11 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_internal[0][0]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_internal[0][1]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_internal[0][2]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_internal[0][3]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_internal[0][4]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_internal[0][5]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_internal[0][6]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_internal[0][7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe12]
set_property port_width 1 [get_debug_ports u_ila_0/probe12]
connect_debug_port u_ila_0/probe12 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_crc_ok_capture_by_decode_end]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe13]
set_property port_width 1 [get_debug_ports u_ila_0/probe13]
connect_debug_port u_ila_0/probe13 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/decode_end_early]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe14]
set_property port_width 1 [get_debug_ports u_ila_0/probe14]
connect_debug_port u_ila_0/probe14 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/decode_end_any]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe15]
set_property port_width 1 [get_debug_ports u_ila_0/probe15]
connect_debug_port u_ila_0/probe15 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/decode_end_all]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe16]
set_property port_width 1 [get_debug_ports u_ila_0/probe16]
connect_debug_port u_ila_0/probe16 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/decode_restart]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe17]
set_property port_width 1 [get_debug_ports u_ila_0/probe17]
connect_debug_port u_ila_0/probe17 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/decode_end_state]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe18]
set_property port_width 1 [get_debug_ports u_ila_0/probe18]
connect_debug_port u_ila_0/probe18 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/ext_rx_decode_run]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe19]
set_property port_width 1 [get_debug_ports u_ila_0/probe19]
connect_debug_port u_ila_0/probe19 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/ext_rx_hit_flag]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe20]
set_property port_width 1 [get_debug_ports u_ila_0/probe20]
connect_debug_port u_ila_0/probe20 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/ext_rx_decode_end]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe21]
set_property port_width 1 [get_debug_ports u_ila_0/probe21]
connect_debug_port u_ila_0/probe21 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/ext_rx_crc_ok]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe22]
set_property port_width 1 [get_debug_ports u_ila_0/probe22]
connect_debug_port u_ila_0/probe22 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/rx_iq_valid]]
create_debug_core u_ila_1 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_1]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_1]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_1]
set_property C_DATA_DEPTH 8192 [get_debug_cores u_ila_1]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_1]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_1]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_1]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_1]
set_property port_width 1 [get_debug_ports u_ila_1/clk]
connect_debug_port u_ila_1/clk [get_nets [list i_system_wrapper/system_i/sys_ps7/inst/FCLK_CLK0]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe0]
set_property port_width 8 [get_debug_ports u_ila_1/probe0]
connect_debug_port u_ila_1/probe0 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_pdu_octet_mem_data[0]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_pdu_octet_mem_data[1]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_pdu_octet_mem_data[2]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_pdu_octet_mem_data[3]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_pdu_octet_mem_data[4]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_pdu_octet_mem_data[5]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_pdu_octet_mem_data[6]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_pdu_octet_mem_data[7]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe1]
set_property port_width 6 [get_debug_ports u_ila_1/probe1]
connect_debug_port u_ila_1/probe1 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_pdu_octet_mem_addr[0]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_pdu_octet_mem_addr[1]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_pdu_octet_mem_addr[2]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_pdu_octet_mem_addr[3]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_pdu_octet_mem_addr[4]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_pdu_octet_mem_addr[5]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe2]
set_property port_width 3 [get_debug_ports u_ila_1/probe2]
connect_debug_port u_ila_1/probe2 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/reg_gpio_axi[0]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/reg_gpio_axi[1]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/reg_gpio_axi[15]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe3]
set_property port_width 5 [get_debug_ports u_ila_1/probe3]
connect_debug_port u_ila_1/probe3 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/axi_awaddr_core[0]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/axi_awaddr_core[1]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/axi_awaddr_core[2]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/axi_awaddr_core[3]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/axi_awaddr_core[4]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe4]
set_property port_width 5 [get_debug_ports u_ila_1/probe4]
connect_debug_port u_ila_1/probe4 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/axi_araddr_core[0]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/axi_araddr_core[1]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/axi_araddr_core[2]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/axi_araddr_core[3]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/axi_araddr_core[4]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe5]
set_property port_width 1 [get_debug_ports u_ila_1/probe5]
connect_debug_port u_ila_1/probe5 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_crc_ok_capture_by_decode_end_axi]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe6]
set_property port_width 1 [get_debug_ports u_ila_1/probe6]
connect_debug_port u_ila_1/probe6 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_decode_run_axi]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe7]
set_property port_width 1 [get_debug_ports u_ila_1/probe7]
connect_debug_port u_ila_1/probe7 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/slv_reg_rden]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe8]
set_property port_width 1 [get_debug_ports u_ila_1/probe8]
connect_debug_port u_ila_1/probe8 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/slv_reg_wren]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets u_ila_1_FCLK_CLK0]
