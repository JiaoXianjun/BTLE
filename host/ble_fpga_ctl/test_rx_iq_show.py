# Author: Xianjun Jiao <putaoshu@msn.com>
# SPDX-FileCopyrightText: 2024 Xianjun Jiao
# SPDX-License-Identifier: Apache-2.0 license

import numpy as np
# import matplotlib
# matplotlib.use('TkAgg')
import matplotlib.pyplot as plt
import sys
import os

if __name__ == "__main__":
  freq_hz = np.uint64(1575e6)
  sampling_rate_hz = np.uint64(8e6)
  rx_iq_filename = 'rx_iq_'+str(freq_hz)+'Hz_'+str(sampling_rate_hz)+'sps.bin'

  ssh_cmd  = 'ssh root@10.10.10.10 ./btle_ll -q 1 -o 1 -n '+str(freq_hz)
  status = os.system(ssh_cmd)
  if status != 0:
    print('SSH command failed')
    sys.exit(1)

  scp_cmd = 'scp root@10.10.10.10:' + rx_iq_filename + ' ./'
  status = os.system(scp_cmd)
  if status != 0:
      print('SCP command failed')
      sys.exit(1)

  print(rx_iq_filename)
