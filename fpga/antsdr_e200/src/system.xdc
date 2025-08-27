#set_clock_groups -asynchronous -group [get_clocks [list i_system_wrapper/system_i/util_ad9361_divclk/inst/clk_out]] -group [get_clocks [list i_system_wrapper/system_i/sys_ps8/inst/pl_clk2]]
#set_false_path -from [get_clocks -of_objects [get_pins i_system_wrapper/system_i/util_ad9361_divclk/inst/clk_divide_sel_0/O]] -to [get_clocks clk_pl_2]
#set_false_path -from [get_clocks -of_objects [get_pins i_system_wrapper/system_i/util_ad9361_divclk/inst/clk_divide_sel_1/O]] -to [get_clocks clk_pl_2]

## relax cross rf and bb domain control of adc_intf
#set_false_path -from [get_pins i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/adc_valid_count_reg/C] -to [get_pins {i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/wren_count_reg[0]/R}]
#set_false_path -from [get_pins i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/adc_valid_count_reg/C] -to [get_pins {i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/wren_count_reg[1]/R}]
#set_false_path -from [get_pins i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/adc_valid_count_reg/C] -to [get_pins {i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/wren_count_reg[2]/R}]
#set_false_path -from [get_pins i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/adc_valid_count_reg/C] -to [get_pins {i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/wren_count_reg[3]/R}]

#set_false_path -from [get_pins i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/fifo32_2clk_dep32_i/fifo_generator_0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/ram_full_i_reg/C] -to [get_pins i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/FULL_internal_in_bb_domain_reg/D]

#set_false_path -from [get_pins i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/adc_valid_count_reg/C] -to [get_pins i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/adc_valid_decimate_reg_reg/D]
#set_false_path -from [get_pins i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/adc_valid_count_reg_replica/C] -to [get_pins i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/adc_valid_decimate_reg_reg/D]
#set_false_path -from [get_pins i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/adc_valid_count_reg_replica_1/C] -to [get_pins i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/adc_valid_decimate_reg_reg/D]

#set_false_path -from [get_pins i_system_wrapper/system_i/util_ad9361_divclk/inst/clk_divide_sel_0/O] -to [get_pins i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/adc_clk_in_bb_domain_reg/D]
#set_false_path -from [get_pins i_system_wrapper/system_i/util_ad9361_divclk/inst/clk_divide_sel_1/O] -to [get_pins i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/adc_clk_in_bb_domain_reg/D]
#set_false_path -through [get_pins i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/adc_clk_in_bb_domain_reg/C]
#set_false_path -through [get_pins i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/adc_clk_in_bb_domain_reg/D]
#set_false_path -through [get_pins i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/adc_clk_in_bb_domain_reg/Q]
#set_false_path -through [get_pins i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/adc_clk_in_bb_domain_reg/R]

#set_false_path -from [get_pins i_system_wrapper/system_i/util_ad9361_adc_pack/inst/i_cpack/packed_fifo_wr_en_reg/C] -to [get_pins i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/adc_valid_in_bb_domain_reg/D]
#set_false_path -through [get_pins i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/adc_valid_in_bb_domain_reg/C]
#set_false_path -through [get_pins i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/adc_valid_in_bb_domain_reg/D]
#set_false_path -through [get_pins i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/adc_valid_in_bb_domain_reg/Q]
#set_false_path -through [get_pins i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/adc_valid_in_bb_domain_reg/R]

# relax cross rf and bb domain control of dac_intf
set_max_delay 5 -datapath_only -from [get_pins {i_system_wrapper/system_i/openwifi_ip/tx_intf_0/inst/tx_iq_intf_i/csi_fuzzer_i/iq_out_reg[*]/C}] -to [get_pins {i_system_wrapper/system_i/openwifi_ip/tx_intf_0/inst/dac_intf_i/data_from_acc_stage1_reg[*]/D}]

# relax cross rf and bb domain control of dac_intf
set_false_path -through [get_pins {i_system_wrapper/system_i/openwifi_ip/tx_intf_0/inst/dac_intf_i/xpm_cdc_array_single_inst_ant_flag/syncstages_ff_reg[3][0]/C}]
set_false_path -through [get_pins {i_system_wrapper/system_i/openwifi_ip/tx_intf_0/inst/dac_intf_i/xpm_cdc_array_single_inst_simple_cdd_flag/syncstages_ff_reg[3][0]/C}]
set_false_path -through [get_pins {i_system_wrapper/system_i/openwifi_ip/tx_intf_0/inst/dac_intf_i/xpm_cdc_array_single_inst_read_bb_fifo/syncstages_ff_reg[3][0]/C}]

