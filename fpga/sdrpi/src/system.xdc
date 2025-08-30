# Author: Xianjun Jiao
# SPDX-FileCopyrightText: 2025 Xianjun Jiao <putaoshu@msn.com>
# SPDX-License-Identifier: Apache-2.0

set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins i_system_wrapper/system_i/util_ad9361_divclk/inst/clk_divide_sel_0/O]] -group [get_clocks -of_objects [get_pins i_system_wrapper/system_i/clk_wiz_0/inst/mmcm_adv_inst/CLKOUT0]]

set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins i_system_wrapper/system_i/util_ad9361_divclk/inst/clk_divide_sel_1/O]] -group [get_clocks -of_objects [get_pins i_system_wrapper/system_i/clk_wiz_0/inst/mmcm_adv_inst/CLKOUT0]]

set_clock_groups -asynchronous -group [get_clocks clk_fpga_0] -group [get_clocks -of_objects [get_pins i_system_wrapper/system_i/clk_wiz_0/inst/mmcm_adv_inst/CLKOUT0]]

# rx iq
set_max_delay -datapath_only -from [get_pins {i_system_wrapper/system_i/util_ad9361_adc_pack/inst/i_cpack/packed_fifo_wr_data_reg[*]/C}] -to [get_pins {i_system_wrapper/system_i/btle_controller_0/inst/clock_domain_conversion_iq_i/rx_i_signal_reg[*]/D}] 10.000
set_max_delay -datapath_only -from [get_pins {i_system_wrapper/system_i/util_ad9361_adc_pack/inst/i_cpack/packed_fifo_wr_data_reg[*]/C}] -to [get_pins {i_system_wrapper/system_i/btle_controller_0/inst/clock_domain_conversion_iq_i/rx_q_signal_reg[*]/D}] 10.000

# tx iq
set_max_delay -datapath_only -from [get_pins {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/gfsk_modulation_i/vco_i/sin_table_sdpram_one_clk_i/read_data_reg[*]/C}] -to [get_pins {i_system_wrapper/system_i/btle_controller_0/inst/clock_domain_conversion_iq_i/tx_iq_signal_ext_reg[*]/D}] 10.000
set_max_delay -datapath_only -from [get_pins {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/gfsk_modulation_i/vco_i/cos_table_sdpram_one_clk_i/read_data_reg[*]/C}] -to [get_pins {i_system_wrapper/system_i/btle_controller_0/inst/clock_domain_conversion_iq_i/tx_iq_signal_ext_reg[*]/D}] 10.000
set_max_delay -datapath_only -from [get_pins i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/gfsk_modulation_i/vco_i/sin_cos_out_valid_reg/C] -to [get_pins i_system_wrapper/system_i/btle_controller_0/inst/clock_domain_conversion_iq_i/tx_iq_valid_ext_reg/D] 10.000
set_max_delay -datapath_only -from [get_pins {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/FSM_sequential_phy_tx_state_reg[*]/C}] -to [get_pins {i_system_wrapper/system_i/btle_controller_0/inst/clock_domain_conversion_iq_i/tx_iq_signal_ext_reg[*]/D}] 10.000

# bb to axi for host read bb status
set_false_path -through [get_pins {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/genblk1[0].serial_in_ram_out_i/serial_in_ram_out_sdpram_two_clk_i/read_data_reg[*]/C}]
set_false_path -through [get_pins {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/genblk1[1].serial_in_ram_out_i/serial_in_ram_out_sdpram_two_clk_i/read_data_reg[*]/C}]
set_false_path -through [get_pins {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/genblk1[2].serial_in_ram_out_i/serial_in_ram_out_sdpram_two_clk_i/read_data_reg[*]/C}]
set_false_path -through [get_pins {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/genblk1[3].serial_in_ram_out_i/serial_in_ram_out_sdpram_two_clk_i/read_data_reg[*]/C}]
set_false_path -through [get_pins {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/genblk1[4].serial_in_ram_out_i/serial_in_ram_out_sdpram_two_clk_i/read_data_reg[*]/C}]
set_false_path -through [get_pins {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/genblk1[5].serial_in_ram_out_i/serial_in_ram_out_sdpram_two_clk_i/read_data_reg[*]/C}]
set_false_path -through [get_pins {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/genblk1[6].serial_in_ram_out_i/serial_in_ram_out_sdpram_two_clk_i/read_data_reg[*]/C}]
set_false_path -through [get_pins {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/genblk1[7].serial_in_ram_out_i/serial_in_ram_out_sdpram_two_clk_i/read_data_reg[*]/C}]

