#!/bin/bash

#// Author: Xianjun Jiao <putaoshu@msn.com>
#// SPDX-FileCopyrightText: 2025 Xianjun Jiao
#// SPDX-License-Identifier: Apache-2.0 license

# arm-linux-gnueabihf-gcc -static -o btle_ll btle_ll.c -O2 -pthread

source ~/Xilinx/Vitis/2022.2/settings64.sh

set -x

target_name=btle_ll
arm-linux-gnueabihf-gcc -static -pthread \
  -O3 -mcpu=cortex-a9 -mfpu=neon -mfloat-abi=hard \
  -flto -fvisibility=hidden \
  -fPIC -fPIE -fstack-protector-strong -fno-common \
  -ffunction-sections -fdata-sections \
  -Wl,--gc-sections -Wl,-z,relro -Wl,-z,now -Wl,--exclude-libs,ALL -pie \
  -o $target_name $target_name.c

arm-linux-gnueabihf-strip --strip-all $target_name

arm-linux-gnueabihf-objcopy --redefine-sym old=new --remove-section=.note.gnu.build-id $target_name
# scp $target_name root@10.10.10.10:

# cp $target_name ../../../BTLE/verilog/btle_ll/

# target_name=btle_ll_recv_from_host
# arm-linux-gnueabihf-gcc -static -pthread \
#   -O3 -mcpu=cortex-a9 -mfpu=neon -mfloat-abi=hard \
#   -flto -fvisibility=hidden \
#   -fPIC -fPIE -fstack-protector-strong -fno-common \
#   -ffunction-sections -fdata-sections \
#   -Wl,--gc-sections -Wl,-z,relro -Wl,-z,now -Wl,--exclude-libs,ALL -pie \
#   -o $target_name $target_name.c

# arm-linux-gnueabihf-strip --strip-all $target_name

# arm-linux-gnueabihf-objcopy --redefine-sym old=new --remove-section=.note.gnu.build-id $target_name
# # scp $target_name root@10.10.10.10:

# cp $target_name ../../../BTLE/BTLE-hw-img/fpga/

set +x

#source ~/Xilinx/Vivado/2022.2/settings64.sh
#vivado -source ./btle_ll.tcl
