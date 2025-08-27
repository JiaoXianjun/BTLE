#!/bin/bash

# // Author: Xianjun Jiao <putaoshu@msn.com>
# // SPDX-FileCopyrightText: 2025 Xianjun Jiao
# // SPDX-License-Identifier: Apache-2.0 license

fpga_filename=system_top.bit.bin

echo 0 > /sys/class/fpga_manager/fpga0/flags
mkdir -p /lib/firmware
cp $fpga_filename /lib/firmware/ -rf
echo $fpga_filename > /sys/class/fpga_manager/fpga0/firmware