set_false_path -through [get_pins {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/genblk1[0].serial_in_ram_out_i/serial_in_ram_out_sdpram_two_clk_i/read_data_reg[*]/D}]
set_false_path -through [get_pins {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/genblk1[1].serial_in_ram_out_i/serial_in_ram_out_sdpram_two_clk_i/read_data_reg[*]/D}]
set_false_path -through [get_pins {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/genblk1[2].serial_in_ram_out_i/serial_in_ram_out_sdpram_two_clk_i/read_data_reg[*]/D}]
set_false_path -through [get_pins {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/genblk1[3].serial_in_ram_out_i/serial_in_ram_out_sdpram_two_clk_i/read_data_reg[*]/D}]
set_false_path -through [get_pins {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/genblk1[4].serial_in_ram_out_i/serial_in_ram_out_sdpram_two_clk_i/read_data_reg[*]/D}]
set_false_path -through [get_pins {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/genblk1[5].serial_in_ram_out_i/serial_in_ram_out_sdpram_two_clk_i/read_data_reg[*]/D}]
set_false_path -through [get_pins {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/genblk1[6].serial_in_ram_out_i/serial_in_ram_out_sdpram_two_clk_i/read_data_reg[*]/D}]
set_false_path -through [get_pins {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/genblk1[7].serial_in_ram_out_i/serial_in_ram_out_sdpram_two_clk_i/read_data_reg[*]/D}]

set_false_path -through [get_pins {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/sdpram_two_clk_bb_to_s_axi_i/read_data_reg[*]/D}]

# # axi to bb for host configure bb
set_false_path -through [get_pins {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/sdpram_two_clk_s_axi_to_bb_i/read_data_reg[*]/C}]
set_false_path -through [get_pins {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/sdpram_two_clk_s_axi_to_bb_i/read_data_reg[*]/D}]

set_false_path -through [get_pins {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/btle_tx_sdpram_two_clk_i/read_data_reg[*]/D}]















