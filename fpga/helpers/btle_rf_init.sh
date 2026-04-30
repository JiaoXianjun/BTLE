#!/bin/bash

# // Author: Xianjun Jiao <putaoshu@msn.com>
# // SPDX-FileCopyrightText: 2025 Xianjun Jiao
# // SPDX-License-Identifier: Apache-2.0 license

# re-initialize rf
while [ ! -d "/sys/bus/spi/drivers/ad9361/spi0.0" ]
do
  echo "Waiting for /sys/bus/spi/drivers/ad9361/spi0.0"
  sleep 0.2
done
cd /sys/bus/spi/drivers/ad9361/
echo spi0.0 > unbind
echo spi0.0 > bind

while [ ! -d "/sys/bus/platform/drivers/cf_axi_adc/79020000.cf-ad9361-lpc" ]
do
  echo "Waiting for /sys/bus/platform/drivers/cf_axi_adc/79020000.cf-ad9361-lpc"
  sleep 0.2
done
cd /sys/bus/platform/drivers/cf_axi_adc/
echo 79020000.cf-ad9361-lpc  > unbind
echo 79020000.cf-ad9361-lpc  > bind

# set rf parameters
cd /sys/bus/iio/devices/iio:device0

# cat ensm_mode_available
# cat ensm_mode
# echo fdd > ensm_mode
# cat ensm_mode

# echo 1 >  out_altvoltage1_TX_LO_powerdown
# cat out_altvoltage1_TX_LO_powerdown

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
echo 2000000 >  in_voltage_rf_bandwidth
cat in_voltage_rf_bandwidth

cat out_voltage_rf_bandwidth
echo 2000000 >  out_voltage_rf_bandwidth
cat out_voltage_rf_bandwidth

cat in_voltage_gain_control_mode_available

cat in_voltage0_gain_control_mode
echo fast_attack > in_voltage0_gain_control_mode
cat in_voltage0_gain_control_mode

cat in_voltage1_gain_control_mode
echo fast_attack > in_voltage1_gain_control_mode
cat in_voltage1_gain_control_mode

cat in_voltage0_rssi
cat in_voltage1_rssi
