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