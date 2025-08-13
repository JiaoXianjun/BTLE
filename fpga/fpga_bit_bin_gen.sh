#!/bin/bash

# // Author: Xianjun Jiao <putaoshu@msn.com>
# // SPDX-FileCopyrightText: 2025 Xianjun Jiao
# // SPDX-License-Identifier: Apache-2.0 license

mkdir -p tmp
rm tmp/* -rf
unzip ../BTLE-hw-img/fpga/sdrpi/system_top.xsa -d ./tmp
source ~/Xilinx/Vitis/2022.2/settings64.sh
bootgen -image fpga_top.bif -arch zynq -process_bitstream bin -w
cp ./tmp/system_top.bit.bin ./
echo system_top.bit.bin
