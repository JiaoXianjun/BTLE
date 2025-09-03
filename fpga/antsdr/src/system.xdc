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

# ad9361

set_property  -dict {PACKAGE_PIN  T11  IOSTANDARD LVCMOS25} [get_ports gpio_status[0]]                   ; ## G21  FMC_LPC_LA20_P
set_property  -dict {PACKAGE_PIN  T14  IOSTANDARD LVCMOS25} [get_ports gpio_status[1]]                   ; ## G22  FMC_LPC_LA20_N
set_property  -dict {PACKAGE_PIN  T15  IOSTANDARD LVCMOS25} [get_ports gpio_status[2]]                   ; ## H25  FMC_LPC_LA21_P
set_property  -dict {PACKAGE_PIN  T17  IOSTANDARD LVCMOS25} [get_ports gpio_status[3]]                   ; ## H26  FMC_LPC_LA21_N
set_property  -dict {PACKAGE_PIN  T19  IOSTANDARD LVCMOS25} [get_ports gpio_status[4]]                   ; ## G24  FMC_LPC_LA22_P
set_property  -dict {PACKAGE_PIN  T20  IOSTANDARD LVCMOS25} [get_ports gpio_status[5]]                   ; ## G25  FMC_LPC_LA22_N
set_property  -dict {PACKAGE_PIN  U13  IOSTANDARD LVCMOS25} [get_ports gpio_status[6]]                   ; ## D23  FMC_LPC_LA23_P
set_property  -dict {PACKAGE_PIN  V13  IOSTANDARD LVCMOS25} [get_ports gpio_status[7]]                   ; ## D24  FMC_LPC_LA23_N
set_property  -dict {PACKAGE_PIN  T10  IOSTANDARD LVCMOS25} [get_ports gpio_ctl[0]]                      ; ## H28  FMC_LPC_LA24_P
set_property  -dict {PACKAGE_PIN  Y12  IOSTANDARD LVCMOS33} [get_ports gpio_ctl[1]]                      ; ## H29  FMC_LPC_LA24_N
set_property  -dict {PACKAGE_PIN  Y13  IOSTANDARD LVCMOS33} [get_ports gpio_ctl[2]]                      ; ## G27  FMC_LPC_LA25_P
set_property  -dict {PACKAGE_PIN  V11  IOSTANDARD LVCMOS33} [get_ports gpio_ctl[3]]                      ; ## G28  FMC_LPC_LA25_N
set_property  -dict {PACKAGE_PIN  P16  IOSTANDARD LVCMOS25} [get_ports gpio_en_agc]                      ; ## H22  FMC_LPC_LA19_P
set_property  -dict {PACKAGE_PIN  U20  IOSTANDARD LVCMOS25} [get_ports gpio_sync]                        ; ## H23  FMC_LPC_LA19_N
set_property  -dict {PACKAGE_PIN  N17  IOSTANDARD LVCMOS25} [get_ports gpio_resetb]                      ; ## H31  FMC_LPC_LA28_P
set_property  -dict {PACKAGE_PIN  R18  IOSTANDARD LVCMOS25} [get_ports enable]                           ; ## G18  FMC_LPC_LA16_P
set_property  -dict {PACKAGE_PIN  P14  IOSTANDARD LVCMOS25} [get_ports txnrx]                            ; ## G19  FMC_LPC_LA16_N

set_property  -dict {PACKAGE_PIN  P18  IOSTANDARD LVCMOS25  PULLTYPE PULLUP} [get_ports spi_csn]         ; ## D26  FMC_LPC_LA26_P
set_property  -dict {PACKAGE_PIN  R14  IOSTANDARD LVCMOS25} [get_ports spi_clk]                          ; ## D27  FMC_LPC_LA26_N
set_property  -dict {PACKAGE_PIN  P15  IOSTANDARD LVCMOS25} [get_ports spi_mosi]                         ; ## C26  FMC_LPC_LA27_P
set_property  -dict {PACKAGE_PIN  R19  IOSTANDARD LVCMOS25} [get_ports spi_miso]                         ; ## C27  FMC_LPC_LA27_N