connect_debug_port dbg_hub/clk [get_nets u_ila_0_clk_out1]




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
connect_debug_port u_ila_0/clk [get_nets [list i_system_wrapper/system_i/sys_ps7/inst/FCLK_CLK0]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 8 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/ext_rx_pdu_octet_mem_data[0]} {i_system_wrapper/system_i/btle_controller_0/inst/ext_rx_pdu_octet_mem_data[1]} {i_system_wrapper/system_i/btle_controller_0/inst/ext_rx_pdu_octet_mem_data[2]} {i_system_wrapper/system_i/btle_controller_0/inst/ext_rx_pdu_octet_mem_data[3]} {i_system_wrapper/system_i/btle_controller_0/inst/ext_rx_pdu_octet_mem_data[4]} {i_system_wrapper/system_i/btle_controller_0/inst/ext_rx_pdu_octet_mem_data[5]} {i_system_wrapper/system_i/btle_controller_0/inst/ext_rx_pdu_octet_mem_data[6]} {i_system_wrapper/system_i/btle_controller_0/inst/ext_rx_pdu_octet_mem_data[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 6 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/pdu_octet_mem_addr[0]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/pdu_octet_mem_addr[1]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/pdu_octet_mem_addr[2]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/pdu_octet_mem_addr[3]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/pdu_octet_mem_addr[4]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/pdu_octet_mem_addr[5]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 8 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/timestamp_rx_hit_flag_axi[0]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/timestamp_rx_hit_flag_axi[1]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/timestamp_rx_hit_flag_axi[2]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/timestamp_rx_hit_flag_axi[3]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/timestamp_rx_hit_flag_axi[4]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/timestamp_rx_hit_flag_axi[5]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/timestamp_rx_hit_flag_axi[6]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/timestamp_rx_hit_flag_axi[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 7 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_payload_length_axi[0]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_payload_length_axi[1]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_payload_length_axi[2]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_payload_length_axi[3]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_payload_length_axi[4]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_payload_length_axi[5]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_payload_length_axi[6]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 1 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_crc_ok_axi]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 1 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_hit_flag_axi]]
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
connect_debug_port u_ila_1/clk [get_nets [list i_system_wrapper/system_i/clk_wiz_0/inst/clk_out1]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe0]
set_property port_width 16 [get_debug_ports u_ila_1/probe0]
connect_debug_port u_ila_1/probe0 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/rx_q_signal[0]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_q_signal[1]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_q_signal[2]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_q_signal[3]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_q_signal[4]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_q_signal[5]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_q_signal[6]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_q_signal[7]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_q_signal[8]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_q_signal[9]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_q_signal[10]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_q_signal[11]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_q_signal[12]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_q_signal[13]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_q_signal[14]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_q_signal[15]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe1]
set_property port_width 16 [get_debug_ports u_ila_1/probe1]
connect_debug_port u_ila_1/probe1 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/rx_i_signal[0]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_i_signal[1]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_i_signal[2]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_i_signal[3]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_i_signal[4]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_i_signal[5]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_i_signal[6]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_i_signal[7]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_i_signal[8]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_i_signal[9]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_i_signal[10]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_i_signal[11]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_i_signal[12]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_i_signal[13]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_i_signal[14]} {i_system_wrapper/system_i/btle_controller_0/inst/rx_i_signal[15]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe2]
set_property port_width 7 [get_debug_ports u_ila_1/probe2]
connect_debug_port u_ila_1/probe2 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/rf_gain[0]} {i_system_wrapper/system_i/btle_controller_0/inst/rf_gain[1]} {i_system_wrapper/system_i/btle_controller_0/inst/rf_gain[2]} {i_system_wrapper/system_i/btle_controller_0/inst/rf_gain[3]} {i_system_wrapper/system_i/btle_controller_0/inst/rf_gain[4]} {i_system_wrapper/system_i/btle_controller_0/inst/rf_gain[5]} {i_system_wrapper/system_i/btle_controller_0/inst/rf_gain[6]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe3]
set_property port_width 7 [get_debug_ports u_ila_1/probe3]
connect_debug_port u_ila_1/probe3 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/rx_payload_length[0]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/rx_payload_length[1]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/rx_payload_length[2]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/rx_payload_length[3]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/rx_payload_length[4]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/rx_payload_length[5]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/rx_payload_length[6]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe4]
set_property port_width 3 [get_debug_ports u_ila_1/probe4]
connect_debug_port u_ila_1/probe4 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/rx_best_phase[0]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/rx_best_phase[1]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/rx_best_phase[2]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe5]
set_property port_width 8 [get_debug_ports u_ila_1/probe5]
connect_debug_port u_ila_1/probe5 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_internal[3][0]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_internal[3][1]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_internal[3][2]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_internal[3][3]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_internal[3][4]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_internal[3][5]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_internal[3][6]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_internal[3][7]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe6]
set_property port_width 8 [get_debug_ports u_ila_1/probe6]
connect_debug_port u_ila_1/probe6 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_internal[2][0]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_internal[2][1]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_internal[2][2]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_internal[2][3]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_internal[2][4]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_internal[2][5]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_internal[2][6]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_internal[2][7]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe7]
set_property port_width 8 [get_debug_ports u_ila_1/probe7]
connect_debug_port u_ila_1/probe7 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_internal[1][0]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_internal[1][1]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_internal[1][2]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_internal[1][3]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_internal[1][4]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_internal[1][5]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_internal[1][6]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_internal[1][7]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe8]
set_property port_width 8 [get_debug_ports u_ila_1/probe8]
connect_debug_port u_ila_1/probe8 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_internal[0][0]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_internal[0][1]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_internal[0][2]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_internal[0][3]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_internal[0][4]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_internal[0][5]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_internal[0][6]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_internal[0][7]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe9]
set_property port_width 8 [get_debug_ports u_ila_1/probe9]
connect_debug_port u_ila_1/probe9 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/timestamp_rx_hit_flag[0]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/timestamp_rx_hit_flag[1]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/timestamp_rx_hit_flag[2]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/timestamp_rx_hit_flag[3]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/timestamp_rx_hit_flag[4]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/timestamp_rx_hit_flag[5]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/timestamp_rx_hit_flag[6]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/timestamp_rx_hit_flag[7]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe10]
set_property port_width 8 [get_debug_ports u_ila_1/probe10]
connect_debug_port u_ila_1/probe10 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/timestamp[0]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/timestamp[1]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/timestamp[2]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/timestamp[3]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/timestamp[4]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/timestamp[5]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/timestamp[6]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/timestamp[7]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe11]
set_property port_width 4 [get_debug_ports u_ila_1/probe11]
connect_debug_port u_ila_1/probe11 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event1_counter[0]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event1_counter[1]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event1_counter[2]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event1_counter[3]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe12]
set_property port_width 4 [get_debug_ports u_ila_1/probe12]
connect_debug_port u_ila_1/probe12 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event0_counter[0]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event0_counter[1]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event0_counter[2]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event0_counter[3]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe13]
set_property port_width 1 [get_debug_ports u_ila_1/probe13]
connect_debug_port u_ila_1/probe13 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/agc_lock_state]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe14]
set_property port_width 1 [get_debug_ports u_ila_1/probe14]
connect_debug_port u_ila_1/probe14 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/decode_end_all]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe15]
set_property port_width 1 [get_debug_ports u_ila_1/probe15]
connect_debug_port u_ila_1/probe15 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/decode_end_early]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe16]
set_property port_width 1 [get_debug_ports u_ila_1/probe16]
connect_debug_port u_ila_1/probe16 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/decode_end_state]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe17]
set_property port_width 1 [get_debug_ports u_ila_1/probe17]
connect_debug_port u_ila_1/probe17 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/decode_restart]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe18]
set_property port_width 1 [get_debug_ports u_ila_1/probe18]
connect_debug_port u_ila_1/probe18 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_valid_0]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe19]
set_property port_width 1 [get_debug_ports u_ila_1/probe19]
connect_debug_port u_ila_1/probe19 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_valid_1]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe20]
set_property port_width 1 [get_debug_ports u_ila_1/probe20]
connect_debug_port u_ila_1/probe20 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_valid_2]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe21]
set_property port_width 1 [get_debug_ports u_ila_1/probe21]
connect_debug_port u_ila_1/probe21 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/octet_valid_3]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe22]
set_property port_width 1 [get_debug_ports u_ila_1/probe22]
connect_debug_port u_ila_1/probe22 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/rx_crc_ok]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe23]
set_property port_width 1 [get_debug_ports u_ila_1/probe23]
connect_debug_port u_ila_1/probe23 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/rx_decode_end]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe24]
set_property port_width 1 [get_debug_ports u_ila_1/probe24]
connect_debug_port u_ila_1/probe24 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/rx_decode_run]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe25]
set_property port_width 1 [get_debug_ports u_ila_1/probe25]
connect_debug_port u_ila_1/probe25 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/rx_hit_flag]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe26]
set_property port_width 1 [get_debug_ports u_ila_1/probe26]
connect_debug_port u_ila_1/probe26 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/rx_iq_valid]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk]
