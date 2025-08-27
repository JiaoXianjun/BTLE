#!/bin/bash

# // Author: Xianjun Jiao <putaoshu@msn.com>
# // SPDX-FileCopyrightText: 2025 Xianjun Jiao
# // SPDX-License-Identifier: Apache-2.0 license

if [ "$#" -lt 1 ]; then
  HARDWARE="sdrpi"
else
  HARDWARE=$1
fi

source ~/Xilinx/Vitis/2022.2/settings64.sh
./build_boot_bin.sh ../../BTLE-hw-img/fpga/$HARDWARE/system_top.xsa ./u-boot.elf
cp ./output_boot_bin/BOOT.BIN ./
echo "BOOT.BIN"
