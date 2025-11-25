#!/bin/bash

# // Author: Xianjun Jiao <putaoshu@msn.com>
# // SPDX-FileCopyrightText: 2025 Xianjun Jiao
# // SPDX-License-Identifier: Apache-2.0 license

if [ "$#" -lt 1 ]; then
  echo "Please specify hardware platform: antsdr sdrpi antsdr_e200"
  exit 1
else
  HARDWARE=$1
fi

./save_fpga_img_ila.sh $HARDWARE
./BOOT_BIN_gen.sh $HARDWARE
# ./devicetree_gen.sh

set -x
scp BOOT.BIN root@10.10.10.10:
scp ../$HARDWARE/devicetree.dtb root@10.10.10.10:
scp ../../verilog/btle_ll/btle_ll root@10.10.10.10:
echo "Try to run remotely on board and reboot ..."
ssh root@10.10.10.10 "sync"
ssh root@10.10.10.10 "./update_BOOT_partition.sh"
set +x
