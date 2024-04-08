# Author: Xianjun Jiao <putaoshu@msn.com>
# SPDX-FileCopyrightText: 2024 Xianjun Jiao
# SPDX-License-Identifier: Apache-2.0 license

create_clock -period 62.500 -name clk -waveform {0.000 31.250} [get_ports clk]
set_input_delay -clock [get_clocks clk] -min -add_delay 10.000 [get_ports {rx_i_signal[*]}]
set_input_delay -clock [get_clocks clk] -max -add_delay 20.000 [get_ports {rx_i_signal[*]}]
set_input_delay -clock [get_clocks clk] -min -add_delay 10.000 [get_ports {rx_q_signal[*]}]
set_input_delay -clock [get_clocks clk] -max -add_delay 20.000 [get_ports {rx_q_signal[*]}]
set_input_delay -clock [get_clocks clk] -min -add_delay 10.000 [get_ports baremetal_phy_intf_mode]
set_input_delay -clock [get_clocks clk] -max -add_delay 20.000 [get_ports baremetal_phy_intf_mode]
set_input_delay -clock [get_clocks clk] -min -add_delay 10.000 [get_ports rst]
set_input_delay -clock [get_clocks clk] -max -add_delay 20.000 [get_ports rst]
set_input_delay -clock [get_clocks clk] -min -add_delay 10.000 [get_ports rx_iq_valid]
set_input_delay -clock [get_clocks clk] -max -add_delay 20.000 [get_ports rx_iq_valid]
set_input_delay -clock [get_clocks clk] -min -add_delay 10.000 [get_ports uart_rx]
set_input_delay -clock [get_clocks clk] -max -add_delay 20.000 [get_ports uart_rx]
set_output_delay -clock [get_clocks clk] -min -add_delay 5.000 [get_ports {tx_i_signal[*]}]
set_output_delay -clock [get_clocks clk] -max -add_delay 11.000 [get_ports {tx_i_signal[*]}]
set_output_delay -clock [get_clocks clk] -min -add_delay 5.000 [get_ports {tx_q_signal[*]}]
set_output_delay -clock [get_clocks clk] -max -add_delay 11.000 [get_ports {tx_q_signal[*]}]
set_output_delay -clock [get_clocks clk] -min -add_delay 5.000 [get_ports tx_iq_valid]
set_output_delay -clock [get_clocks clk] -max -add_delay 11.000 [get_ports tx_iq_valid]
set_output_delay -clock [get_clocks clk] -min -add_delay 5.000 [get_ports tx_iq_valid_last]
set_output_delay -clock [get_clocks clk] -max -add_delay 11.000 [get_ports tx_iq_valid_last]
set_output_delay -clock [get_clocks clk] -min -add_delay 5.000 [get_ports uart_tx]
set_output_delay -clock [get_clocks clk] -max -add_delay 11.000 [get_ports uart_tx]

set_property BITSTREAM.General.UnconstrainedPins {Allow} [current_design]
