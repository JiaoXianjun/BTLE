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

