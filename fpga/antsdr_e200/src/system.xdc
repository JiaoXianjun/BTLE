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

# iic

set_property PACKAGE_PIN L20 [get_ports iic_scl]
set_property IOSTANDARD LVCMOS18 [get_ports iic_scl]
set_property PULLUP true [get_ports iic_scl]
set_property PACKAGE_PIN L19 [get_ports iic_sda]
set_property IOSTANDARD LVCMOS18 [get_ports iic_sda]
set_property PULLUP true [get_ports iic_sda]


set_property  -dict {PACKAGE_PIN  V6   IOSTANDARD  LVCMOS33} [get_ports  dac_sync] ;
set_property  -dict {PACKAGE_PIN  W6   IOSTANDARD  LVCMOS33} [get_ports  dac_sclk] ;
set_property  -dict {PACKAGE_PIN  V10  IOSTANDARD  LVCMOS33} [get_ports  dac_din]  ;
set_property  -dict {PACKAGE_PIN  V11  IOSTANDARD  LVCMOS33} [get_ports  pps_in]  ;
set_property  -dict {PACKAGE_PIN  M20  IOSTANDARD  LVCMOS33} [get_ports  clkin_10m_req]  ;
set_property  -dict {PACKAGE_PIN  J18  IOSTANDARD  LVCMOS33} [get_ports  clkin_10m]  ;

set_property -dict {PACKAGE_PIN N16 IOSTANDARD LVCMOS18} [get_ports gpio_clksel]




set_property -dict {PACKAGE_PIN C20 IOSTANDARD LVCMOS18} [get_ports {rgmii_td[3]}]
set_property -dict {PACKAGE_PIN D19 IOSTANDARD LVCMOS18} [get_ports {rgmii_td[2]}]
set_property -dict {PACKAGE_PIN D20 IOSTANDARD LVCMOS18} [get_ports {rgmii_td[1]}]
set_property -dict {PACKAGE_PIN F19 IOSTANDARD LVCMOS18} [get_ports {rgmii_td[0]}]
set_property -dict {PACKAGE_PIN E18 IOSTANDARD LVCMOS18} [get_ports {rgmii_rd[3]}]
set_property -dict {PACKAGE_PIN E19 IOSTANDARD LVCMOS18} [get_ports {rgmii_rd[2]}]
set_property -dict {PACKAGE_PIN E17 IOSTANDARD LVCMOS18} [get_ports {rgmii_rd[1]}]
set_property -dict {PACKAGE_PIN F16 IOSTANDARD LVCMOS18} [get_ports {rgmii_rd[0]}]

set_property -dict {PACKAGE_PIN F20 IOSTANDARD LVCMOS18} [get_ports rgmii_tx_ctl]
set_property -dict {PACKAGE_PIN D18 IOSTANDARD LVCMOS18} [get_ports rgmii_txc]
set_property -dict {PACKAGE_PIN G17 IOSTANDARD LVCMOS18} [get_ports rgmii_rx_ctl]
set_property -dict {PACKAGE_PIN H16 IOSTANDARD LVCMOS18} [get_ports rgmii_rxc]
set_property -dict {PACKAGE_PIN B19 IOSTANDARD LVCMOS18} [get_ports phy_rst_n]
set_property -dict {PACKAGE_PIN A20 IOSTANDARD LVCMOS18} [get_ports mdio_phy_mdio_io]
set_property -dict {PACKAGE_PIN B20 IOSTANDARD LVCMOS18} [get_ports mdio_phy_mdc]

set_property -dict {PACKAGE_PIN G15 IOSTANDARD LVCMOS18} [get_ports tx_amp_en]


