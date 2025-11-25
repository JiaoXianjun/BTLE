#!/bin/bash

# // Author: Xianjun Jiao <putaoshu@msn.com>
# // SPDX-FileCopyrightText: 2025 Xianjun Jiao
# // SPDX-License-Identifier: Apache-2.0 license

set -x

if [ "$#" -lt 1 ]; then
  echo "Please specify hardware platform: antsdr sdrpi antsdr_e200"
  exit 1
else
  HARDWARE=$1
fi

OFFICIAL_DIR_SAVE_FPGA_IMG=../../BTLE-hw-img/fpga/$HARDWARE
TMP_DIR_SAVE_FPGA_IMG=./BTLE-hw-img/fpga/$HARDWARE

if [ -f "../$HARDWARE/btle_$HARDWARE/system_top.xsa" ]; then
  mkdir -p $TMP_DIR_SAVE_FPGA_IMG
  rm -rf $TMP_DIR_SAVE_FPGA_IMG/*

  cp ../$HARDWARE/btle_$HARDWARE/system_top.xsa $TMP_DIR_SAVE_FPGA_IMG/system_top.xsa
else
  echo "../$HARDWARE/btle_$HARDWARE/system_top.xsa does not exist."
  echo "Try to fetch FPGA img from $OFFICIAL_DIR_SAVE_FPGA_IMG and save to $TMP_DIR_SAVE_FPGA_IMG/"
  if [ -f "$OFFICIAL_DIR_SAVE_FPGA_IMG/system_top.xsa" ]; then
    mkdir -p $TMP_DIR_SAVE_FPGA_IMG
    rm -rf $TMP_DIR_SAVE_FPGA_IMG/*

    cp $OFFICIAL_DIR_SAVE_FPGA_IMG/system_top.xsa $TMP_DIR_SAVE_FPGA_IMG/system_top.xsa
  else
    echo "$OFFICIAL_DIR_SAVE_FPGA_IMG/system_top.xsa does not exist. Please check!"
    exit 1
  fi
fi

if [ -f "../$HARDWARE/btle_$HARDWARE/btle_$HARDWARE.runs/impl_1/system_top.ltx" ]; then
  cp ../$HARDWARE/btle_$HARDWARE/btle_$HARDWARE.runs/impl_1/system_top.ltx $TMP_DIR_SAVE_FPGA_IMG/system_top.ltx
else
  echo "../$HARDWARE/btle_$HARDWARE/btle_$HARDWARE.runs/impl_1/system_top.ltx does not exist."
  echo "Try to fetch FPGA img from $OFFICIAL_DIR_SAVE_FPGA_IMG and save to $TMP_DIR_SAVE_FPGA_IMG/"
  if [ -f "$OFFICIAL_DIR_SAVE_FPGA_IMG/system_top.ltx" ]; then
    cp $OFFICIAL_DIR_SAVE_FPGA_IMG/system_top.ltx $TMP_DIR_SAVE_FPGA_IMG/system_top.ltx
  else
    echo "$OFFICIAL_DIR_SAVE_FPGA_IMG/system_top.ltx does not exist. Skip it."
  fi
fi

# HARDWARES="sdrpi antsdr_e200 antsdr"

# for hw in $HARDWARES; do
#     cp ../$hw/btle_$hw/system_top.xsa ../../BTLE-hw-img/fpga/$hw/system_top.xsa
#     cp ../$hw/btle_$hw/btle_$hw.runs/impl_1/system_top.ltx ../../BTLE-hw-img/fpga/$hw/system_top.ltx
# done

set +x