# iic
set_property  -dict {PACKAGE_PIN  G18   IOSTANDARD LVCMOS33} [get_ports gpio_clksel] 
set_property  -dict {PACKAGE_PIN  G15   IOSTANDARD LVCMOS33} [get_ports clkout_in]           
set_property  -dict {PACKAGE_PIN  H18   IOSTANDARD LVCMOS33 PULLTYPE PULLUP} [get_ports iic_scl]          
set_property  -dict {PACKAGE_PIN  G17   IOSTANDARD LVCMOS33 PULLTYPE PULLUP} [get_ports iic_sda]          

# ad9361
set_property  -dict {PACKAGE_PIN P19  IOSTANDARD LVDS_25 } [get_ports  tx_clk_out_n     ]
set_property  -dict {PACKAGE_PIN N18  IOSTANDARD LVDS_25 } [get_ports  tx_clk_out_p     ]
set_property  -dict {PACKAGE_PIN Y14  IOSTANDARD LVDS_25 } [get_ports  tx_data_out_n[0] ]
set_property  -dict {PACKAGE_PIN W14  IOSTANDARD LVDS_25 } [get_ports  tx_data_out_p[0] ]
set_property  -dict {PACKAGE_PIN U12  IOSTANDARD LVDS_25 } [get_ports  tx_data_out_n[1] ]
set_property  -dict {PACKAGE_PIN T12  IOSTANDARD LVDS_25 } [get_ports  tx_data_out_p[1] ]
set_property  -dict {PACKAGE_PIN U15  IOSTANDARD LVDS_25 } [get_ports  tx_data_out_n[2] ]
set_property  -dict {PACKAGE_PIN U14  IOSTANDARD LVDS_25 } [get_ports  tx_data_out_p[2] ]
set_property  -dict {PACKAGE_PIN U17  IOSTANDARD LVDS_25 } [get_ports  tx_data_out_n[3] ]
set_property  -dict {PACKAGE_PIN T16  IOSTANDARD LVDS_25 } [get_ports  tx_data_out_p[3] ]
set_property  -dict {PACKAGE_PIN W13  IOSTANDARD LVDS_25 } [get_ports  tx_data_out_n[4] ]
set_property  -dict {PACKAGE_PIN V12  IOSTANDARD LVDS_25 } [get_ports  tx_data_out_p[4] ]
set_property  -dict {PACKAGE_PIN W15  IOSTANDARD LVDS_25 } [get_ports  tx_data_out_n[5] ]
set_property  -dict {PACKAGE_PIN V15  IOSTANDARD LVDS_25 } [get_ports  tx_data_out_p[5] ]
set_property  -dict {PACKAGE_PIN Y17  IOSTANDARD LVDS_25 } [get_ports  tx_frame_out_n   ]
set_property  -dict {PACKAGE_PIN Y16  IOSTANDARD LVDS_25 } [get_ports  tx_frame_out_p   ]
set_property  -dict {PACKAGE_PIN P20  IOSTANDARD LVDS_25 DIFF_TERM TRUE } [get_ports  rx_clk_in_n      ]
set_property  -dict {PACKAGE_PIN N20  IOSTANDARD LVDS_25 DIFF_TERM TRUE } [get_ports  rx_clk_in_p      ]
set_property  -dict {PACKAGE_PIN Y19  IOSTANDARD LVDS_25 DIFF_TERM TRUE } [get_ports  rx_data_in_n[0]  ]
set_property  -dict {PACKAGE_PIN Y18  IOSTANDARD LVDS_25 DIFF_TERM TRUE } [get_ports  rx_data_in_p[0]  ]
set_property  -dict {PACKAGE_PIN V18  IOSTANDARD LVDS_25 DIFF_TERM TRUE } [get_ports  rx_data_in_n[1]  ]
set_property  -dict {PACKAGE_PIN V17  IOSTANDARD LVDS_25 DIFF_TERM TRUE } [get_ports  rx_data_in_p[1]  ]
set_property  -dict {PACKAGE_PIN W20  IOSTANDARD LVDS_25 DIFF_TERM TRUE } [get_ports  rx_data_in_n[2]  ]
set_property  -dict {PACKAGE_PIN V20  IOSTANDARD LVDS_25 DIFF_TERM TRUE } [get_ports  rx_data_in_p[2]  ]
set_property  -dict {PACKAGE_PIN R17  IOSTANDARD LVDS_25 DIFF_TERM TRUE } [get_ports  rx_data_in_n[3]  ]
set_property  -dict {PACKAGE_PIN R16  IOSTANDARD LVDS_25 DIFF_TERM TRUE } [get_ports  rx_data_in_p[3]  ]
set_property  -dict {PACKAGE_PIN W19  IOSTANDARD LVDS_25 DIFF_TERM TRUE } [get_ports  rx_data_in_n[4]  ]
set_property  -dict {PACKAGE_PIN W18  IOSTANDARD LVDS_25 DIFF_TERM TRUE } [get_ports  rx_data_in_p[4]  ]
set_property  -dict {PACKAGE_PIN W16  IOSTANDARD LVDS_25 DIFF_TERM TRUE } [get_ports  rx_data_in_n[5]  ]
set_property  -dict {PACKAGE_PIN V16  IOSTANDARD LVDS_25 DIFF_TERM TRUE } [get_ports  rx_data_in_p[5]  ]
set_property  -dict {PACKAGE_PIN U19  IOSTANDARD LVDS_25 DIFF_TERM TRUE } [get_ports  rx_frame_in_n    ]
set_property  -dict {PACKAGE_PIN U18  IOSTANDARD LVDS_25 DIFF_TERM TRUE } [get_ports  rx_frame_in_p    ]

