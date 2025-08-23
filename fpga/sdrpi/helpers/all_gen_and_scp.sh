#!/bin/bash

# // Author: Xianjun Jiao <putaoshu@msn.com>
# // SPDX-FileCopyrightText: 2025 Xianjun Jiao
# // SPDX-License-Identifier: Apache-2.0 license

./save_fpga_img_ila.sh
./BOOT_BIN_gen.sh
./devicetree_gen.sh

scp BOOT.BIN root@10.10.10.10:
scp devicetree.dtb root@10.10.10.10:
