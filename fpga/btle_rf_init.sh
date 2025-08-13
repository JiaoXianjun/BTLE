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