# clocks

create_clock -name rx_clk       -period  8 [get_ports rx_clk_in_p]

## ad9361 clkout forward

set_property  -dict {PACKAGE_PIN   J18    IOSTANDARD  LVCMOS33} [get_ports  clkout_out]  
set_property  -dict {PACKAGE_PIN   H17    IOSTANDARD  LVCMOS33} [get_ports  gpio_bd[0]]  
set_property  -dict {PACKAGE_PIN   H15    IOSTANDARD  LVCMOS33} [get_ports  gpio_bd[1]]  
set_property  -dict {PACKAGE_PIN   L19    IOSTANDARD  LVCMOS33} [get_ports  gpio_bd[2]]  
set_property  -dict {PACKAGE_PIN   L16    IOSTANDARD  LVCMOS33} [get_ports  gpio_bd[3]]  
set_property  -dict {PACKAGE_PIN   K14    IOSTANDARD  LVCMOS33} [get_ports  gpio_bd[4]]  
set_property  -dict {PACKAGE_PIN   L17    IOSTANDARD  LVCMOS33} [get_ports  gpio_bd[5]]  
set_property  -dict {PACKAGE_PIN   M17    IOSTANDARD  LVCMOS33} [get_ports  gpio_bd[6]]  
set_property  -dict {PACKAGE_PIN   M18    IOSTANDARD  LVCMOS33} [get_ports  gpio_bd[7]]  
set_property  -dict {PACKAGE_PIN   F19    IOSTANDARD  LVCMOS33} [get_ports  gpio_bd[8]]  
set_property  -dict {PACKAGE_PIN   F20    IOSTANDARD  LVCMOS33} [get_ports  gpio_bd[9]]  
set_property  -dict {PACKAGE_PIN   G19    IOSTANDARD  LVCMOS33} [get_ports  gpio_bd[10]] 

set_property  -dict {PACKAGE_PIN  G14  IOSTANDARD LVCMOS33} [get_ports rx1_band_sel_h]
set_property  -dict {PACKAGE_PIN  C20  IOSTANDARD LVCMOS33} [get_ports rx1_band_sel_l]
set_property  -dict {PACKAGE_PIN  B19  IOSTANDARD LVCMOS33} [get_ports tx1_band_sel_h]
set_property  -dict {PACKAGE_PIN  B20  IOSTANDARD LVCMOS33} [get_ports tx1_band_sel_l]
set_property  -dict {PACKAGE_PIN  E17  IOSTANDARD LVCMOS33} [get_ports rx2_band_sel_h]
set_property  -dict {PACKAGE_PIN  A20  IOSTANDARD LVCMOS33} [get_ports rx2_band_sel_l]
set_property  -dict {PACKAGE_PIN  D18  IOSTANDARD LVCMOS33} [get_ports tx2_band_sel_h]
set_property  -dict {PACKAGE_PIN  D19  IOSTANDARD LVCMOS33} [get_ports tx2_band_sel_l]

