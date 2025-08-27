#!/bin/bash

# // Author: Xianjun Jiao <putaoshu@msn.com>
# // SPDX-FileCopyrightText: 2025 Xianjun Jiao
# // SPDX-License-Identifier: Apache-2.0 license

set -x

HARDWARES="sdrpi antsdr_e200"

for hw in $HARDWARES; do
    cp ../$hw/btle_$hw/system_top.xsa ../../BTLE-hw-img/fpga/$hw/system_top.xsa
    cp ../$hw/btle_$hw/btle_$hw.runs/impl_1/system_top.ltx ../../BTLE-hw-img/fpga/$hw/system_top.ltx
done

set +x

