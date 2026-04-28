# Author: Xianjun Jiao <putaoshu@msn.com>
# SPDX-FileCopyrightText: 2024 Xianjun Jiao
# SPDX-License-Identifier: Apache-2.0 license

from datetime import datetime
from fileinput import filename

import numpy as np
# import matplotlib
# matplotlib.use('TkAgg')
import matplotlib.pyplot as plt

import argparse
import sys
import os

def water_fall(iq, fft_size, num_sample_feed_to_fft, sample_resolution):
  num_col = int((len(iq) - num_sample_feed_to_fft + 1) // sample_resolution)
  a = np.zeros((fft_size, num_col))

  for i in range(num_col):
    sp = i * sample_resolution
    ep = sp + num_sample_feed_to_fft
    a[:, i] = np.abs(np.fft.fft(iq[sp:ep], fft_size)) ** 2

  fft_size_half = fft_size // 2
  a = np.concatenate([a[fft_size_half:, :], a[:fft_size_half, :]], axis=0)

  return a

if __name__ == "__main__":
  freq_hz = np.uint64(2402e6)
  duration_ms = int(10)
  sampling_rate_hz = int(8e6)

  parser = argparse.ArgumentParser(
    description="Waterfall spectrum analyzer"
  )

  parser.add_argument("-f", "--filename", type=str, default="", help="Input IQ .bin file to avoid actual capture onboard")
  parser.add_argument("-n", "--freq_hz", type=int, default=freq_hz, help="Input frequency in Hz (default: "+str(freq_hz))
  parser.add_argument("-q", "--duration_ms", type=int, default=duration_ms, help="Input duration in ms (default: "+str(duration_ms))
  parser.add_argument("-s", "--sampling_rate_hz", type=int, default=sampling_rate_hz, help="Input sampling rate in Hz (default: "+str(sampling_rate_hz))

  args = parser.parse_args()

  if args.freq_hz:
    freq_hz = np.uint64(args.freq_hz)
  
  if args.duration_ms:
    duration_ms = int(args.duration_ms)
  
  if args.sampling_rate_hz:
    sampling_rate_hz = int(args.sampling_rate_hz)

  if args.filename:
    rx_iq_filename = args.filename
  else:
    rx_iq_filename = 'rx_iq_'+str(freq_hz)+'Hz_'+str(sampling_rate_hz)+'sps.bin'

    ssh_cmd  = 'ssh root@10.10.10.10 ./btle_ll -q '+str(duration_ms)+' -o 1 -n '+str(freq_hz)
    print(ssh_cmd)
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

  # name_without_ext = rx_iq_filename.rsplit('.', 1)[0]
  # date_time_str = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
  # new_filename = f"{name_without_ext}_{date_time_str}.bin"
  # os.rename(rx_iq_filename, new_filename)
  # print('Saved as ', new_filename)

  with open(rx_iq_filename, mode="rb") as file:
    my_bytes = file.read()

  rx_iq = np.frombuffer(my_bytes, dtype=np.int16)
  rx_complex = rx_iq[0::2] + 1j * rx_iq[1::2]  # the sampling rate is alraedy iq sampling rate
  rx_i = rx_iq[0::2]
  rx_q = rx_iq[1::2]
  # rx_abs = np.abs(rx_complex)

  # if len(rx_i) > 10000:
  #   print('Decide the start/end idx. Close figure and input ...')

  #   plt.plot(rx_i, 'b', label='I')
  #   plt.plot(rx_q, 'r', label='Q')
  #   plt.legend(loc='upper right')
  #   plt.grid(True)
  #   plt.title('Decide the start/end idx. Close figure and input ...')
  #   plt.show()

  #   start_index = int(input('Enter the start index for processing: '))
  #   end_index = int(input('Enter the end index for processing: '))
  #   rx_i = rx_i[start_index:end_index]
  #   rx_q = rx_q[start_index:end_index]

  #   # close the figure after user input
  #   plt.close()

  fig_timedomain_abs = plt.figure(1)
  fig_timedomain_abs.clf()

  td_abs = fig_timedomain_abs.add_subplot(111)
  td_abs.set_title('IQ plot')
  td_abs.set_xlabel("sample idx")
  td_abs.set_ylabel("I/Q")
  td_abs.plot(rx_i, 'b', label='I')
  td_abs.plot(rx_q, 'r', label='Q')
  td_abs.legend(loc='upper right')
  td_abs.grid(True)
  
  fig_timedomain_abs.canvas.flush_events()

  fft_size=128
  num_sample_feed_to_fft=10
  sample_resolution=2
  a = water_fall(rx_complex, fft_size=fft_size, num_sample_feed_to_fft=num_sample_feed_to_fft, sample_resolution=sample_resolution)

  time_resolution_us = (sample_resolution*(1/sampling_rate_hz))*1e6
  # print(a.shape)
  # print(a[:, 0:10])

  fig_waterfall = plt.figure(0)
  fig_waterfall.clf()

  waterfall = fig_waterfall.add_subplot(111)
  waterfall.set_title('Spectrogram')
  waterfall.set_xlabel("Time(us)")
  waterfall.set_ylabel("Freq(Hz)")
  waterfall_shw = waterfall.imshow(a, aspect='auto', origin='lower', extent=[0, a.shape[1]*time_resolution_us, -sampling_rate_hz/2, sampling_rate_hz/2])
  plt.colorbar(waterfall_shw)
  fig_waterfall.canvas.flush_events()

  plt.show()
