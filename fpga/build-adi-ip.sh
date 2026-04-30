#!/bin/bash

# // Author: Xianjun Jiao <putaoshu@msn.com>
# // SPDX-FileCopyrightText: 2025 Xianjun Jiao
# // SPDX-License-Identifier: Apache-2.0 license

XILINX_DIR=$1
git submodule init adi-hdl
git submodule update adi-hdl
cd ./adi-hdl/
git reset --hard
git fetch
git checkout 2022_R2
git reset --hard 2022_R2
source $XILINX_DIR/Vivado/2022.2/settings64.sh
cd library/
make

