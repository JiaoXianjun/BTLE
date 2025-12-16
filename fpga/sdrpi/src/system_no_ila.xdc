# Author: Xianjun Jiao
# SPDX-FileCopyrightText: 2025 Xianjun Jiao <putaoshu@msn.com>
# SPDX-License-Identifier: Apache-2.0

#set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins i_system_wrapper/system_i/util_ad9361_divclk/inst/clk_divide_sel_0/O]] -group [get_clocks -of_objects [get_pins i_system_wrapper/system_i/clk_wiz_0/inst/mmcm_adv_inst/CLKOUT0]]

#set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins i_system_wrapper/system_i/util_ad9361_divclk/inst/clk_divide_sel_1/O]] -group [get_clocks -of_objects [get_pins i_system_wrapper/system_i/clk_wiz_0/inst/mmcm_adv_inst/CLKOUT0]]

set_clock_groups -asynchronous -group [get_clocks clk_fpga_0] -group [get_clocks -of_objects [get_pins i_system_wrapper/system_i/clk_wiz_1/inst/mmcm_adv_inst/CLKOUT1]]

## rx iq
#set_max_delay -datapath_only -from [get_pins {i_system_wrapper/system_i/util_ad9361_adc_pack/inst/i_cpack/packed_fifo_wr_data_reg[*]/C}] -to [get_pins {i_system_wrapper/system_i/btle_controller_0/inst/clock_domain_conversion_iq_i/rx_i_signal_reg[*]/D}] 10.000
#set_max_delay -datapath_only -from [get_pins {i_system_wrapper/system_i/util_ad9361_adc_pack/inst/i_cpack/packed_fifo_wr_data_reg[*]/C}] -to [get_pins {i_system_wrapper/system_i/btle_controller_0/inst/clock_domain_conversion_iq_i/rx_q_signal_reg[*]/D}] 10.000

## tx iq
#set_max_delay -datapath_only -from [get_pins {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/gfsk_modulation_i/vco_i/sin_table_sdpram_one_clk_i/read_data_reg[*]/C}] -to [get_pins {i_system_wrapper/system_i/btle_controller_0/inst/clock_domain_conversion_iq_i/tx_iq_signal_ext_reg[*]/D}] 10.000
#set_max_delay -datapath_only -from [get_pins {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/gfsk_modulation_i/vco_i/cos_table_sdpram_one_clk_i/read_data_reg[*]/C}] -to [get_pins {i_system_wrapper/system_i/btle_controller_0/inst/clock_domain_conversion_iq_i/tx_iq_signal_ext_reg[*]/D}] 10.000
#set_max_delay -datapath_only -from [get_pins i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/gfsk_modulation_i/vco_i/sin_cos_out_valid_reg/C] -to [get_pins i_system_wrapper/system_i/btle_controller_0/inst/clock_domain_conversion_iq_i/tx_iq_valid_ext_reg/D] 10.000
#set_max_delay -datapath_only -from [get_pins {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/FSM_sequential_phy_tx_state_reg[*]/C}] -to [get_pins {i_system_wrapper/system_i/btle_controller_0/inst/clock_domain_conversion_iq_i/tx_iq_signal_ext_reg[*]/D}] 10.000

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


# # axi to bb for host configure bb

set_false_path -through [get_pins {i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_tx_i/btle_tx_sdpram_two_clk_i/read_data_reg[*]/D}]

# ports connect to P1 in sdrpi board.

