#!/bin/bash

# // Author: Xianjun Jiao <putaoshu@msn.com>
# // SPDX-FileCopyrightText: 2025 Xianjun Jiao
# // SPDX-License-Identifier: Apache-2.0 license

# set rf parameters
cd /sys/bus/iio/devices/iio:device0
sleep 1
# cat ensm_mode_available
# cat ensm_mode
# echo fdd > ensm_mode
# cat ensm_mode

# echo 1 >  out_altvoltage1_TX_LO_powerdown
# cat out_altvoltage1_TX_LO_powerdown

echo 0 > in_voltage_filter_fir_en
echo 0 > out_voltage_filter_fir_en
# cat filter_fir_config

echo 2402000000 >  out_altvoltage0_RX_LO_frequency
cat out_altvoltage0_RX_LO_frequency
echo 5990000000 >  out_altvoltage1_TX_LO_frequency
cat out_altvoltage1_TX_LO_frequency

cat in_voltage_sampling_frequency
echo 8000000 >  in_voltage_sampling_frequency
cat in_voltage_sampling_frequency

cat out_voltage_sampling_frequency
echo 8000000 >  out_voltage_sampling_frequency
cat out_voltage_sampling_frequency

cat in_voltage_rf_bandwidth
echo 8000000 >  in_voltage_rf_bandwidth
cat in_voltage_rf_bandwidth

cat out_voltage_rf_bandwidth
echo 8000000 >  out_voltage_rf_bandwidth
cat out_voltage_rf_bandwidth

echo 0 >  out_altvoltage1_TX_LO_powerdown
cat out_altvoltage1_TX_LO_powerdown

iio_reg ad9361-phy 0x2 0x0
iio_reg ad9361-phy 0x2

cat in_voltage_filter_fir_en
cat out_voltage_filter_fir_en

cat in_voltage_gain_control_mode_available

cat in_voltage0_gain_control_mode
echo fast_attack > in_voltage0_gain_control_mode
cat in_voltage0_gain_control_mode

cat in_voltage1_gain_control_mode
echo fast_attack > in_voltage1_gain_control_mode
cat in_voltage1_gain_control_mode

cat in_voltage0_rssi
cat in_voltage1_rssi
