#!/bin/bash

#// Author: Xianjun Jiao <putaoshu@msn.com>
#// SPDX-FileCopyrightText: 2025 Xianjun Jiao
#// SPDX-License-Identifier: Apache-2.0 license

set -x
gcc -O3 -o ble_fpga_ctl ble_fpga_ctl.c
gcc -O3 -o ble_send_cmd ble_send_cmd.c
set +x