#   // gpio_bd[0]  -> P1.gpio1
#   // gpio_bd[1]  -> P1.gpio2
#   // gpio_bd[2]  -> P1.gpio3
#   // ......
#   // gpio_bd[24] -> P1.gpio25
#   // gpio_bd[25] -> P1.gpio26
set_property -dict {PACKAGE_PIN G14 IOSTANDARD LVCMOS25} [get_ports {gpio_bd[0]}]
set_property -dict {PACKAGE_PIN V10 IOSTANDARD LVCMOS25} [get_ports {gpio_bd[1]}]
set_property -dict {PACKAGE_PIN W10 IOSTANDARD LVCMOS25} [get_ports {gpio_bd[2]}]
set_property -dict {PACKAGE_PIN Y9 IOSTANDARD LVCMOS25} [get_ports {gpio_bd[3]}]
set_property -dict {PACKAGE_PIN U9 IOSTANDARD LVCMOS25} [get_ports {gpio_bd[4]}]
set_property -dict {PACKAGE_PIN V8 IOSTANDARD LVCMOS25} [get_ports {gpio_bd[5]}]
set_property -dict {PACKAGE_PIN Y7 IOSTANDARD LVCMOS25} [get_ports {gpio_bd[6]}]
set_property -dict {PACKAGE_PIN Y13 IOSTANDARD LVCMOS25} [get_ports {gpio_bd[7]}]
set_property -dict {PACKAGE_PIN V6 IOSTANDARD LVCMOS25} [get_ports {gpio_bd[8]}]
set_property -dict {PACKAGE_PIN Y12 IOSTANDARD LVCMOS25} [get_ports {gpio_bd[9]}]
set_property -dict {PACKAGE_PIN W11 IOSTANDARD LVCMOS25} [get_ports {gpio_bd[10]}]
set_property -dict {PACKAGE_PIN T9 IOSTANDARD LVCMOS25} [get_ports {gpio_bd[11]}]
set_property -dict {PACKAGE_PIN W9 IOSTANDARD LVCMOS25} [get_ports {gpio_bd[12]}]
set_property -dict {PACKAGE_PIN V7 IOSTANDARD LVCMOS25} [get_ports {gpio_bd[13]}]
set_property -dict {PACKAGE_PIN U10 IOSTANDARD LVCMOS25} [get_ports {gpio_bd[14]}]
set_property -dict {PACKAGE_PIN V11 IOSTANDARD LVCMOS25} [get_ports {gpio_bd[15]}]
set_property -dict {PACKAGE_PIN Y8 IOSTANDARD LVCMOS25} [get_ports {gpio_bd[16]}]
set_property -dict {PACKAGE_PIN Y6 IOSTANDARD LVCMOS25} [get_ports {gpio_bd[17]}]
set_property -dict {PACKAGE_PIN U8 IOSTANDARD LVCMOS25} [get_ports {gpio_bd[18]}]
set_property -dict {PACKAGE_PIN W6 IOSTANDARD LVCMOS25} [get_ports {gpio_bd[19]}]
set_property -dict {PACKAGE_PIN U5 IOSTANDARD LVCMOS25} [get_ports {gpio_bd[20]}]
set_property -dict {PACKAGE_PIN T5 IOSTANDARD LVCMOS25} [get_ports {gpio_bd[21]}]
set_property -dict {PACKAGE_PIN Y11 IOSTANDARD LVCMOS25} [get_ports {gpio_bd[22]}]
set_property -dict {PACKAGE_PIN U7 IOSTANDARD LVCMOS25} [get_ports {gpio_bd[23]}]
set_property -dict {PACKAGE_PIN W8 IOSTANDARD LVCMOS25} [get_ports {gpio_bd[24]}]
set_property -dict {PACKAGE_PIN V5 IOSTANDARD LVCMOS25} [get_ports {gpio_bd[25]}]

## ad9361
set_property -dict {PACKAGE_PIN N20 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports rx_clk_in_p]
set_property -dict {PACKAGE_PIN P20 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports rx_clk_in_n]

set_property -dict {PACKAGE_PIN U18 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports rx_frame_in_p]
set_property -dict {PACKAGE_PIN U19 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports rx_frame_in_n]

set_property -dict {PACKAGE_PIN Y18 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports {rx_data_in_p[0]}]
set_property -dict {PACKAGE_PIN Y19 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports {rx_data_in_n[0]}]

set_property -dict {PACKAGE_PIN V20 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports {rx_data_in_p[1]}]
set_property -dict {PACKAGE_PIN W20 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports {rx_data_in_n[1]}]

set_property -dict {PACKAGE_PIN W18 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports {rx_data_in_p[2]}]
set_property -dict {PACKAGE_PIN W19 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports {rx_data_in_n[2]}]

set_property -dict {PACKAGE_PIN R16 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports {rx_data_in_p[3]}]
set_property -dict {PACKAGE_PIN R17 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports {rx_data_in_n[3]}]

set_property -dict {PACKAGE_PIN V17 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports {rx_data_in_p[4]}]
set_property -dict {PACKAGE_PIN V18 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports {rx_data_in_n[4]}]

set_property -dict {PACKAGE_PIN V16 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports {rx_data_in_p[5]}]
set_property -dict {PACKAGE_PIN W16 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports {rx_data_in_n[5]}]

set_property -dict {PACKAGE_PIN N18 IOSTANDARD LVDS_25} [get_ports tx_clk_out_p]
set_property -dict {PACKAGE_PIN P19 IOSTANDARD LVDS_25} [get_ports tx_clk_out_n]

set_property -dict {PACKAGE_PIN T16 IOSTANDARD LVDS_25} [get_ports tx_frame_out_p]
set_property -dict {PACKAGE_PIN U17 IOSTANDARD LVDS_25} [get_ports tx_frame_out_n]

