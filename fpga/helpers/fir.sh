#!/bin/bash

# // Author: Xianjun Jiao <putaoshu@msn.com>
# // SPDX-FileCopyrightText: 2025 Xianjun Jiao
# // SPDX-License-Identifier: Apache-2.0 license

cd /sys/bus/iio/devices/iio:device0

cat /root/ad9361_fir_smpl8M_pass0.8_stop1.1.ftr > filter_fir_config
echo 1 > in_voltage_filter_fir_en
echo 1 > out_voltage_filter_fir_en
cat filter_fir_config
cat in_voltage_filter_fir_en
cat out_voltage_filter_fir_en

cd 
