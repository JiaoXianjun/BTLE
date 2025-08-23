source ~/Xilinx/Vitis/2022.2/settings64.sh
./build_boot_bin.sh ../../../BTLE-hw-img/fpga/sdrpi/system_top.xsa ./u-boot.elf
cp ./output_boot_bin/BOOT.BIN ./
echo "BOOT.BIN"