## end of ad9361

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
connect_debug_port u_ila_0/probe1 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_pdu_octet_mem_addr[0]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_pdu_octet_mem_addr[1]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_pdu_octet_mem_addr[2]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_pdu_octet_mem_addr[3]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_pdu_octet_mem_addr[4]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_pdu_octet_mem_addr[5]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 7 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_payload_length_axi[0]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_payload_length_axi[1]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_payload_length_axi[2]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_payload_length_axi[3]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_payload_length_axi[4]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_payload_length_axi[5]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_payload_length_axi[6]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 6 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_channel_number_axi[0]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_channel_number_axi[1]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_channel_number_axi[2]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_channel_number_axi[3]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_channel_number_axi[4]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_channel_number_axi[5]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 2 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/reg_gpio_axi[0]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/reg_gpio_axi[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 4 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event1_counter_axi[0]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event1_counter_axi[1]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event1_counter_axi[2]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event1_counter_axi[3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 5 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/axi_awaddr_core[0]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/axi_awaddr_core[1]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/axi_awaddr_core[2]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/axi_awaddr_core[3]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/axi_awaddr_core[4]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 5 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/axi_araddr_core[0]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/axi_araddr_core[1]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/axi_araddr_core[2]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/axi_araddr_core[3]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/axi_araddr_core[4]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
set_property port_width 1 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_crc_ok_axi]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
set_property port_width 1 [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_crc_ok_capture_by_decode_end_axi]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
set_property port_width 1 [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_decode_end_axi]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe11]
set_property port_width 1 [get_debug_ports u_ila_0/probe11]
connect_debug_port u_ila_0/probe11 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_decode_run_axi]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe12]
set_property port_width 1 [get_debug_ports u_ila_0/probe12]
connect_debug_port u_ila_0/probe12 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_hit_flag_axi]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe13]
set_property port_width 1 [get_debug_ports u_ila_0/probe13]
connect_debug_port u_ila_0/probe13 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/slv_reg_rden]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe14]
set_property port_width 1 [get_debug_ports u_ila_0/probe14]
connect_debug_port u_ila_0/probe14 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/slv_reg_wren]]
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
set_property port_width 6 [get_debug_ports u_ila_1/probe9]
connect_debug_port u_ila_1/probe9 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_channel_number[0]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_channel_number[1]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_channel_number[2]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_channel_number[3]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_channel_number[4]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_channel_number[5]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe10]
set_property port_width 2 [get_debug_ports u_ila_1/probe10]
connect_debug_port u_ila_1/probe10 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/reg_gpio[0]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/reg_gpio[15]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe11]
set_property port_width 4 [get_debug_ports u_ila_1/probe11]
connect_debug_port u_ila_1/probe11 [get_nets [list {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event1_counter[0]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event1_counter[1]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event1_counter[2]} {i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event1_counter[3]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe12]
set_property port_width 1 [get_debug_ports u_ila_1/probe12]
connect_debug_port u_ila_1/probe12 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/agc_lock_state]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe13]
set_property port_width 1 [get_debug_ports u_ila_1/probe13]
connect_debug_port u_ila_1/probe13 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/decode_end_all]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe14]
set_property port_width 1 [get_debug_ports u_ila_1/probe14]
connect_debug_port u_ila_1/probe14 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/decode_end_early]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe15]
set_property port_width 1 [get_debug_ports u_ila_1/probe15]
connect_debug_port u_ila_1/probe15 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/decode_end_state]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe16]
set_property port_width 1 [get_debug_ports u_ila_1/probe16]
connect_debug_port u_ila_1/probe16 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/btle_rx_i/decode_restart]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe17]
set_property port_width 1 [get_debug_ports u_ila_1/probe17]
connect_debug_port u_ila_1/probe17 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/event_counter_level_decode_run_i/level_signal_delay]]
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
connect_debug_port u_ila_1/probe23 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/btle_ll_i/rx_crc_ok_capture_by_decode_end]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe24]
set_property port_width 1 [get_debug_ports u_ila_1/probe24]
connect_debug_port u_ila_1/probe24 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/rx_decode_end]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe25]
set_property port_width 1 [get_debug_ports u_ila_1/probe25]
connect_debug_port u_ila_1/probe25 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/rx_decode_run]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe26]
set_property port_width 1 [get_debug_ports u_ila_1/probe26]
connect_debug_port u_ila_1/probe26 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/btle_phy_i/rx_hit_flag]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe27]
set_property port_width 1 [get_debug_ports u_ila_1/probe27]
connect_debug_port u_ila_1/probe27 [get_nets [list i_system_wrapper/system_i/btle_controller_0/inst/rx_iq_valid]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk]
