#!/bin/bash

# // Author: Xianjun Jiao <putaoshu@msn.com>
# // SPDX-FileCopyrightText: 2025 Xianjun Jiao
# // SPDX-License-Identifier: Apache-2.0 license

set -x

sync

mount /dev/mmcblk0p1 /mnt

cp BOOT.BIN /mnt/
cp devicetree.dtb /mnt/

cd /mnt/
sync

cd
umount /mnt

reboot now

set +x