# relax cross rf and bb domain control of adc_intf
set_max_delay 5 -datapath_only -from [get_pins {i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/adc_data_shift_reg[*]/C}] -to [get_pins {i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/adc_data_shift_stage1_reg[*]/D}]
set_max_delay 5 -datapath_only -from [get_pins i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/adc_valid_count_reg_inv/C] -to [get_pins i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/adc_valid_decimate_stage1_reg/D]
set_false_path -through [get_pins {i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/xpm_cdc_array_single_inst_ant_flag/syncstages_ff_reg[3][*]/C}]


# iic

set_property  -dict {PACKAGE_PIN  L20   IOSTANDARD LVCMOS18 PULLTYPE PULLUP} [get_ports iic_scl]           ; 
set_property  -dict {PACKAGE_PIN  L19   IOSTANDARD LVCMOS18 PULLTYPE PULLUP} [get_ports iic_sda]           ; 


set_property  -dict {PACKAGE_PIN  V6   IOSTANDARD  LVCMOS33} [get_ports  dac_sync] ;
set_property  -dict {PACKAGE_PIN  W6   IOSTANDARD  LVCMOS33} [get_ports  dac_sclk] ;
set_property  -dict {PACKAGE_PIN  V10  IOSTANDARD  LVCMOS33} [get_ports  dac_din]  ;
set_property  -dict {PACKAGE_PIN  V11  IOSTANDARD  LVCMOS33} [get_ports  pps_in]  ;
set_property  -dict {PACKAGE_PIN  M20  IOSTANDARD  LVCMOS33} [get_ports  clkin_10m_req]  ;
set_property  -dict {PACKAGE_PIN  J18  IOSTANDARD  LVCMOS33} [get_ports  clkin_10m]  ;

set_property  -dict {PACKAGE_PIN  N16   IOSTANDARD  LVCMOS18} [get_ports  gpio_clksel]  ;




set_property  -dict {PACKAGE_PIN  C20   IOSTANDARD  LVCMOS18} [get_ports  rgmii_td[3]]  ;
set_property  -dict {PACKAGE_PIN  D19   IOSTANDARD  LVCMOS18} [get_ports  rgmii_td[2]]  ;
set_property  -dict {PACKAGE_PIN  D20   IOSTANDARD  LVCMOS18} [get_ports  rgmii_td[1]]  ;
set_property  -dict {PACKAGE_PIN  F19   IOSTANDARD  LVCMOS18} [get_ports  rgmii_td[0]]  ;
set_property  -dict {PACKAGE_PIN  E18   IOSTANDARD  LVCMOS18} [get_ports  rgmii_rd[3]]  ;
set_property  -dict {PACKAGE_PIN  E19   IOSTANDARD  LVCMOS18} [get_ports  rgmii_rd[2]]  ;
set_property  -dict {PACKAGE_PIN  E17   IOSTANDARD  LVCMOS18} [get_ports  rgmii_rd[1]]  ;
set_property  -dict {PACKAGE_PIN  F16   IOSTANDARD  LVCMOS18} [get_ports  rgmii_rd[0]]  ;

set_property  -dict {PACKAGE_PIN  F20   IOSTANDARD  LVCMOS18} [get_ports  rgmii_tx_ctl]  ;
set_property  -dict {PACKAGE_PIN  D18   IOSTANDARD  LVCMOS18} [get_ports  rgmii_txc]     ;
set_property  -dict {PACKAGE_PIN  G17   IOSTANDARD  LVCMOS18} [get_ports  rgmii_rx_ctl]  ;
set_property  -dict {PACKAGE_PIN  H16   IOSTANDARD  LVCMOS18} [get_ports  rgmii_rxc]     ;
set_property  -dict {PACKAGE_PIN  B19   IOSTANDARD  LVCMOS18} [get_ports  phy_rst_n]   ;
set_property  -dict {PACKAGE_PIN  A20   IOSTANDARD  LVCMOS18} [get_ports  mdio_phy_mdio_io]   ;
set_property  -dict {PACKAGE_PIN  B20   IOSTANDARD  LVCMOS18} [get_ports  mdio_phy_mdc]       ;

set_property  -dict {PACKAGE_PIN  G15   IOSTANDARD  LVCMOS18} [get_ports  tx_amp_en]  ;


set_property  -dict {PACKAGE_PIN    T15   IOSTANDARD LVCMOS25} [get_ports gpio_status[7]]                    ; 
set_property  -dict {PACKAGE_PIN    K16   IOSTANDARD LVCMOS18} [get_ports gpio_status[6]]                    ; 
set_property  -dict {PACKAGE_PIN    P14   IOSTANDARD LVCMOS25} [get_ports gpio_status[5]]                    ; 
set_property  -dict {PACKAGE_PIN    P15   IOSTANDARD LVCMOS25} [get_ports gpio_status[4]]                    ; 
set_property  -dict {PACKAGE_PIN    R14   IOSTANDARD LVCMOS25} [get_ports gpio_status[3]]                    ; 
set_property  -dict {PACKAGE_PIN    J16   IOSTANDARD LVCMOS18} [get_ports gpio_status[2]]                    ; 
set_property  -dict {PACKAGE_PIN    J15   IOSTANDARD LVCMOS18} [get_ports gpio_status[1]]                    ; 
set_property  -dict {PACKAGE_PIN    T10   IOSTANDARD LVCMOS25} [get_ports gpio_status[0]]                    ; 
set_property  -dict {PACKAGE_PIN    T11   IOSTANDARD LVCMOS25} [get_ports gpio_ctl[3]]                       ; 
set_property  -dict {PACKAGE_PIN    V13   IOSTANDARD LVCMOS25} [get_ports gpio_ctl[2]]                       ; 
set_property  -dict {PACKAGE_PIN    T14   IOSTANDARD LVCMOS25} [get_ports gpio_ctl[1]]                       ; 
set_property  -dict {PACKAGE_PIN    U13   IOSTANDARD LVCMOS25} [get_ports gpio_ctl[0]]                       ; 
set_property  -dict {PACKAGE_PIN    P16   IOSTANDARD LVCMOS25} [get_ports gpio_en_agc]                       ; 
set_property  -dict {PACKAGE_PIN    U20   IOSTANDARD LVCMOS25} [get_ports gpio_sync]                         ; 
set_property  -dict {PACKAGE_PIN    T17   IOSTANDARD LVCMOS25} [get_ports gpio_resetb]                       ; 
set_property  -dict {PACKAGE_PIN    R18   IOSTANDARD LVCMOS25} [get_ports enable]                            ; 
set_property  -dict {PACKAGE_PIN    N17   IOSTANDARD LVCMOS25} [get_ports txnrx]                             ; 

set_property  -dict {PACKAGE_PIN    T20   IOSTANDARD LVCMOS25  PULLTYPE PULLUP} [get_ports spi_csn]          ; 
set_property  -dict {PACKAGE_PIN    R19   IOSTANDARD LVCMOS25} [get_ports spi_clk]                           ; 
set_property  -dict {PACKAGE_PIN    P18   IOSTANDARD LVCMOS25} [get_ports spi_mosi]                          ; 
set_property  -dict {PACKAGE_PIN    T19   IOSTANDARD LVCMOS25} [get_ports spi_miso]                          ; 





# constraints (pzsdr2.e)
# ad9361

