// BTLE packet transmit tool by Jiao Xianjun (putaoshu@gmail.com)

/*
 * Copyright 2012 Jared Boone <jared@sharebrained.com>
 * Copyright 2013-2014 Benjamin Vernoux <titanmkd@gmail.com>
 *
 * This file is part of HackRF.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; see the file COPYING.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street,
 * Boston, MA 02110-1301, USA.
 */

#include <hackrf.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>

#ifndef bool
typedef int bool;
#define true 1
#define false 0
#endif

#ifdef _WIN32
#include <windows.h>

#ifdef _MSC_VER

#ifdef _WIN64
typedef int64_t ssize_t;
#else
typedef int32_t ssize_t;
#endif

#define strtoull _strtoui64
#define snprintf _snprintf

int gettimeofday(struct timeval *tv, void* ignored)
{
	FILETIME ft;
	unsigned __int64 tmp = 0;
	if (NULL != tv) {
		GetSystemTimeAsFileTime(&ft);
		tmp |= ft.dwHighDateTime;
		tmp <<= 32;
		tmp |= ft.dwLowDateTime;
		tmp /= 10;
		tmp -= 11644473600000000Ui64;
		tv->tv_sec = (long)(tmp / 1000000UL);
		tv->tv_usec = (long)(tmp % 1000000UL);
	}
	return 0;
}

#endif
#endif

#if defined(__GNUC__)
#include <unistd.h>
#include <sys/time.h>
#endif

#include <signal.h>

#define FREQ_ONE_MHZ (1000000ull)
#define DEFAULT_BASEBAND_FILTER_BANDWIDTH (5000000) /* 5MHz default */

#if defined _WIN32
	#define sleep(a) Sleep( (a*1000) )
#endif

static float
TimevalDiff(const struct timeval *a, const struct timeval *b)
{
   return (a->tv_sec - b->tv_sec) + 1e-6f * (a->tv_usec - b->tv_usec);
}

#define MAX_NUM_SAMPLE (8192)

uint64_t freq_hz = 2480000000ull;
const uint32_t sample_rate_hz = 8000000;
uint32_t baseband_filter_bw_hz;

volatile bool do_exit = false;

volatile bool stop_tx = true;
volatile char tx_buf[MAX_NUM_SAMPLE*2];
volatile int tx_len;
int tx_callback(hackrf_transfer* transfer) {
  if (~stop_tx) {
    if ( tx_len <= transfer->valid_length ) {
      memcpy(transfer->buffer, (char *)tx_buf, tx_len);
      memset(transfer->buffer + tx_len, 0, transfer->valid_length - tx_len);
      stop_tx = true;
    } else {
      memset(transfer->buffer, 0, transfer->valid_length);
      return(-1);
    }
  } else {
    memset(transfer->buffer, 0, transfer->valid_length);
  }
  return(0);
}

static hackrf_device* device = NULL;

#ifdef _MSC_VER
BOOL WINAPI
sighandler(int signum)
{
	if (CTRL_C_EVENT == signum) {
		fprintf(stdout, "Caught signal %d\n", signum);
		do_exit = true;
		return TRUE;
	}
	return FALSE;
}
#else
void sigint_callback_handler(int signum)
{
	fprintf(stdout, "Caught signal %d\n", signum);
	do_exit = true;
}
#endif

static void usage() {
//	printf("Usage:\n");
//	printf("\t-r <filename> # Receive data into file.\n");
//	printf("\t-t <filename> # Transmit data from file.\n");
//	printf("\t-w # Receive data into file with WAV header and automatic name.\n");
//	printf("\t   # This is for SDR# compatibility and may not work with other software.\n");
//	printf("\t[-f freq_hz] # Frequency in Hz [%sMHz to %sMHz].\n",
//		u64toa((FREQ_MIN_HZ/FREQ_ONE_MHZ),&ascii_u64_data1),
//		u64toa((FREQ_MAX_HZ/FREQ_ONE_MHZ),&ascii_u64_data2));
//	printf("\t[-i if_freq_hz] # Intermediate Frequency (IF) in Hz [%sMHz to %sMHz].\n",
//		u64toa((IF_MIN_HZ/FREQ_ONE_MHZ),&ascii_u64_data1),
//		u64toa((IF_MAX_HZ/FREQ_ONE_MHZ),&ascii_u64_data2));
//	printf("\t[-o lo_freq_hz] # Front-end Local Oscillator (LO) frequency in Hz [%sMHz to %sMHz].\n",
//		u64toa((LO_MIN_HZ/FREQ_ONE_MHZ),&ascii_u64_data1),
//		u64toa((LO_MAX_HZ/FREQ_ONE_MHZ),&ascii_u64_data2));
//	printf("\t[-m image_reject] # Image rejection filter selection, 0=bypass, 1=low pass, 2=high pass.\n");
//	printf("\t[-a amp_enable] # RX/TX RF amplifier 1=Enable, 0=Disable.\n");
//	printf("\t[-p antenna_enable] # Antenna port power, 1=Enable, 0=Disable.\n");
//	printf("\t[-l gain_db] # RX LNA (IF) gain, 0-40dB, 8dB steps\n");
//	printf("\t[-g gain_db] # RX VGA (baseband) gain, 0-62dB, 2dB steps\n");
//	printf("\t[-x gain_db] # TX VGA (IF) gain, 0-47dB, 1dB steps\n");
//	printf("\t[-s sample_rate_hz] # Sample rate in Hz (8/10/12.5/16/20MHz, default %sMHz).\n",
//		u64toa((DEFAULT_SAMPLE_RATE_HZ/FREQ_ONE_MHZ),&ascii_u64_data1));
//	printf("\t[-n num_samples] # Number of samples to transfer (default is unlimited).\n");
//	printf("\t[-b baseband_filter_bw_hz] # Set baseband filter bandwidth in MHz.\n\tPossible values: 1.75/2.5/3.5/5/5.5/6/7/8/9/10/12/14/15/20/24/28MHz, default < sample_rate_hz.\n" );
}

