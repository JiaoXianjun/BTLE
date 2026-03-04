#!/bin/bash

set -x
gcc -O3 -o ble_fpga_ctl ble_fpga_ctl.c
gcc -O3 -o ble_send_cmd ble_send_cmd.c
set +x

