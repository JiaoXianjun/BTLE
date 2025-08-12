# Author: Xianjun Jiao
# SPDX-FileCopyrightText: 2025 Xianjun Jiao <putaoshu@msn.com>
# SPDX-License-Identifier: Apache-2.0

#create_clock -name rf_clk -period 62.500 [get_pins util_ad9361_divclk/clk_out]

set_clock_groups -asynchronous \
    -group [get_clocks clk_div_sel_0_s] \
    -group [get_clocks clk_fpga_0]
    
set_clock_groups -asynchronous \
    -group [get_clocks clk_div_sel_1_s] \
    -group [get_clocks clk_fpga_0]