set_property -dict {PACKAGE_PIN T15 IOSTANDARD LVCMOS25} [get_ports {gpio_status[7]}]
set_property -dict {PACKAGE_PIN K16 IOSTANDARD LVCMOS18} [get_ports {gpio_status[6]}]
set_property -dict {PACKAGE_PIN P14 IOSTANDARD LVCMOS25} [get_ports {gpio_status[5]}]
set_property -dict {PACKAGE_PIN P15 IOSTANDARD LVCMOS25} [get_ports {gpio_status[4]}]
set_property -dict {PACKAGE_PIN R14 IOSTANDARD LVCMOS25} [get_ports {gpio_status[3]}]
set_property -dict {PACKAGE_PIN J16 IOSTANDARD LVCMOS18} [get_ports {gpio_status[2]}]
set_property -dict {PACKAGE_PIN J15 IOSTANDARD LVCMOS18} [get_ports {gpio_status[1]}]
set_property -dict {PACKAGE_PIN T10 IOSTANDARD LVCMOS25} [get_ports {gpio_status[0]}]
set_property -dict {PACKAGE_PIN T11 IOSTANDARD LVCMOS25} [get_ports {gpio_ctl[3]}]
set_property -dict {PACKAGE_PIN V13 IOSTANDARD LVCMOS25} [get_ports {gpio_ctl[2]}]
set_property -dict {PACKAGE_PIN T14 IOSTANDARD LVCMOS25} [get_ports {gpio_ctl[1]}]
set_property -dict {PACKAGE_PIN U13 IOSTANDARD LVCMOS25} [get_ports {gpio_ctl[0]}]
set_property -dict {PACKAGE_PIN P16 IOSTANDARD LVCMOS25} [get_ports gpio_en_agc]
set_property -dict {PACKAGE_PIN U20 IOSTANDARD LVCMOS25} [get_ports gpio_sync]
set_property -dict {PACKAGE_PIN T17 IOSTANDARD LVCMOS25} [get_ports gpio_resetb]
set_property -dict {PACKAGE_PIN R18 IOSTANDARD LVCMOS25} [get_ports enable]
set_property -dict {PACKAGE_PIN N17 IOSTANDARD LVCMOS25} [get_ports txnrx]

set_property PACKAGE_PIN T20 [get_ports spi_csn]
set_property IOSTANDARD LVCMOS25 [get_ports spi_csn]
set_property PULLUP true [get_ports spi_csn]
set_property -dict {PACKAGE_PIN R19 IOSTANDARD LVCMOS25} [get_ports spi_clk]
set_property -dict {PACKAGE_PIN P18 IOSTANDARD LVCMOS25} [get_ports spi_mosi]
set_property -dict {PACKAGE_PIN T19 IOSTANDARD LVCMOS25} [get_ports spi_miso]





# constraints (pzsdr2.e)
# ad9361

