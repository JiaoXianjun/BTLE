<!--
Author: Xianjun Jiao
SPDX-FileCopyrightText: 2025 Xianjun Jiao <putaoshu@msn.com>
SPDX-License-Identifier: Apache-2.0
-->

![](./media/fpga-ila-btle-signal-ch37.png)

Full steps from scratch to update FPGA on board.

```
git clone --recursive git@github.com:JiaoXianjun/BTLE.git
cd BTLE
git checkout fpga_dev
git submodule update

# Change the Vivado install directory ~/Xilinx/ accordingly!

cd fpga/
./build-adi-ip.sh ~/Xilinx/
# take a while...
cd sdrpi/
./btle.sh &

# Generate Bitstream in the Vivado
# take a while...
# In Vivado: File --> Export --> Export Hardware --> Next --> Include bitstream --> Next --> Next --> Finish

cd helpers/
./all_gen_and_scp.sh
# "btle" is the password of the ssh to board
ssh root@10.10.10.10
# on board:
./update_BOOT_partition.sh

# wait for board fully rebooting
# Use Vivado Hardware Manager to observe on FPGA ILA.
# probe file: BTLE/BTLE-hw-img/fpga/sdrpi/system_top.ltx
```
