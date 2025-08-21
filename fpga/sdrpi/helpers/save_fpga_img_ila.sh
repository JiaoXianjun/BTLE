#!/bin/bash

# // Author: Xianjun Jiao <putaoshu@msn.com>
# // SPDX-FileCopyrightText: 2025 Xianjun Jiao
# // SPDX-License-Identifier: Apache-2.0 license
set -x
cp ../btle_sdrpi/system_top.xsa ../../../BTLE-hw-img/fpga/sdrpi/system_top.xsa
cp ../btle_sdrpi/btle_sdrpi.runs/impl_1/system_top.ltx ../../../BTLE-hw-img/fpga/sdrpi/system_top.ltx
set +x