set_property -dict {PACKAGE_PIN N20 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports rx_clk_in_p]
set_property -dict {PACKAGE_PIN P20 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports rx_clk_in_n]
set_property -dict {PACKAGE_PIN Y16 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports rx_frame_in_p]
set_property -dict {PACKAGE_PIN Y17 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports rx_frame_in_n]
set_property -dict {PACKAGE_PIN W14 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports {rx_data_in_p[5]}]
set_property -dict {PACKAGE_PIN Y14 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports {rx_data_in_n[5]}]
set_property -dict {PACKAGE_PIN V20 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports {rx_data_in_p[4]}]
set_property -dict {PACKAGE_PIN W20 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports {rx_data_in_n[4]}]
set_property -dict {PACKAGE_PIN R16 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports {rx_data_in_p[3]}]
set_property -dict {PACKAGE_PIN R17 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports {rx_data_in_n[3]}]
set_property -dict {PACKAGE_PIN W18 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports {rx_data_in_p[2]}]
set_property -dict {PACKAGE_PIN W19 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports {rx_data_in_n[2]}]
set_property -dict {PACKAGE_PIN V17 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports {rx_data_in_p[1]}]
set_property -dict {PACKAGE_PIN V18 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports {rx_data_in_n[1]}]
set_property -dict {PACKAGE_PIN Y18 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports {rx_data_in_p[0]}]
set_property -dict {PACKAGE_PIN Y19 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports {rx_data_in_n[0]}]
set_property -dict {PACKAGE_PIN N18 IOSTANDARD LVDS_25} [get_ports tx_clk_out_p]
set_property -dict {PACKAGE_PIN P19 IOSTANDARD LVDS_25} [get_ports tx_clk_out_n]
set_property -dict {PACKAGE_PIN V16 IOSTANDARD LVDS_25} [get_ports tx_frame_out_p]
set_property -dict {PACKAGE_PIN W16 IOSTANDARD LVDS_25} [get_ports tx_frame_out_n]
set_property -dict {PACKAGE_PIN V15 IOSTANDARD LVDS_25} [get_ports {tx_data_out_p[5]}]
set_property -dict {PACKAGE_PIN W15 IOSTANDARD LVDS_25} [get_ports {tx_data_out_n[5]}]
set_property -dict {PACKAGE_PIN T12 IOSTANDARD LVDS_25} [get_ports {tx_data_out_p[4]}]
set_property -dict {PACKAGE_PIN U12 IOSTANDARD LVDS_25} [get_ports {tx_data_out_n[4]}]
set_property -dict {PACKAGE_PIN V12 IOSTANDARD LVDS_25} [get_ports {tx_data_out_p[3]}]
set_property -dict {PACKAGE_PIN W13 IOSTANDARD LVDS_25} [get_ports {tx_data_out_n[3]}]
set_property -dict {PACKAGE_PIN U14 IOSTANDARD LVDS_25} [get_ports {tx_data_out_p[2]}]
set_property -dict {PACKAGE_PIN U15 IOSTANDARD LVDS_25} [get_ports {tx_data_out_n[2]}]
set_property -dict {PACKAGE_PIN U18 IOSTANDARD LVDS_25} [get_ports {tx_data_out_p[1]}]
set_property -dict {PACKAGE_PIN U19 IOSTANDARD LVDS_25} [get_ports {tx_data_out_n[1]}]
set_property -dict {PACKAGE_PIN T16 IOSTANDARD LVDS_25} [get_ports {tx_data_out_p[0]}]
set_property -dict {PACKAGE_PIN U17 IOSTANDARD LVDS_25} [get_ports {tx_data_out_n[0]}]

# clocks

