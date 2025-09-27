<!--
Author: Xianjun Jiao
SPDX-FileCopyrightText: 2025 Xianjun Jiao <putaoshu@msn.com>
SPDX-License-Identifier: Apache-2.0
-->

# Bluetooth Low Energy open FPGA/chip 

![](./media/fpga-ila-btle-signal-ch37.png)

## Prepare SD card image

Download 2022_r2 image file from https://wiki.analog.com/resources/tools-software/linux-software/kuiper-linux?redirect=1

For BOOT partition:
- Choose and apply correct Linux kernel image file according to "Configuring the SD Card for FPGA Projects".
- Use the devicetree.dtb and BOOT.BIN in BTLE/fpga/$HARDWARE/ and BTLE/fpga/helpers/ (See how to generate them in the "Full steps..." section)
- Use the following bootargs for uEnv.txt
  `bootargs=console=ttyPS0,115200 root=/dev/mmcblk0p2 rw earlycon rootfstype=ext4 rootwait clk_ignore_unused cpuidle.off=1 uio_pdrv_genirq.of_id=generic-uio`

$HARDWARE could be sdrpi, antsdr_e200. Please also put BTLE/fpga/helpers/update_BOOT_partition.sh into the /root/ directory on board Linux.

For rootfs partition:
- Change the board's IP to **10.10.10.10** (by changing /etc/dhcpcd.conf) and password **btle**.
- Add `nohup ./btle_ll &` at the end of /root/.profile

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
```

## See Bluetooth run

Use Vivado Hardware Manager to observe on FPGA ILA.

probe file: BTLE/BTLE-hw-img/fpga/$HARDWARE/system_top.ltx

Use ext_rx_crc_ok == 1 as trigger condition to capture BLE waveform and related AGC procedure in the ILA window.
