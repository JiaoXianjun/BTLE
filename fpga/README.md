<!--
Author: Xianjun Jiao
SPDX-FileCopyrightText: 2025 Xianjun Jiao <putaoshu@msn.com>
SPDX-License-Identifier: Apache-2.0
-->

# Bluetooth Low Energy open FPGA/chip 

![](./media/fpga-ila-btle-signal-ch37.png)

## Prepare SD card image

Download 2022_r2 image file from https://wiki.analog.com/resources/tools-software/linux-software/kuiper-linux?redirect=1

Choose and apply correct Linux kernel image file in BOOT partition according to "Configuring the SD Card for FPGA Projects".

Use the devicetree.dtb and BOOT.BIN in BTLE/fpga/$HARDWARE/ and BTLE/fpga/helpers/ (See how to generate them in the "Full steps..." section)

$HARDWARE could be sdrpi, antsdr_e200. Please also put BTLE/fpga/helpers/update_BOOT_partition.sh into the /root/ directory on board Linux.

Change the board's IP to **10.10.10.10** and password **btle**.

## Full steps from scratch to update FPGA on board

```
git clone --recursive git@github.com:JiaoXianjun/BTLE.git
cd BTLE
git checkout fpga_dev
git submodule update

# Change the Vivado install directory ~/Xilinx/ accordingly!

cd fpga/
./build-adi-ip.sh ~/Xilinx/
# take a while...
cd $HARDWARE/
./btle.sh &

# Generate Bitstream in the Vivado
# take a while...
# In Vivado: File --> Export --> Export Hardware --> Next --> Include bitstream --> Next --> Next --> Finish

cd ../helpers/
./all_gen_and_scp.sh $HARDWARE
# "btle" is the password of the ssh to board

# wait for board fully rebooting
# Use Vivado Hardware Manager to observe on FPGA ILA.
# probe file: BTLE/BTLE-hw-img/fpga/$HARDWARE/system_top.ltx
```
