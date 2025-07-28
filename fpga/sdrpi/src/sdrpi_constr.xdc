
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

set_property -dict {PACKAGE_PIN P18 IOSTANDARD LVCMOS25 PULLUP true  } [get_ports spi_csn]
set_property -dict {PACKAGE_PIN R14 IOSTANDARD LVCMOS25 } [get_ports spi_clk]
set_property -dict {PACKAGE_PIN P15 IOSTANDARD LVCMOS25 } [get_ports spi_mosi]
set_property -dict {PACKAGE_PIN R19 IOSTANDARD LVCMOS25 } [get_ports spi_miso]

set_property -dict {PACKAGE_PIN B20 IOSTANDARD LVCMOS25 } [get_ports tx1_en]
set_property -dict {PACKAGE_PIN C20 IOSTANDARD LVCMOS25 } [get_ports tx2_en]
set_property -dict {PACKAGE_PIN E19 IOSTANDARD LVCMOS25 } [get_ports sel_clk_src]

# iic      
set_property  -dict {PACKAGE_PIN  M14   IOSTANDARD LVCMOS25 PULLTYPE PULLUP} [get_ports iic_scl]          
set_property  -dict {PACKAGE_PIN  M15   IOSTANDARD LVCMOS25 PULLTYPE PULLUP} [get_ports iic_sda]        



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




set_property -dict {PACKAGE_PIN G19 IOSTANDARD LVCMOS25 PULLUP true  } [get_ports mdio1_mdc]
set_property -dict {PACKAGE_PIN G20  IOSTANDARD LVCMOS25 PULLUP true  } [get_ports mdio1_io]
  

set_property -dict {PACKAGE_PIN A20 IOSTANDARD LVCMOS25} [get_ports rx1_led ]
set_property -dict {PACKAGE_PIN B19 IOSTANDARD LVCMOS25} [get_ports rx2_led ]

 
 