set_property  -dict {PACKAGE_PIN  N20  IOSTANDARD LVDS_25      DIFF_TERM TRUE} [get_ports rx_clk_in_p]       ; 
set_property  -dict {PACKAGE_PIN  P20  IOSTANDARD LVDS_25      DIFF_TERM TRUE} [get_ports rx_clk_in_n]       ; 
set_property  -dict {PACKAGE_PIN  Y16  IOSTANDARD LVDS_25      DIFF_TERM TRUE} [get_ports rx_frame_in_p]     ; 
set_property  -dict {PACKAGE_PIN  Y17  IOSTANDARD LVDS_25      DIFF_TERM TRUE} [get_ports rx_frame_in_n]     ; 
set_property  -dict {PACKAGE_PIN  W14  IOSTANDARD LVDS_25      DIFF_TERM TRUE} [get_ports rx_data_in_p[5]]   ; 
set_property  -dict {PACKAGE_PIN  Y14  IOSTANDARD LVDS_25      DIFF_TERM TRUE} [get_ports rx_data_in_n[5]]   ; 
set_property  -dict {PACKAGE_PIN  V20  IOSTANDARD LVDS_25      DIFF_TERM TRUE} [get_ports rx_data_in_p[4]]   ; 
set_property  -dict {PACKAGE_PIN  W20  IOSTANDARD LVDS_25      DIFF_TERM TRUE} [get_ports rx_data_in_n[4]]   ; 
set_property  -dict {PACKAGE_PIN  R16  IOSTANDARD LVDS_25      DIFF_TERM TRUE} [get_ports rx_data_in_p[3]]   ; 
set_property  -dict {PACKAGE_PIN  R17  IOSTANDARD LVDS_25      DIFF_TERM TRUE} [get_ports rx_data_in_n[3]]   ; 
set_property  -dict {PACKAGE_PIN  W18  IOSTANDARD LVDS_25      DIFF_TERM TRUE} [get_ports rx_data_in_p[2]]   ; 
set_property  -dict {PACKAGE_PIN  W19  IOSTANDARD LVDS_25      DIFF_TERM TRUE} [get_ports rx_data_in_n[2]]   ; 
set_property  -dict {PACKAGE_PIN  V17  IOSTANDARD LVDS_25      DIFF_TERM TRUE} [get_ports rx_data_in_p[1]]   ; 
set_property  -dict {PACKAGE_PIN  V18  IOSTANDARD LVDS_25      DIFF_TERM TRUE} [get_ports rx_data_in_n[1]]   ; 
set_property  -dict {PACKAGE_PIN  Y18  IOSTANDARD LVDS_25      DIFF_TERM TRUE} [get_ports rx_data_in_p[0]]   ; 
set_property  -dict {PACKAGE_PIN  Y19  IOSTANDARD LVDS_25      DIFF_TERM TRUE} [get_ports rx_data_in_n[0]]   ; 
set_property  -dict {PACKAGE_PIN  N18  IOSTANDARD LVDS_25}     [get_ports tx_clk_out_p]                      ; 
set_property  -dict {PACKAGE_PIN  P19  IOSTANDARD LVDS_25}     [get_ports tx_clk_out_n]                      ; 
set_property  -dict {PACKAGE_PIN  V16  IOSTANDARD LVDS_25}     [get_ports tx_frame_out_p]                    ; 
set_property  -dict {PACKAGE_PIN  W16  IOSTANDARD LVDS_25}     [get_ports tx_frame_out_n]                    ; 
set_property  -dict {PACKAGE_PIN  V15  IOSTANDARD LVDS_25}     [get_ports tx_data_out_p[5]]                  ; 
set_property  -dict {PACKAGE_PIN  W15  IOSTANDARD LVDS_25}     [get_ports tx_data_out_n[5]]                  ; 
set_property  -dict {PACKAGE_PIN  T12  IOSTANDARD LVDS_25}     [get_ports tx_data_out_p[4]]                  ; 
set_property  -dict {PACKAGE_PIN  U12  IOSTANDARD LVDS_25}     [get_ports tx_data_out_n[4]]                  ; 
set_property  -dict {PACKAGE_PIN  V12  IOSTANDARD LVDS_25}     [get_ports tx_data_out_p[3]]                  ; 
set_property  -dict {PACKAGE_PIN  W13  IOSTANDARD LVDS_25}     [get_ports tx_data_out_n[3]]                  ; 
set_property  -dict {PACKAGE_PIN  U14  IOSTANDARD LVDS_25}     [get_ports tx_data_out_p[2]]                  ; 
set_property  -dict {PACKAGE_PIN  U15  IOSTANDARD LVDS_25}     [get_ports tx_data_out_n[2]]                  ; 
set_property  -dict {PACKAGE_PIN  U18  IOSTANDARD LVDS_25}     [get_ports tx_data_out_p[1]]                  ; 
set_property  -dict {PACKAGE_PIN  U19  IOSTANDARD LVDS_25}     [get_ports tx_data_out_n[1]]                  ; 
set_property  -dict {PACKAGE_PIN  T16  IOSTANDARD LVDS_25}     [get_ports tx_data_out_p[0]]                  ; 
set_property  -dict {PACKAGE_PIN  U17  IOSTANDARD LVDS_25}     [get_ports tx_data_out_n[0]]                  ; 

# clocks

create_clock -name rx_clk       -period  4 [get_ports rx_clk_in_p]