set_property -dict {PACKAGE_PIN Y16 IOSTANDARD LVDS_25} [get_ports {tx_data_out_p[0]}]
set_property -dict {PACKAGE_PIN Y17 IOSTANDARD LVDS_25} [get_ports {tx_data_out_n[0]}]

set_property -dict {PACKAGE_PIN U14 IOSTANDARD LVDS_25} [get_ports {tx_data_out_p[1]}]
set_property -dict {PACKAGE_PIN U15 IOSTANDARD LVDS_25} [get_ports {tx_data_out_n[1]}]

set_property -dict {PACKAGE_PIN V15 IOSTANDARD LVDS_25} [get_ports {tx_data_out_p[2]}]
set_property -dict {PACKAGE_PIN W15 IOSTANDARD LVDS_25} [get_ports {tx_data_out_n[2]}]

set_property -dict {PACKAGE_PIN W14 IOSTANDARD LVDS_25} [get_ports {tx_data_out_p[3]}]
set_property -dict {PACKAGE_PIN Y14 IOSTANDARD LVDS_25} [get_ports {tx_data_out_n[3]}]

set_property -dict {PACKAGE_PIN V12 IOSTANDARD LVDS_25} [get_ports {tx_data_out_p[4]}]
set_property -dict {PACKAGE_PIN W13 IOSTANDARD LVDS_25} [get_ports {tx_data_out_n[4]}]

set_property -dict {PACKAGE_PIN T12 IOSTANDARD LVDS_25} [get_ports {tx_data_out_p[5]}]
set_property -dict {PACKAGE_PIN U12 IOSTANDARD LVDS_25} [get_ports {tx_data_out_n[5]}]

create_clock -period 8.000 -name rx_clk [get_ports rx_clk_in_p]

## other constrains
set_property -dict {PACKAGE_PIN T11 IOSTANDARD LVCMOS25} [get_ports {gpio_status[0]}]
set_property -dict {PACKAGE_PIN T14 IOSTANDARD LVCMOS25} [get_ports {gpio_status[1]}]
set_property -dict {PACKAGE_PIN T15 IOSTANDARD LVCMOS25} [get_ports {gpio_status[2]}]
set_property -dict {PACKAGE_PIN T17 IOSTANDARD LVCMOS25} [get_ports {gpio_status[3]}]
set_property -dict {PACKAGE_PIN T19 IOSTANDARD LVCMOS25} [get_ports {gpio_status[4]}]
set_property -dict {PACKAGE_PIN T20 IOSTANDARD LVCMOS25} [get_ports {gpio_status[5]}]
set_property -dict {PACKAGE_PIN U13 IOSTANDARD LVCMOS25} [get_ports {gpio_status[6]}]
set_property -dict {PACKAGE_PIN V13 IOSTANDARD LVCMOS25} [get_ports {gpio_status[7]}]

set_property -dict {PACKAGE_PIN T10 IOSTANDARD LVCMOS25} [get_ports {gpio_ctl[0]}]
set_property -dict {PACKAGE_PIN J14 IOSTANDARD LVCMOS25} [get_ports {gpio_ctl[1]}]
set_property -dict {PACKAGE_PIN N15 IOSTANDARD LVCMOS25} [get_ports {gpio_ctl[2]}]
set_property -dict {PACKAGE_PIN N16 IOSTANDARD LVCMOS25} [get_ports {gpio_ctl[3]}]


set_property -dict {PACKAGE_PIN P16 IOSTANDARD LVCMOS25} [get_ports gpio_en_agc]
set_property -dict {PACKAGE_PIN U20 IOSTANDARD LVCMOS25} [get_ports gpio_sync]
set_property -dict {PACKAGE_PIN N17 IOSTANDARD LVCMOS25} [get_ports gpio_resetb]
set_property -dict {PACKAGE_PIN R18 IOSTANDARD LVCMOS25} [get_ports enable]
set_property -dict {PACKAGE_PIN P14 IOSTANDARD LVCMOS25} [get_ports txnrx]

set_property PACKAGE_PIN P18 [get_ports spi_csn]
set_property IOSTANDARD LVCMOS25 [get_ports spi_csn]
set_property PULLUP true [get_ports spi_csn]
set_property -dict {PACKAGE_PIN R14 IOSTANDARD LVCMOS25} [get_ports spi_clk]
set_property -dict {PACKAGE_PIN P15 IOSTANDARD LVCMOS25} [get_ports spi_mosi]
set_property -dict {PACKAGE_PIN R19 IOSTANDARD LVCMOS25} [get_ports spi_miso]

