#!/bin/bash

# // Author: Xianjun Jiao <putaoshu@msn.com>
# // SPDX-FileCopyrightText: 2025 Xianjun Jiao
# // SPDX-License-Identifier: Apache-2.0 license

if [ "$#" -lt 1 ]; then
  HARDWARE="sdrpi"
else
  HARDWARE=$1
fi

./save_fpga_img_ila.sh
./BOOT_BIN_gen.sh $HARDWARE
# ./devicetree_gen.sh

set -x
scp BOOT.BIN root@10.10.10.10:
scp ../$HARDWARE/devicetree.dtb root@10.10.10.10:
echo "Try to run remotely on board and reboot ..."
ssh root@10.10.10.10 "./update_BOOT_partition.sh"
set +x