inline int open_board() {
  int result;
  unsigned int txvga_gain=47;

	/* Compute nearest freq for bw filter */
  baseband_filter_bw_hz = hackrf_compute_baseband_filter_bw(DEFAULT_BASEBAND_FILTER_BANDWIDTH);

	result = hackrf_init();
	if( result != HACKRF_SUCCESS ) {
		printf("open_board: hackrf_init() failed: %s (%d)\n", hackrf_error_name(result), result);
		usage();
		return(-1);
	}

	result = hackrf_open(&device);
	if( result != HACKRF_SUCCESS ) {
		printf("open_board: hackrf_open() failed: %s (%d)\n", hackrf_error_name(result), result);
		usage();
		return(-1);
	}

#ifdef _MSC_VER
	SetConsoleCtrlHandler( (PHANDLER_ROUTINE) sighandler, TRUE );
#else
	signal(SIGINT, &sigint_callback_handler);
	signal(SIGILL, &sigint_callback_handler);
	signal(SIGFPE, &sigint_callback_handler);
	signal(SIGSEGV, &sigint_callback_handler);
	signal(SIGTERM, &sigint_callback_handler);
	signal(SIGABRT, &sigint_callback_handler);
#endif

	printf("open_board: call hackrf_sample_rate_set(%u Hz/%.03f MHz)\n", sample_rate_hz,((float)sample_rate_hz/(float)FREQ_ONE_MHZ));
	result = hackrf_set_sample_rate_manual(device, sample_rate_hz, 1);
	if( result != HACKRF_SUCCESS ) {
		printf("open_board: hackrf_sample_rate_set() failed: %s (%d)\n", hackrf_error_name(result), result);
		usage();
		return(-1);
	}

	printf("open_board: call hackrf_baseband_filter_bandwidth_set(%d Hz/%.03f MHz)\n",
			baseband_filter_bw_hz, ((float)baseband_filter_bw_hz/(float)FREQ_ONE_MHZ));

	result = hackrf_set_baseband_filter_bandwidth(device, baseband_filter_bw_hz);
	if( result != HACKRF_SUCCESS ) {
		printf("open_board: hackrf_baseband_filter_bandwidth_set() failed: %s (%d)\n", hackrf_error_name(result), result);
		usage();
		return(-1);
	}

  result = hackrf_set_txvga_gain(device, txvga_gain);
  if( result != HACKRF_SUCCESS ) {
    printf("open_board: hackrf_set_txvga_gain() failed: %s (%d)\n", hackrf_error_name(result), result);
    usage();
    return(-1);
  }

  result = hackrf_start_tx(device, tx_callback, NULL);
  if( result != HACKRF_SUCCESS ) {
    printf("open_board: hackrf_start_tx() failed: %s (%d)\n", hackrf_error_name(result), result);
    usage();
    return(-1);
  }

  printf("open_board: call hackrf_set_freq(%.03f MHz)\n", ((double)freq_hz/(double)FREQ_ONE_MHZ) );
  result = hackrf_set_freq(device, freq_hz);
  if( result != HACKRF_SUCCESS ) {
    printf("open_board: hackrf_set_freq() failed: %s (%d)\n", hackrf_error_name(result), result);
    usage();
    return(-1);
  }

  printf("open_board: call hackrf_set_amp_enable(%u)\n", 1);
  result = hackrf_set_amp_enable(device, (uint8_t)1);
  if( result != HACKRF_SUCCESS ) {
    printf("open_board: hackrf_set_amp_enable() failed: %s (%d)\n", hackrf_error_name(result), result);
    usage();
    return(-1);
  }

  return(0);
}

inline void close_board() {
  int result;

	if(device != NULL)
	{
    result = hackrf_stop_tx(device);
    if( result != HACKRF_SUCCESS ) {
      printf("close_board: hackrf_stop_tx() failed: %s (%d)\n", hackrf_error_name(result), result);
    }else {
      printf("close_board: hackrf_stop_tx() done\n");
    }

		result = hackrf_close(device);
		if( result != HACKRF_SUCCESS )
		{
			printf("close_board: hackrf_close() failed: %s (%d)\n", hackrf_error_name(result), result);
		}else {
			printf("close_board: hackrf_close() done\n");
		}

		hackrf_exit();
		printf("hackrf_exit() done\n");
	}
}

inline int tx_one_buf(char *buf, int length) {
  memcpy((char *)tx_buf, buf, length);
  tx_len = length;

  stop_tx = false;

  while( (hackrf_is_streaming(device) == HACKRF_TRUE) &&
      (do_exit == false) )
  {
    if (stop_tx) {
      break;
    }
  }

  if (do_exit)
  {
    printf("\ntx_one_buf: Abnormal, exiting...\n");
    return(-1);
  }

  return(0);
}

int main(int argc, char** argv) {

  int i;

  if ( open_board() == -1 )
    return(-1);

  char buf[6352];
  FILE *fp = fopen("fnd_single_packet.bin", "rb");
  fread(buf, sizeof(char), 6352, fp);
  fclose(fp);

  for (i=0; i<10; i++) {
    if ( tx_one_buf(buf, 6352) == -1 ){
      close_board();
      return(-1);
    }
    printf("%d\n", i);
    sleep(0.05);

    if (do_exit)
      break;
  }

  close_board();
	printf("exit\n");
	return(0);
}