create_clock -period 4.000 -name rx_clk [get_ports rx_clk_in_p]


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
set_property port_width 7 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/rf_gain[0]} {i_system_wrapper/system_i/btle_controller_0/inst/rf_gain[1]} {i_system_wrapper/system_i/btle_controller_0/inst/rf_gain[2]} {i_system_wrapper/system_i/btle_controller_0/inst/rf_gain[3]} {i_system_wrapper/system_i/btle_controller_0/inst/rf_gain[4]} {i_system_wrapper/system_i/btle_controller_0/inst/rf_gain[5]} {i_system_wrapper/system_i/btle_controller_0/inst/rf_gain[6]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 3 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/ext_rx_best_phase[0]} {i_system_wrapper/system_i/btle_controller_0/inst/ext_rx_best_phase[1]} {i_system_wrapper/system_i/btle_controller_0/inst/ext_rx_best_phase[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 7 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/ext_rx_payload_length[0]} {i_system_wrapper/system_i/btle_controller_0/inst/ext_rx_payload_length[1]} {i_system_wrapper/system_i/btle_controller_0/inst/ext_rx_payload_length[2]} {i_system_wrapper/system_i/btle_controller_0/inst/ext_rx_payload_length[3]} {i_system_wrapper/system_i/btle_controller_0/inst/ext_rx_payload_length[4]} {i_system_wrapper/system_i/btle_controller_0/inst/ext_rx_payload_length[5]} {i_system_wrapper/system_i/btle_controller_0/inst/ext_rx_payload_length[6]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 16 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/auxiliary_daemon_i/rx_q_signal[0]} {i_system_wrapper/system_i/btle_controller_0/inst/auxiliary_daemon_i/rx_q_signal[1]} {i_system_wrapper/system_i/btle_controller_0/inst/auxiliary_daemon_i/rx_q_signal[2]} {i_system_wrapper/system_i/btle_controller_0/inst/auxiliary_daemon_i/rx_q_signal[3]} {i_system_wrapper/system_i/btle_controller_0/inst/auxiliary_daemon_i/rx_q_signal[4]} {i_system_wrapper/system_i/btle_controller_0/inst/auxiliary_daemon_i/rx_q_signal[5]} {i_system_wrapper/system_i/btle_controller_0/inst/auxiliary_daemon_i/rx_q_signal[6]} {i_system_wrapper/system_i/btle_controller_0/inst/auxiliary_daemon_i/rx_q_signal[7]} {i_system_wrapper/system_i/btle_controller_0/inst/auxiliary_daemon_i/rx_q_signal[8]} {i_system_wrapper/system_i/btle_controller_0/inst/auxiliary_daemon_i/rx_q_signal[9]} {i_system_wrapper/system_i/btle_controller_0/inst/auxiliary_daemon_i/rx_q_signal[10]} {i_system_wrapper/system_i/btle_controller_0/inst/auxiliary_daemon_i/rx_q_signal[11]} {i_system_wrapper/system_i/btle_controller_0/inst/auxiliary_daemon_i/rx_q_signal[12]} {i_system_wrapper/system_i/btle_controller_0/inst/auxiliary_daemon_i/rx_q_signal[13]} {i_system_wrapper/system_i/btle_controller_0/inst/auxiliary_daemon_i/rx_q_signal[14]} {i_system_wrapper/system_i/btle_controller_0/inst/auxiliary_daemon_i/rx_q_signal[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 16 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/auxiliary_daemon_i/rx_i_signal[0]} {i_system_wrapper/system_i/btle_controller_0/inst/auxiliary_daemon_i/rx_i_signal[1]} {i_system_wrapper/system_i/btle_controller_0/inst/auxiliary_daemon_i/rx_i_signal[2]} {i_system_wrapper/system_i/btle_controller_0/inst/auxiliary_daemon_i/rx_i_signal[3]} {i_system_wrapper/system_i/btle_controller_0/inst/auxiliary_daemon_i/rx_i_signal[4]} {i_system_wrapper/system_i/btle_controller_0/inst/auxiliary_daemon_i/rx_i_signal[5]} {i_system_wrapper/system_i/btle_controller_0/inst/auxiliary_daemon_i/rx_i_signal[6]} {i_system_wrapper/system_i/btle_controller_0/inst/auxiliary_daemon_i/rx_i_signal[7]} {i_system_wrapper/system_i/btle_controller_0/inst/auxiliary_daemon_i/rx_i_signal[8]} {i_system_wrapper/system_i/btle_controller_0/inst/auxiliary_daemon_i/rx_i_signal[9]} {i_system_wrapper/system_i/btle_controller_0/inst/auxiliary_daemon_i/rx_i_signal[10]} {i_system_wrapper/system_i/btle_controller_0/inst/auxiliary_daemon_i/rx_i_signal[11]} {i_system_wrapper/system_i/btle_controller_0/inst/auxiliary_daemon_i/rx_i_signal[12]} {i_system_wrapper/system_i/btle_controller_0/inst/auxiliary_daemon_i/rx_i_signal[13]} {i_system_wrapper/system_i/btle_controller_0/inst/auxiliary_daemon_i/rx_i_signal[14]} {i_system_wrapper/system_i/btle_controller_0/inst/auxiliary_daemon_i/rx_i_signal[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 1 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/ext_rx_hit_flag]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 1 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/ext_rx_decode_run]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 1 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/ext_rx_decode_end]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
set_property port_width 1 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/ext_rx_crc_ok]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
set_property port_width 1 [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/auxiliary_daemon_i/agc_lock_change]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
set_property port_width 1 [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/agc_lock_state]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe11]
set_property port_width 1 [get_debug_ports u_ila_0/probe11]
connect_debug_port u_ila_0/probe11 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/rx_iq_valid]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets u_ila_0_clk_out1]
