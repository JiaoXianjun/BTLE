################################################################################

# This XDC is used only for OOC mode of synthesis, implementation
# This constraints file contains default clock frequencies to be used during
# out-of-context flows such as OOC Synthesis and Hierarchical Designs.
# This constraints file is not used in normal top-down synthesis (default flow
# of Vivado)
################################################################################
create_clock -name ENET1_GMII_RX_CLK_0 -period 10 [get_ports ENET1_GMII_RX_CLK_0]
create_clock -name ENET1_GMII_TX_CLK_0 -period 10 [get_ports ENET1_GMII_TX_CLK_0]
create_clock -name GMII_ETHERNET_1_0_rx_clk -period 10 [get_ports GMII_ETHERNET_1_0_rx_clk]
create_clock -name GMII_ETHERNET_1_0_tx_clk -period 10 [get_ports GMII_ETHERNET_1_0_tx_clk]
create_clock -name sys_ps7_FCLK_CLK0 -period 10 [get_pins sys_ps7/FCLK_CLK0]
create_clock -name sys_ps7_FCLK_CLK1 -period 5 [get_pins sys_ps7/FCLK_CLK1]
create_clock -name sys_ps7_FCLK_CLK2 -period 8 [get_pins sys_ps7/FCLK_CLK2]

################################################################################