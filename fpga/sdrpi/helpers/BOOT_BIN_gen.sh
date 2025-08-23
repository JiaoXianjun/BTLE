#!/bin/bash

# // Author: Xianjun Jiao <putaoshu@msn.com>
# // SPDX-FileCopyrightText: 2025 Xianjun Jiao
# // SPDX-License-Identifier: Apache-2.0 license

source ~/Xilinx/Vitis/2022.2/settings64.sh
./build_boot_bin.sh ../../../BTLE-hw-img/fpga/sdrpi/system_top.xsa ./u-boot.elf
cp ./output_boot_bin/BOOT.BIN ./
echo "BOOT.BIN"