set_property -dict {PACKAGE_PIN B20 IOSTANDARD LVCMOS25} [get_ports tx1_en]
set_property -dict {PACKAGE_PIN C20 IOSTANDARD LVCMOS25} [get_ports tx2_en]
set_property -dict {PACKAGE_PIN E19 IOSTANDARD LVCMOS25} [get_ports sel_clk_src]

# iic
set_property PACKAGE_PIN M14 [get_ports iic_scl]
set_property IOSTANDARD LVCMOS25 [get_ports iic_scl]
set_property PULLUP true [get_ports iic_scl]
set_property PACKAGE_PIN M15 [get_ports iic_sda]
set_property IOSTANDARD LVCMOS25 [get_ports iic_sda]
set_property PULLUP true [get_ports iic_sda]

set_property -dict {PACKAGE_PIN D20 IOSTANDARD LVCMOS25} [get_ports phy_tx_en]
set_property -dict {PACKAGE_PIN E18 IOSTANDARD LVCMOS25} [get_ports phy_tx_err]
set_property -dict {PACKAGE_PIN F17 IOSTANDARD LVCMOS25} [get_ports phy_reset_n]
set_property -dict {PACKAGE_PIN M19 IOSTANDARD LVCMOS25} [get_ports {phy_tx_dout[0]}]
set_property -dict {PACKAGE_PIN M20 IOSTANDARD LVCMOS25} [get_ports {phy_tx_dout[1]}]
set_property -dict {PACKAGE_PIN M17 IOSTANDARD LVCMOS25} [get_ports {phy_tx_dout[2]}]
set_property -dict {PACKAGE_PIN M18 IOSTANDARD LVCMOS25} [get_ports {phy_tx_dout[3]}]
set_property -dict {PACKAGE_PIN L19 IOSTANDARD LVCMOS25} [get_ports {phy_tx_dout[4]}]
set_property -dict {PACKAGE_PIN L20 IOSTANDARD LVCMOS25} [get_ports {phy_tx_dout[5]}]
set_property -dict {PACKAGE_PIN K19 IOSTANDARD LVCMOS25} [get_ports {phy_tx_dout[6]}]
set_property -dict {PACKAGE_PIN J19 IOSTANDARD LVCMOS25} [get_ports {phy_tx_dout[7]}]
set_property -dict {PACKAGE_PIN L16 IOSTANDARD LVCMOS25} [get_ports phy_tx_clk]

set_property -dict {PACKAGE_PIN L17 IOSTANDARD LVCMOS25} [get_ports phy_rx_err]
set_property -dict {PACKAGE_PIN K17 IOSTANDARD LVCMOS25} [get_ports phy_rx_clk]

create_clock -period 8.000 -name phy_rx_clk [get_ports phy_rx_clk]

set_property -dict {PACKAGE_PIN H17 IOSTANDARD LVCMOS25} [get_ports {phy_rx_din[0]}]
set_property -dict {PACKAGE_PIN G15 IOSTANDARD LVCMOS25} [get_ports {phy_rx_din[1]}]
set_property -dict {PACKAGE_PIN H18 IOSTANDARD LVCMOS25} [get_ports {phy_rx_din[2]}]
set_property -dict {PACKAGE_PIN F19 IOSTANDARD LVCMOS25} [get_ports {phy_rx_din[3]}]
set_property -dict {PACKAGE_PIN F20 IOSTANDARD LVCMOS25} [get_ports {phy_rx_din[4]}]
set_property -dict {PACKAGE_PIN G17 IOSTANDARD LVCMOS25} [get_ports {phy_rx_din[5]}]
set_property -dict {PACKAGE_PIN G18 IOSTANDARD LVCMOS25} [get_ports {phy_rx_din[6]}]
set_property -dict {PACKAGE_PIN J20 IOSTANDARD LVCMOS25} [get_ports {phy_rx_din[7]}]

set_property -dict {PACKAGE_PIN H20 IOSTANDARD LVCMOS25} [get_ports phy_rx_dv]
set_property -dict {PACKAGE_PIN H15 IOSTANDARD LVCMOS25} [get_ports phy_gtx_clk]

set_property PACKAGE_PIN G19 [get_ports mdio1_mdc]
set_property IOSTANDARD LVCMOS25 [get_ports mdio1_mdc]
set_property PULLUP true [get_ports mdio1_mdc]
set_property PACKAGE_PIN G20 [get_ports mdio1_io]
set_property IOSTANDARD LVCMOS25 [get_ports mdio1_io]
set_property PULLUP true [get_ports mdio1_io]

set_property -dict {PACKAGE_PIN A20 IOSTANDARD LVCMOS25} [get_ports rx1_led]
set_property -dict {PACKAGE_PIN B19 IOSTANDARD LVCMOS25} [get_ports rx2_led]

# # end
