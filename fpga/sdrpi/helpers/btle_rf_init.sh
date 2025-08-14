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

cat ensm_mode_available
cat ensm_mode
echo rx > ensm_mode
cat ensm_mode

echo 0 >  out_altvoltage1_TX_LO_powerdown
cat out_altvoltage1_TX_LO_powerdown
echo 2402000000 >  out_altvoltage0_RX_LO_frequency
cat out_altvoltage0_RX_LO_frequency

