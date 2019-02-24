// BTLE packet sender tool by Xianjun Jiao (putaoshu@gmail.com)

/*
 * Copyright 2012 Jared Boone <jared@sharebrained.com>
 * Copyright 2013-2014 Benjamin Vernoux <titanmkd@gmail.com>
 *
 * This file is part of HackRF and bladeRF.
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

#include "common.h"

#ifdef USE_BLADERF
#include <libbladeRF.h>
#else
#include <hackrf.h>
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <ctype.h>
#include <math.h>

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

#if defined _WIN32
	#define sleep(a) Sleep( (a*1000) )
#endif

static inline int
TimevalDiff(const struct timeval *a, const struct timeval *b)
{
   return( (a->tv_sec - b->tv_sec)*1000000 + (a->tv_usec - b->tv_usec) );
}

#ifdef USE_BLADERF
#define SAMPLE_PER_SYMBOL 4
#else
#define SAMPLE_PER_SYMBOL 4
#endif // USE_BLADERF

//#define AMPLITUDE (110.0)
#define AMPLITUDE (127.0)
#define MOD_IDX (0.5)
//#define LEN_GAUSS_FILTER (11) // pre 8, post 3
#define LEN_GAUSS_FILTER (4) // pre 2, post 2
#define MAX_NUM_INFO_BYTE (43)
#define MAX_NUM_PHY_BYTE (47)
#define MAX_NUM_PHY_SAMPLE ((MAX_NUM_PHY_BYTE*8*SAMPLE_PER_SYMBOL)+(LEN_GAUSS_FILTER*SAMPLE_PER_SYMBOL))

#if SAMPLE_PER_SYMBOL==10
float gauss_coef[LEN_GAUSS_FILTER*SAMPLE_PER_SYMBOL] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5.551115e-17, 1.165734e-15, 2.231548e-14, 3.762546e-13, 5.522305e-12, 7.048379e-11, 7.826021e-10, 7.561773e-09, 6.360787e-08, 4.660229e-07, 2.975472e-06, 1.656713e-05, 8.050684e-05, 3.417749e-04, 1.269100e-03, 4.128134e-03, 1.178514e-02, 2.959908e-02, 6.560143e-02, 1.288102e-01, 2.252153e-01, 3.529425e-01, 4.999195e-01, 6.466991e-01, 7.735126e-01, 8.670612e-01, 9.226134e-01, 9.408018e-01, 9.226134e-01, 8.670612e-01, 7.735126e-01, 6.466991e-01, 4.999195e-01, 3.529425e-01, 2.252153e-01, 1.288102e-01, 6.560143e-02, 2.959908e-02, 1.178514e-02, 4.128134e-03, 1.269100e-03, 3.417749e-04, 8.050684e-05, 1.656713e-05, 2.975472e-06, 4.660229e-07, 6.360787e-08, 7.561773e-09, 7.826021e-10, 7.048379e-11, 5.522305e-12, 3.762546e-13, 2.231548e-14, 1.165734e-15, 5.551115e-17, 0, 0};
#endif
#if SAMPLE_PER_SYMBOL==8
float gauss_coef[LEN_GAUSS_FILTER*SAMPLE_PER_SYMBOL] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5.551115e-16, 2.231548e-14, 7.461809e-13, 2.007605e-11, 4.343541e-10, 7.561773e-09, 1.060108e-07, 1.197935e-06, 1.092397e-05, 8.050684e-05, 4.804052e-04, 2.326833e-03, 9.176993e-03, 2.959908e-02, 7.852842e-02, 1.727474e-01, 3.185668e-01, 4.999195e-01, 6.809419e-01, 8.249246e-01, 9.122945e-01, 9.408018e-01, 9.122945e-01, 8.249246e-01, 6.809419e-01, 4.999195e-01, 3.185668e-01, 1.727474e-01, 7.852842e-02, 2.959908e-02, 9.176993e-03, 2.326833e-03, 4.804052e-04, 8.050684e-05, 1.092397e-05, 1.197935e-06, 1.060108e-07, 7.561773e-09, 4.343541e-10, 2.007605e-11, 7.461809e-13, 2.231548e-14, 5.551115e-16, 0, 0};
#endif
#if SAMPLE_PER_SYMBOL==6
float gauss_coef[LEN_GAUSS_FILTER*SAMPLE_PER_SYMBOL] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1.665335e-16, 2.231548e-14, 2.290834e-12, 1.596947e-10, 7.561773e-09, 2.436464e-07, 5.354390e-06, 8.050684e-05, 8.317661e-04, 5.941078e-03, 2.959908e-02, 1.042296e-01, 2.646999e-01, 4.999195e-01, 7.344630e-01, 8.898291e-01, 9.408018e-01, 8.898291e-01, 7.344630e-01, 4.999195e-01, 2.646999e-01, 1.042296e-01, 2.959908e-02, 5.941078e-03, 8.317661e-04, 8.050684e-05, 5.354390e-06, 2.436464e-07, 7.561773e-09, 1.596947e-10, 2.290834e-12, 2.231548e-14, 1.665335e-16, 0};
#endif
#if SAMPLE_PER_SYMBOL==4
//float gauss_coef[LEN_GAUSS_FILTER*SAMPLE_PER_SYMBOL] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2.231548e-14, 2.007605e-11, 7.561773e-09, 1.197935e-06, 8.050684e-05, 2.326833e-03, 2.959908e-02, 1.727474e-01, 4.999195e-01, 8.249246e-01, 9.408018e-01, 8.249246e-01, 4.999195e-01, 1.727474e-01, 2.959908e-02, 2.326833e-03, 8.050684e-05, 1.197935e-06, 7.561773e-09, 2.007605e-11, 2.231548e-14, 0};
float gauss_coef[LEN_GAUSS_FILTER*SAMPLE_PER_SYMBOL] = {7.561773e-09, 1.197935e-06, 8.050684e-05, 2.326833e-03, 2.959908e-02, 1.727474e-01, 4.999195e-01, 8.249246e-01, 9.408018e-01, 8.249246e-01, 4.999195e-01, 1.727474e-01, 2.959908e-02, 2.326833e-03, 8.050684e-05, 1.197935e-06};
#endif

uint64_t freq_hz;

volatile bool do_exit = false;

volatile int stop_tx = 1;
volatile int tx_len, tx_buffer_length, tx_valid_length;
volatile int tx_count = 0;

#define NUM_PRE_SEND_DATA (256)

#ifdef USE_BLADERF
#define NUM_BLADERF_BUF_SAMPLE 4096
volatile int16_t tx_buf[NUM_BLADERF_BUF_SAMPLE*2];
struct bladerf *dev = NULL;
#else
//volatile char tx_buf[MAX_NUM_PHY_SAMPLE*2];
#define HACKRF_ONBOARD_BUF_SIZE (32768) // in usb_bulk_buffer.h
#define HACKRF_USB_BUF_SIZE (4096) // in hackrf.c lib_device->buffer_size
char tx_zeros[HACKRF_USB_BUF_SIZE-NUM_PRE_SEND_DATA] = {0};
volatile char *tx_buf;
static hackrf_device* device = NULL;

int tx_callback(hackrf_transfer* transfer) {
  #if 0
  tx_buffer_length = transfer->buffer_length; //always is 262144 in old driver, now it is 4096. (3008 for maximum BTLE packet)
  tx_valid_length = transfer->valid_length; //always is 262144 in old driver, now it is 4096. (3008 for maximum BTLE packet)
  tx_count++;
  #endif
  
  #if 0
  if (~stop_tx) {
    if ( (tx_len+NUM_PRE_SEND_DATA) <= transfer->valid_length ) {
// don't feed data to the beginning of transfer->buffer, because tx needs warming up
      memset(transfer->buffer, 0, transfer->valid_length);
      memcpy(transfer->buffer+NUM_PRE_SEND_DATA, (char *)(tx_buf), tx_len);
      stop_tx = 1;
    } else {
      memset(transfer->buffer, 0, transfer->valid_length);
      stop_tx = 2;
      return(-1);
    }
  } else {
    memset(transfer->buffer, 0, transfer->valid_length);
  }
  #endif
  
  #if 0 // ----------------- simple one   ----------------
  if (~stop_tx) {
    memset(transfer->buffer, 0, NUM_PRE_SEND_DATA);
    memcpy(transfer->buffer+NUM_PRE_SEND_DATA, (char *)(tx_buf), tx_len);
    stop_tx = 1;
  } else {
    memset(transfer->buffer, 0, transfer->valid_length);
  }
  #endif
  
  #if 1
  int size_left;
  if (stop_tx == 0) {
    memset(transfer->buffer, 0, NUM_PRE_SEND_DATA);
    memcpy(transfer->buffer+NUM_PRE_SEND_DATA, (char *)(tx_buf), tx_len);

    size_left = (transfer->valid_length - tx_len - NUM_PRE_SEND_DATA);
    memset(transfer->buffer+NUM_PRE_SEND_DATA+tx_len, 0, size_left);
  } else {
    memset(transfer->buffer, 0, transfer->valid_length);
  }
  stop_tx++;
  #endif
  
  //lib_device->transfer_count = 4;
  #if 0
  int size_left;
  switch(stop_tx) {
    
    case 0:
      memset(transfer->buffer, 0, NUM_PRE_SEND_DATA);
      memcpy(transfer->buffer+NUM_PRE_SEND_DATA, (char *)(tx_buf), tx_len);

      size_left = (transfer->valid_length - tx_len - NUM_PRE_SEND_DATA);
      memset(transfer->buffer+NUM_PRE_SEND_DATA+tx_len, 0, size_left);

      stop_tx = 1;
      break;
      
    case 1:
      memset(transfer->buffer, 0, transfer->valid_length);
      stop_tx = 2;
      break;
      
    case 2:
      memset(transfer->buffer, 0, transfer->valid_length);
      stop_tx = 3;
      break;
    
    case 3:
      memset(transfer->buffer, 0, transfer->valid_length);
      stop_tx = 4;
      break;
    
    case 4:
      memset(transfer->buffer, 0, transfer->valid_length);
      stop_tx = 5;
      break;

    case 5:
      memset(transfer->buffer, 0, transfer->valid_length);
      stop_tx = 6;
      break;

    case 6:
      memset(transfer->buffer, 0, transfer->valid_length);
      stop_tx = 7;
      break;
      
    case 7:
      memset(transfer->buffer, 0, transfer->valid_length);
      stop_tx = 8;
      break;
      
    case 8:
      memset(transfer->buffer, 0, transfer->valid_length);
      stop_tx = 9;
      break;

    default:
      memset(transfer->buffer, 0, transfer->valid_length);
      stop_tx = 9;
      break;
      
  }
  #endif
  
  return(0);
}
#endif

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
  printf("BLE packet generator. Xianjun Jiao. putaoshu@msn.com\n\n");
	printf("Usage:\n");
	printf("btle_tx packet1 packet2 ... packetX ...  rN\n");
	printf("or\n");
	printf("./btle_tx packets.txt\n");
	printf("(packets.txt contains parameters: packet1 ... packetX rN\n");
  printf("\nA packet sequence is composed by packet1 packet2 ... packetX\n");
  printf("rN means that the sequence will be repeated for N times\n");
  printf("packetX is packet descriptor string.\n");
  printf("For the format, see README for detailed information.\n");
}

inline void set_freq_by_channel_number(int channel_number) {

  if ( channel_number == 37 ) {
    freq_hz = 2402000000ull;
  } else if (channel_number == 38) {
    freq_hz = 2426000000ull;
  } else if (channel_number == 39) {
    freq_hz = 2480000000ull;
  } else if (channel_number >=0 && channel_number <= 10 ) {
    freq_hz = 2404000000ull + channel_number*2000000ull;
  } else if (channel_number >=11 && channel_number <= 36 ) {
    freq_hz = 2428000000ull + (channel_number-11)*2000000ull;
  }
}

#ifdef USE_BLADERF

inline int init_board() {
  int status;
  unsigned int actual;

  #ifdef _MSC_VER
    SetConsoleCtrlHandler( (PHANDLER_ROUTINE) sighandler, TRUE );
  #else
  if (signal(SIGINT, sigint_callback_handler) == SIG_ERR ||
      signal(SIGTERM, sigint_callback_handler) == SIG_ERR) {
      fprintf(stderr, "Failed to set up signal handler\n");
      return EXIT_FAILURE;
  }
  #endif

  status = bladerf_open(&dev, NULL);
  if (status < 0) {
      fprintf(stderr, "Failed to open device: %s\n", bladerf_strerror(status));
      return EXIT_FAILURE;
  } else  {
    fprintf(stdout, "open device: %s\n", bladerf_strerror(status));
  }
  
  status = bladerf_is_fpga_configured(dev);
  if (status < 0) {
      fprintf(stderr, "Failed to determine FPGA state: %s\n",
              bladerf_strerror(status));
      return EXIT_FAILURE;
  } else if (status == 0) {
      fprintf(stderr, "Error: FPGA is not loaded.\n");
      bladerf_close(dev);
      return EXIT_FAILURE;
  } else  {
    fprintf(stdout, "FPGA is loaded.\n");
  }
  
  status = bladerf_set_frequency(dev, BLADERF_MODULE_TX, 2402000000ull);
  if (status != 0) {
      fprintf(stderr, "Failed to set frequency: %s\n",
              bladerf_strerror(status));
      bladerf_close(dev);
      return EXIT_FAILURE;
  } else {
      fprintf(stdout, "set frequency: %lluHz %s\n", 2402000000ull,
              bladerf_strerror(status));
  }

  status = bladerf_set_sample_rate(dev, BLADERF_MODULE_TX, SAMPLE_PER_SYMBOL*1000000ul, &actual);
  if (status != 0) {
      fprintf(stderr, "Failed to set sample rate: %s\n",
              bladerf_strerror(status));
      bladerf_close(dev);
      return EXIT_FAILURE;
  } else {
    fprintf(stdout, "set sample rate: %dHz %s\n", actual,
              bladerf_strerror(status));
  }
  
  status = bladerf_set_bandwidth(dev, BLADERF_MODULE_TX, SAMPLE_PER_SYMBOL*1000000ul/2, &actual);
  if (status != 0) {
      fprintf(stderr, "Failed to set bandwidth: %s\n",
              bladerf_strerror(status));
      bladerf_close(dev);
      return EXIT_FAILURE;
  } else {
    fprintf(stdout, "bladerf_set_bandwidth: %d %s\n", actual,
              bladerf_strerror(status));
  }
  
  status = bladerf_set_gain(dev, BLADERF_MODULE_TX, 57);
  if (status != 0) {
      fprintf(stderr, "Failed to set gain: %s\n",
              bladerf_strerror(status));
      bladerf_close(dev);
      return EXIT_FAILURE;
  } else {
    fprintf(stdout, "bladerf_set_gain: %d %s\n", 57,
              bladerf_strerror(status));
  }

#if 0 // old version do not have this API
  status = bladerf_get_gain(dev, BLADERF_MODULE_TX, &actual);
  if (status != 0) {
      fprintf(stderr, "Failed to get gain: %s\n",
              bladerf_strerror(status));
      bladerf_close(dev);
      return EXIT_FAILURE;
  } else {
    fprintf(stdout, "bladerf_get_gain: %d %s\n", actual,
              bladerf_strerror(status));
  }
#endif

  status = bladerf_sync_config(dev,
                                BLADERF_MODULE_TX,
                                BLADERF_FORMAT_SC16_Q11,
                                32,
                                NUM_BLADERF_BUF_SAMPLE,
                                16,
                                10);

  if (status != 0) {
      fprintf(stderr, "Failed to initialize TX sync handle: %s\n",
                bladerf_strerror(status));
      bladerf_close(dev);
      return EXIT_FAILURE;
  } else {
    fprintf(stdout, "bladerf_sync_config: %s\n",
              bladerf_strerror(status));
  }

  status = bladerf_enable_module(dev, BLADERF_MODULE_TX, true);
  if (status < 0) {
      fprintf(stderr, "Failed to enable module: %s\n",
              bladerf_strerror(status));
      bladerf_close(dev);
      return EXIT_FAILURE;
  } else {
    fprintf(stdout, "enable module true: %s\n",
              bladerf_strerror(status));
  }

  return(0);
}

void close_board(){
  int status;

  status = bladerf_enable_module(dev, BLADERF_MODULE_TX, false);
  if (status < 0) {
      fprintf(stderr, "Failed to enable module: %s\n",
              bladerf_strerror(status));
  } else {
    fprintf(stdout, "enable module false: %s\n", bladerf_strerror(status));
  }

  bladerf_close(dev);

  printf("bladeRF closed.\n");
}
void exit_board() {
  return;
}
inline int tx_one_buf(char *buf, int length, int channel_number) {
  int status, i;

  set_freq_by_channel_number(channel_number);

  memset( (void *)tx_buf, 0, NUM_BLADERF_BUF_SAMPLE*2*sizeof(tx_buf[0]) );

  for (i=(NUM_BLADERF_BUF_SAMPLE*2-length); i<(NUM_BLADERF_BUF_SAMPLE*2); i++) {
    tx_buf[i] = ( (int)( buf[i-(NUM_BLADERF_BUF_SAMPLE*2-length)] ) )*16;
  }

  // Transmit samples
  status = bladerf_sync_tx(dev, (void *)tx_buf, NUM_BLADERF_BUF_SAMPLE, NULL, 10);
  if (status != 0) {
    printf("tx_one_buf: Failed to TX samples 1: %s\n",
             bladerf_strerror(status));
    return(-1);
  }

  if (do_exit)
  {
    printf("\ntx_one_buf: Exiting...\n");
    return(-1);
  }

  return(0);
}

#else
int init_board() {
	int result = hackrf_init();
	if( result != HACKRF_SUCCESS ) {
		printf("open_board: hackrf_init() failed: %s (%d)\n", hackrf_error_name(result), result);
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

  return(0);
}

inline int open_board() {
  int result;

	result = hackrf_open(&device);
	if( result != HACKRF_SUCCESS ) {
		printf("open_board: hackrf_open() failed: %s (%d)\n", hackrf_error_name(result), result);
		return(-1);
	}

  result = hackrf_set_freq(device, freq_hz);
  if( result != HACKRF_SUCCESS ) {
    printf("open_board: hackrf_set_freq() failed: %s (%d)\n", hackrf_error_name(result), result);
    return(-1);
  }

  result = hackrf_set_sample_rate(device, SAMPLE_PER_SYMBOL*1000000ul);
  if( result != HACKRF_SUCCESS ) {
    printf("open_board: hackrf_set_sample_rate() failed: %s (%d)\n", hackrf_error_name(result), result);
    return(-1);
  }

  /* range 0-47 step 1db */
  result = hackrf_set_txvga_gain(device, 47);
  if( result != HACKRF_SUCCESS ) {
    printf("open_board: hackrf_set_txvga_gain() failed: %s (%d)\n", hackrf_error_name(result), result);
    return(-1);
  }

  #if 0
  result = hackrf_set_antenna_enable(device, 1);
  if( result != HACKRF_SUCCESS ) {
    printf("open_board: hackrf_set_antenna_enable() failed: %s (%d)\n", hackrf_error_name(result), result);
    return(-1);
  }
  #endif

  return(0);
}

void exit_board() {
	if(device != NULL)
	{
		hackrf_exit();
		printf("hackrf_exit() done\n");
	}
}

inline int close_board() {
  int result;

	if(device != NULL)
	{
    result = hackrf_stop_tx(device);
    if( result != HACKRF_SUCCESS ) {
      printf("close_board: hackrf_stop_tx() failed: %s (%d)\n", hackrf_error_name(result), result);
      return(-1);
    }

		result = hackrf_close(device);
		if( result != HACKRF_SUCCESS )
		{
			printf("close_board: hackrf_close() failed: %s (%d)\n", hackrf_error_name(result), result);
			return(-1);
		}

    return(0);
	} else {
	  return(-1);
	}
}

inline int tx_one_buf(char *buf, int length, int channel_number) {
  int result;

  set_freq_by_channel_number(channel_number);

  //tx_buf = tx_zeros;
  //tx_len = HACKRF_USB_BUF_SIZE-NUM_PRE_SEND_DATA;
  tx_buf = buf;
  tx_len = length;

  // open the board-----------------------------------------
  if (open_board() == -1) {
    printf("tx_one_buf: open_board() failed\n");
    return(-1);
  }

  // first round TX---------------------------------
  stop_tx = 0;

  result = hackrf_start_tx(device, tx_callback, NULL);
  if( result != HACKRF_SUCCESS ) {
    printf("tx_one_buf: hackrf_start_tx() failed: %s (%d)\n", hackrf_error_name(result), result);
    return(-1);
  }

  while( (hackrf_is_streaming(device) == HACKRF_TRUE) &&
      (do_exit == false) )
  {
    if (stop_tx>=9) {
      break;
    }
  }

  if (do_exit)
  {
    printf("\ntx_one_buf: Exiting...\n");
    return(-1);
  }

  result = hackrf_stop_tx(device);
  if( result != HACKRF_SUCCESS ) {
    printf("tx_one_buf: hackrf_stop_tx() failed: %s (%d)\n", hackrf_error_name(result), result);
    return(-1);
  }

#if 0
  do_exit = false;
  
  // second round TX-----------------------------------
  tx_buf = tx_zeros;
  tx_len = HACKRF_USB_BUF_SIZE-NUM_PRE_SEND_DATA;
  //tx_buf = buf;
  //tx_len = length;

  stop_tx = 0;

  result = hackrf_start_tx(device, tx_callback, NULL);
  if( result != HACKRF_SUCCESS ) {
    printf("tx_one_buf: hackrf_start_tx() failed: %s (%d)\n", hackrf_error_name(result), result);
    return(-1);
  }

  while( (hackrf_is_streaming(device) == HACKRF_TRUE) &&
      (do_exit == false) )
  {
    if (stop_tx==1) {
      break;
    }
  }

  if (do_exit)
  {
    printf("\ntx_one_buf: Exiting...\n");
    return(-1);
  }
  
  result = hackrf_stop_tx(device);
  if( result != HACKRF_SUCCESS ) {
    printf("tx_one_buf: hackrf_stop_tx() failed: %s (%d)\n", hackrf_error_name(result), result);
    return(-1);
  }

  do_exit = false;

  // another round to flush ------------------------------
  stop_tx = 0;

  result = hackrf_start_tx(device, tx_callback, NULL);
  if( result != HACKRF_SUCCESS ) {
    printf("tx_one_buf: hackrf_start_tx() failed: %s (%d)\n", hackrf_error_name(result), result);
    return(-1);
  }

  while( (hackrf_is_streaming(device) == HACKRF_TRUE) &&
      (do_exit == false) )
  {
    if (stop_tx==1) {
      break;
    }
  }

  if (do_exit)
  {
    printf("\ntx_one_buf: Exiting...\n");
    return(-1);
  }

  result = hackrf_stop_tx(device);
  if( result != HACKRF_SUCCESS ) {
    printf("tx_one_buf: hackrf_stop_tx() failed: %s (%d)\n", hackrf_error_name(result), result);
    return(-1);
  }

  do_exit = false;

  // another round to flush ------------------------------
  stop_tx = 0;

  result = hackrf_start_tx(device, tx_callback, NULL);
  if( result != HACKRF_SUCCESS ) {
    printf("tx_one_buf: hackrf_start_tx() failed: %s (%d)\n", hackrf_error_name(result), result);
    return(-1);
  }

  while( (hackrf_is_streaming(device) == HACKRF_TRUE) &&
      (do_exit == false) )
  {
    if (stop_tx==1) {
      break;
    }
  }

  if (do_exit)
  {
    printf("\ntx_one_buf: Exiting...\n");
    return(-1);
  }
#endif

  // close the board---------------------------------------
  if (close_board() == -1) {
    printf("tx_one_buf: close_board() failed\n");
    return(-1);
  }

  do_exit = false;

  return(0);
}
#endif // USE_BLADERF

typedef enum
{
    INVALID_TYPE,
    RAW,
    DISCOVERY,
    IBEACON,
    ADV_IND,
    ADV_DIRECT_IND,
    ADV_NONCONN_IND,
    ADV_SCAN_IND,
    SCAN_REQ,
    SCAN_RSP,
    CONNECT_REQ,
    LL_DATA,
    LL_CONNECTION_UPDATE_REQ,
    LL_CHANNEL_MAP_REQ,
    LL_TERMINATE_IND,
    LL_ENC_REQ,
    LL_ENC_RSP,
    LL_START_ENC_REQ,
    LL_START_ENC_RSP,
    LL_UNKNOWN_RSP,
    LL_FEATURE_REQ,
    LL_FEATURE_RSP,
    LL_PAUSE_ENC_REQ,
    LL_PAUSE_ENC_RSP,
    LL_VERSION_IND,
    LL_REJECT_IND,
    NUM_PKT_TYPE
} PKT_TYPE;

typedef enum
{
    FLAGS,
    LOCAL_NAME08,
    LOCAL_NAME09,
    TXPOWER,
    SERVICE02,
    SERVICE03,
    SERVICE04,
    SERVICE05,
    SERVICE06,
    SERVICE07,
    SERVICE_SOLI14,
    SERVICE_SOLI15,
    SERVICE_DATA,
    MANUF_DATA,
    CONN_INTERVAL,
    SPACE,
    NUM_AD_TYPE
} AD_TYPE;

char *AD_TYPE_STR[] = {
    "FLAGS",
    "LOCAL_NAME08",
    "LOCAL_NAME09",
    "TXPOWER",
    "SERVICE02",
    "SERVICE03",
    "SERVICE04",
    "SERVICE05",
    "SERVICE06",
    "SERVICE07",
    "SERVICE_SOLI14",
    "SERVICE_SOLI15",
    "SERVICE_DATA",
    "MANUF_DATA",
    "CONN_INTERVAL",
    "SPACE"
};

const int AD_TYPE_VAL[] = {
    0x01,  //"FLAGS",
    0x08,  //"LOCAL_NAME08",
    0x09,  //"LOCAL_NAME09",
    0x0A,  //"TXPOWER",
    0x02,  //"SERVICE02",
    0x03,  //"SERVICE03",
    0x04,  //"SERVICE04",
    0x05,  //"SERVICE05",
    0x06,  //"SERVICE06",
    0x07,  //"SERVICE07",
    0x14,  //"SERVICE_SOLI14",
    0x15,  //"SERVICE_SOLI15",
    0x16,  //"SERVICE_DATA",
    0xFF,  //"MANUF_DATA",
    0x12   //"CONN_INTERVAL",
};

#define MAX_NUM_CHAR_CMD (256)
char tmp_str[MAX_NUM_CHAR_CMD];
char tmp_str1[MAX_NUM_CHAR_CMD];
float tmp_phy_bit_over_sampling[MAX_NUM_PHY_SAMPLE + 2*LEN_GAUSS_FILTER*SAMPLE_PER_SYMBOL];
float tmp_phy_bit_over_sampling1[MAX_NUM_PHY_SAMPLE];
typedef struct
{
    int channel_number;
    PKT_TYPE pkt_type;

    char cmd_str[MAX_NUM_CHAR_CMD]; // hex string format command input

    int num_info_bit;
    char info_bit[MAX_NUM_PHY_BYTE*8]; // without CRC and whitening

    int num_info_byte;
    uint8_t info_byte[MAX_NUM_PHY_BYTE];

    int num_phy_bit;
    char phy_bit[MAX_NUM_PHY_BYTE*8]; // all bits which will be fed to GFSK modulator

    int num_phy_byte;
    uint8_t phy_byte[MAX_NUM_PHY_BYTE];

    int num_phy_sample;
    char phy_sample[2*MAX_NUM_PHY_SAMPLE]; // GFSK output to D/A (hackrf board)
    int8_t phy_sample1[2*MAX_NUM_PHY_SAMPLE]; // GFSK output to D/A (hackrf board)

    int space; // how many millisecond null signal shouwl be padded after this packet
} PKT_INFO;

int get_num_repeat(char *input_str, int *repeat_specific){
  int num_repeat;

  if (input_str[0] == 'r' || input_str[0] == 'R') {
    num_repeat = atol(input_str+1);
    (*repeat_specific) = 1;

    if (strlen(input_str)>1) {
      if (num_repeat < -1) {
        num_repeat = 1;
        printf("Detect num_repeat < -1! (-1 means inf). Set to %d\n", num_repeat);
      } else if (num_repeat == 0) {
        num_repeat = 1;
        if ( input_str[1] == '0') {
          printf("Detect num_repeat = 0! (-1 means inf). Set to %d\n", num_repeat);
        } else {
          printf("Detect invalid num_repeat! (-1 means inf). Set to %d\n", num_repeat);
        }
      }
    } else {
      num_repeat = 1;
      printf("num_repeat not specified! (-1 means inf). Set to %d\n", num_repeat);
    }
  } else if (isdigit(input_str[0])) {
    (*repeat_specific) = 0;
    num_repeat = 1;
    printf("num_repeat not specified! (-1 means inf). Set to %d\n", num_repeat);
  } else {
    num_repeat = -2;
    printf("Invalid last parameter! (It should be num_repeat. -1 means inf)\n");
  }

  return(num_repeat);
}

#define MAX_NUM_PACKET (1024)
PKT_INFO packets[MAX_NUM_PACKET];

char* get_next_field(char *str_input, char *p_out, char *seperator, int size_of_p_out) {
  char *tmp_p = strstr(str_input, seperator);

  if (tmp_p == str_input){
    printf("Duplicated seperator %s!\n", seperator);
    return(NULL);
  } else if (tmp_p == NULL) {
    if (strlen(str_input) > (size_of_p_out-1) ) {
      printf("Number of input exceed output buffer!\n");
      return(NULL);
    } else {
      strcpy(p_out, str_input);
      return(str_input);
    }
  }

  if ( (tmp_p-str_input)>(size_of_p_out-1) ) {
    printf("Number of input exceed output buffer!\n");
    return(NULL);
  }

  char *p;
  for (p=str_input; p<tmp_p; p++) {
    p_out[p-str_input] = (*p);
  }
  p_out[p-str_input] = 0;

  return(tmp_p+1);
}

char* toupper_str(char *input_str, char *output_str) {
  int len_str = strlen(input_str);
  int i;

  for (i=0; i<=len_str; i++) {
    output_str[i] = toupper( input_str[i] );
  }

  return(output_str);
}

void octet_hex_to_bit(char *hex, char *bit) {
  char tmp_hex[3];

  tmp_hex[0] = hex[0];
  tmp_hex[1] = hex[1];
  tmp_hex[2] = 0;

  int n = strtol(tmp_hex, NULL, 16);

  bit[0] = 0x01&(n>>0);
  bit[1] = 0x01&(n>>1);
  bit[2] = 0x01&(n>>2);
  bit[3] = 0x01&(n>>3);
  bit[4] = 0x01&(n>>4);
  bit[5] = 0x01&(n>>5);
  bit[6] = 0x01&(n>>6);
  bit[7] = 0x01&(n>>7);
}

int bit_to_int(char *bit) {
  int n = 0;
  int i;
  for(i=0; i<8; i++) {
    n = ( (n<<1) | bit[7-i] );
  }
  return(n);
}

void int_to_bit(int n, char *bit) {
  bit[0] = 0x01&(n>>0);
  bit[1] = 0x01&(n>>1);
  bit[2] = 0x01&(n>>2);
  bit[3] = 0x01&(n>>3);
  bit[4] = 0x01&(n>>4);
  bit[5] = 0x01&(n>>5);
  bit[6] = 0x01&(n>>6);
  bit[7] = 0x01&(n>>7);
}

int convert_hex_to_bit(char *hex, char *bit){
  int num_hex_orig = strlen(hex);
  //while(hex[num_hex-1]<=32 || hex[num_hex-1]>=127) {
  //  num_hex--;
  //}
  int i, num_hex;
  num_hex = num_hex_orig;
  for(i=0; i<num_hex_orig; i++) {
    if ( !( (hex[i]>=48 && hex[i]<=57) || (hex[i]>=65 && hex[i]<=70) || (hex[i]>=97 && hex[i]<=102) ) ) //not a hex
      num_hex--;
  }

  if (num_hex%2 != 0) {
    printf("convert_hex_to_bit: Half octet is encountered! num_hex %d\n", num_hex);
    printf("%s\n", hex);
    return(-1);
  }

  int num_bit = num_hex*4;

  int j;
  for (i=0; i<num_hex; i=i+2) {
    j = i*4;
    octet_hex_to_bit(hex+i, bit+j);
  }

  return(num_bit);
}

#if 1 // fixed point version
#include "gauss_cos_sin_table.h"

int gen_sample_from_phy_byte(uint8_t *byte,  int8_t *sample, int num_byte) {
  int num_bit = num_byte*8;
  int num_sample = (num_bit*SAMPLE_PER_SYMBOL)+(LEN_GAUSS_FILTER*SAMPLE_PER_SYMBOL);

  int8_t *tmp_phy_bit_over_sampling_int8 = (int8_t *)tmp_phy_bit_over_sampling;

  int i, j, overall_bit_idx, sub_bit_idx;

  for (i=0; i<(LEN_GAUSS_FILTER*SAMPLE_PER_SYMBOL-1); i++) {
    tmp_phy_bit_over_sampling_int8[i] = 0;
  }
  for (i=(LEN_GAUSS_FILTER*SAMPLE_PER_SYMBOL-1+num_bit*SAMPLE_PER_SYMBOL); i<(2*LEN_GAUSS_FILTER*SAMPLE_PER_SYMBOL-2+num_bit*SAMPLE_PER_SYMBOL); i++) {
    tmp_phy_bit_over_sampling_int8[i] = 0;
  }
  for(j=0; j<num_byte; j++) {
    sub_bit_idx = 0;
    for (i=0; i<(8*SAMPLE_PER_SYMBOL); i = i + SAMPLE_PER_SYMBOL) {
      overall_bit_idx = j*8*SAMPLE_PER_SYMBOL + i;
     (*(int*)(&(tmp_phy_bit_over_sampling_int8[overall_bit_idx+(LEN_GAUSS_FILTER*SAMPLE_PER_SYMBOL-1)]))) = 0xff & (( (byte[j]>>sub_bit_idx & 0x01) ) * 2 - 1);
     sub_bit_idx++;
    }
  }

  int16_t tmp = 0;
  sample[0] = cos_table_int8[tmp];
  sample[1] = sin_table_int8[tmp];

  int len_conv_result = num_sample - 1;
  for (i=0; i<len_conv_result; i++) {
    int16_t acc = 0;
    for (j=3; j<(LEN_GAUSS_FILTER*SAMPLE_PER_SYMBOL-4); j++) {
      acc = acc + gauss_coef_int8[(LEN_GAUSS_FILTER*SAMPLE_PER_SYMBOL)-j-1]*tmp_phy_bit_over_sampling_int8[i+j];
    }

    tmp = (tmp + acc)&1023;
    sample[(i+1)*2 + 0] = cos_table_int8[tmp];
    sample[(i+1)*2 + 1] = sin_table_int8[tmp];
  }

  return(num_sample);
}

int gen_sample_from_phy_bit(char *bit, char *sample, int num_bit) {
  int num_sample = (num_bit*SAMPLE_PER_SYMBOL)+(LEN_GAUSS_FILTER*SAMPLE_PER_SYMBOL);

  int8_t *tmp_phy_bit_over_sampling_int8 = (int8_t *)tmp_phy_bit_over_sampling;
  //int16_t *tmp_phy_bit_over_sampling1_int16 = (int16_t *)tmp_phy_bit_over_sampling1;

  int i, j;

  for (i=0; i<(LEN_GAUSS_FILTER*SAMPLE_PER_SYMBOL-1); i++) {
    tmp_phy_bit_over_sampling_int8[i] = 0;
  }
  for (i=(LEN_GAUSS_FILTER*SAMPLE_PER_SYMBOL-1+num_bit*SAMPLE_PER_SYMBOL); i<(2*LEN_GAUSS_FILTER*SAMPLE_PER_SYMBOL-2+num_bit*SAMPLE_PER_SYMBOL); i++) {
    tmp_phy_bit_over_sampling_int8[i] = 0;
  }
  for (i=0; i<(num_bit*SAMPLE_PER_SYMBOL); i++) {
    if (i%SAMPLE_PER_SYMBOL == 0) {
      tmp_phy_bit_over_sampling_int8[i+(LEN_GAUSS_FILTER*SAMPLE_PER_SYMBOL-1)] = ( bit[i/SAMPLE_PER_SYMBOL] ) * 2 - 1;
    } else {
      tmp_phy_bit_over_sampling_int8[i+(LEN_GAUSS_FILTER*SAMPLE_PER_SYMBOL-1)] = 0;
    }
  }

  #if 1 // new method

  int16_t tmp = 0;
  sample[0] = cos_table_int8[tmp];
  sample[1] = sin_table_int8[tmp];

  int len_conv_result = num_sample - 1;
  for (i=0; i<len_conv_result; i++) {
    int16_t acc = 0;
    for (j=3; j<(LEN_GAUSS_FILTER*SAMPLE_PER_SYMBOL-4); j++) {
      acc = acc + gauss_coef_int8[(LEN_GAUSS_FILTER*SAMPLE_PER_SYMBOL)-j-1]*tmp_phy_bit_over_sampling_int8[i+j];
    }

    tmp = (tmp + acc)&1023;
    sample[(i+1)*2 + 0] = cos_table_int8[tmp];
    sample[(i+1)*2 + 1] = sin_table_int8[tmp];
  }

  #else // old method

  int len_conv_result = num_sample - 1;
  for (i=0; i<len_conv_result; i++) {
    int16_t acc = 0;
    for (j=0; j<(LEN_GAUSS_FILTER*SAMPLE_PER_SYMBOL); j++) {
      acc = acc + gauss_coef_int16[(LEN_GAUSS_FILTER*SAMPLE_PER_SYMBOL)-j-1]*tmp_phy_bit_over_sampling_int16[i+j];
    }
    tmp_phy_bit_over_sampling1_int16[i] = acc;
  }

  int16_t tmp = 0;
  sample[0] = cos_table_int8[tmp];
  sample[1] = sin_table_int8[tmp];
  for (i=1; i<num_sample; i++) {
    tmp = (tmp + tmp_phy_bit_over_sampling1_int16[i-1])&1023;
    sample[i*2 + 0] = cos_table_int8[tmp];
    sample[i*2 + 1] = sin_table_int8[tmp];
  }

  #endif

  return(num_sample);
}

#else // float point version

int gen_sample_from_phy_bit(char *bit, char *sample, int num_bit) {
  int num_sample = (num_bit*SAMPLE_PER_SYMBOL)+(LEN_GAUSS_FILTER*SAMPLE_PER_SYMBOL);

  int i, j;

  for (i=0; i<(LEN_GAUSS_FILTER*SAMPLE_PER_SYMBOL-1); i++) {
    tmp_phy_bit_over_sampling[i] = 0.0;
  }
  for (i=(LEN_GAUSS_FILTER*SAMPLE_PER_SYMBOL-1+num_bit*SAMPLE_PER_SYMBOL); i<(2*LEN_GAUSS_FILTER*SAMPLE_PER_SYMBOL-2+num_bit*SAMPLE_PER_SYMBOL); i++) {
    tmp_phy_bit_over_sampling[i] = 0.0;
  }
  for (i=0; i<(num_bit*SAMPLE_PER_SYMBOL); i++) {
    if (i%SAMPLE_PER_SYMBOL == 0) {
      tmp_phy_bit_over_sampling[i+(LEN_GAUSS_FILTER*SAMPLE_PER_SYMBOL-1)] = (float)( bit[i/SAMPLE_PER_SYMBOL] ) * 2.0 - 1.0;
    } else {
      tmp_phy_bit_over_sampling[i+(LEN_GAUSS_FILTER*SAMPLE_PER_SYMBOL-1)] = 0.0;
    }
  }

  int len_conv_result = num_sample - 1;
  for (i=0; i<len_conv_result; i++) {
    float acc = 0;
    for (j=0; j<(LEN_GAUSS_FILTER*SAMPLE_PER_SYMBOL); j++) {
      acc = acc + gauss_coef[(LEN_GAUSS_FILTER*SAMPLE_PER_SYMBOL)-j-1]*tmp_phy_bit_over_sampling[i+j];
    }
    tmp_phy_bit_over_sampling1[i] = acc;
  }

  float tmp = 0;
  sample[0] = (char)round( cos(tmp)*(float)AMPLITUDE );
  sample[1] = (char)round( sin(tmp)*(float)AMPLITUDE );
   for (i=1; i<num_sample; i++) {
    tmp = tmp + (M_PI*MOD_IDX)*tmp_phy_bit_over_sampling1[i-1]/((float)SAMPLE_PER_SYMBOL);
    sample[i*2 + 0] = (char)round( cos(tmp)*(float)AMPLITUDE );
    sample[i*2 + 1] = (char)round( sin(tmp)*(float)AMPLITUDE );
  }

  return(num_sample);
}

#endif

char* get_next_field_value(char *current_p, int *value_return, int *return_flag) {
// return_flag: -1 failed; 0 success; 1 success and this is the last field
  char *next_p = get_next_field(current_p, tmp_str, "-", MAX_NUM_CHAR_CMD);
  if (next_p == NULL) {
    (*return_flag) = -1;
    return(next_p);
  }

  (*value_return) = atol(tmp_str);

  if (next_p == current_p) {
    (*return_flag) = 1;
    return(next_p);
  }

  (*return_flag) = 0;
  return(next_p);
}

char* get_next_field_name(char *current_p, char *name, int *return_flag) {
// return_flag: -1 failed; 0 success; 1 success and this is the last field
  char *next_p = get_next_field(current_p, tmp_str, "-", MAX_NUM_CHAR_CMD);
  if (next_p == NULL) {
    (*return_flag) = -1;
    return(next_p);
  }
  if (strcmp(toupper_str(tmp_str, tmp_str), name) != 0) {
//    printf("%s field is expected!\n", name);
    (*return_flag) = -1;
    return(next_p);
  }

  if (next_p == current_p) {
    (*return_flag) = 1;
    return(next_p);
  }

  (*return_flag) = 0;
  return(next_p);
}

char* get_next_field_char(char *current_p, char *bit_return, int *num_bit_return, int stream_flip, int octet_limit, int *return_flag) {
// return_flag: -1 failed; 0 success; 1 success and this is the last field
// stream_flip: 0: normal order; 1: flip octets order in sequence
  int i;
  char *next_p = get_next_field(current_p, tmp_str, "-", MAX_NUM_CHAR_CMD);
  if (next_p == NULL) {
    (*return_flag) = -1;
    return(next_p);
  }
  int num_hex = strlen(tmp_str);
  while(tmp_str[num_hex-1]<=32 || tmp_str[num_hex-1]>=127) {
    num_hex--;
  }

  if ( num_hex>octet_limit ) {
    printf("Too many octets(char)! Maximum allowed is %d\n", octet_limit);
    (*return_flag) = -1;
    return(next_p);
  }
  if (num_hex <= 1) { // NULL data
    (*return_flag) = 0;
    (*num_bit_return) = 0;
    return(next_p);
  }

  if (stream_flip == 1) {
    for (i=0; i<num_hex; i++) {
      int_to_bit(tmp_str[num_hex-i-1], bit_return + 8*i);
    }
  } else {
    for (i=0; i<num_hex; i++) {
      int_to_bit(tmp_str[i], bit_return + 8*i);
    }
  }

  (*num_bit_return) = 8*num_hex;

  if (next_p == current_p) {
    (*return_flag) = 1;
    return(next_p);
  }

  (*return_flag) = 0;
  return(next_p);
}

char* get_next_field_bit_part_flip(char *current_p, char *bit_return, int *num_bit_return, int stream_flip, int octet_limit, int *return_flag) {
// return_flag: -1 failed; 0 success; 1 success and this is the last field
// stream_flip: 0: normal order; 1: flip octets order in sequence
  int i;
  char *next_p = get_next_field(current_p, tmp_str, "-", MAX_NUM_CHAR_CMD);
  if (next_p == NULL) {
    (*return_flag) = -1;
    return(next_p);
  }
  int num_hex = strlen(tmp_str);
   while(tmp_str[num_hex-1]<=32 || tmp_str[num_hex-1]>=127) {
     num_hex--;
   }

   if (num_hex%2 != 0) {
     printf("get_next_field_bit: Half octet is encountered! num_hex %d\n", num_hex);
     printf("%s\n", tmp_str);
     (*return_flag) = -1;
     return(next_p);
   }

  if ( num_hex>(octet_limit*2) ) {
    printf("Too many octets! Maximum allowed is %d\n", octet_limit);
    (*return_flag) = -1;
    return(next_p);
  }
  if (num_hex <= 1) { // NULL data
    (*return_flag) = 0;
    (*num_bit_return) = 0;
    return(next_p);
  }

  int num_bit_tmp;

  num_hex = 2*stream_flip;
  strcpy(tmp_str1, tmp_str);
  for (i=0; i<num_hex; i=i+2) {
    tmp_str[num_hex-i-2] = tmp_str1[i];
    tmp_str[num_hex-i-1] = tmp_str1[i+1];
  }

  num_bit_tmp = convert_hex_to_bit(tmp_str, bit_return);
  if ( num_bit_tmp == -1 ) {
    (*return_flag) = -1;
    return(next_p);
  }
  (*num_bit_return) = num_bit_tmp;

  if (next_p == current_p) {
    (*return_flag) = 1;
    return(next_p);
  }

  (*return_flag) = 0;
  return(next_p);
}

char* get_next_field_bit(char *current_p, char *bit_return, int *num_bit_return, int stream_flip, int octet_limit, int *return_flag) {
// return_flag: -1 failed; 0 success; 1 success and this is the last field
// stream_flip: 0: normal order; 1: flip octets order in sequence
  int i;
  char *next_p = get_next_field(current_p, tmp_str, "-", MAX_NUM_CHAR_CMD);
  if (next_p == NULL) {
    (*return_flag) = -1;
    return(next_p);
  }
  int num_hex = strlen(tmp_str);
   while(tmp_str[num_hex-1]<=32 || tmp_str[num_hex-1]>=127) {
     num_hex--;
   }

   if (num_hex%2 != 0) {
     printf("get_next_field_bit: Half octet is encountered! num_hex %d\n", num_hex);
     printf("%s\n", tmp_str);
     (*return_flag) = -1;
     return(next_p);
   }

  if ( num_hex>(octet_limit*2) ) {
    printf("Too many octets! Maximum allowed is %d\n", octet_limit);
    (*return_flag) = -1;
    return(next_p);
  }
  if (num_hex <= 1) { // NULL data
    (*return_flag) = 0;
    (*num_bit_return) = 0;
    return(next_p);
  }

  int num_bit_tmp;
  if (stream_flip == 1) {
     strcpy(tmp_str1, tmp_str);
    for (i=0; i<num_hex; i=i+2) {
      tmp_str[num_hex-i-2] = tmp_str1[i];
      tmp_str[num_hex-i-1] = tmp_str1[i+1];
    }
  }
  num_bit_tmp = convert_hex_to_bit(tmp_str, bit_return);
  if ( num_bit_tmp == -1 ) {
    (*return_flag) = -1;
    return(next_p);
  }
  (*num_bit_return) = num_bit_tmp;

  if (next_p == current_p) {
    (*return_flag) = 1;
    return(next_p);
  }

  (*return_flag) = 0;
  return(next_p);
}

char *get_next_field_name_value(char *input_p, char *name, int *val, int *ret_last){
// ret_last: -1 failed; 0 success; 1 success and this is the last field
  int ret;
  char *current_p = input_p;

  char *next_p = get_next_field_name(current_p, name, &ret);
  if (ret != 0) { // failed or the last
    (*ret_last) = -1;
    return(NULL);
  }

  current_p = next_p;
  next_p = get_next_field_value(current_p, val, &ret);
  (*ret_last) = ret;
  if (ret == -1) { // failed
    return(NULL);
  }

  return(next_p);
}

#define DEFAULT_SPACE_MS (200)
int calculate_sample_for_RAW(char *pkt_str, PKT_INFO *pkt) {
// example
// ./btle_tx 39-RAW-AAD6BE898E5F134B5D86F2999CC3D7DF5EDF15DEE39AA2E5D0728EB68B0E449B07C547B80EAA8DD257A0E5EACB0B-SPACE-1000
  char *current_p;
  int ret;

  pkt->num_info_bit = 0;
  printf("num_info_bit %d\n", pkt->num_info_bit);

  current_p = pkt_str;
  current_p = get_next_field_bit(current_p, pkt->phy_bit, &(pkt->num_phy_bit), 0, MAX_NUM_PHY_BYTE, &ret);
  if (ret == -1) {
    return(-1);
  }
  printf("num_phy_bit %d\n", pkt->num_phy_bit);

  pkt->num_phy_sample = gen_sample_from_phy_bit(pkt->phy_bit, pkt->phy_sample, pkt->num_phy_bit);
  printf("num_phy_sample %d\n", pkt->num_phy_sample);

  if (ret==1) {
    pkt->space = DEFAULT_SPACE_MS;
    printf("space %d\n", pkt->space);
    return(0);
  }

  int space;
  current_p = get_next_field_name_value(current_p, "SPACE", &space, &ret);
  if (ret == -1) {
    return(-1);
  }

  if (space <= 0) {
    printf("Invalid space!\n");
    return(-1);
  }

  pkt->space = space;
  printf("space %d\n", pkt->space);

  return(0);
}

/**
 * Static table used for the table_driven implementation.
 *****************************************************************************/
static const uint_fast32_t crc_table[256] = {
    0x000000, 0x01b4c0, 0x036980, 0x02dd40, 0x06d300, 0x0767c0, 0x05ba80, 0x040e40,
    0x0da600, 0x0c12c0, 0x0ecf80, 0x0f7b40, 0x0b7500, 0x0ac1c0, 0x081c80, 0x09a840,
    0x1b4c00, 0x1af8c0, 0x182580, 0x199140, 0x1d9f00, 0x1c2bc0, 0x1ef680, 0x1f4240,
    0x16ea00, 0x175ec0, 0x158380, 0x143740, 0x103900, 0x118dc0, 0x135080, 0x12e440,
    0x369800, 0x372cc0, 0x35f180, 0x344540, 0x304b00, 0x31ffc0, 0x332280, 0x329640,
    0x3b3e00, 0x3a8ac0, 0x385780, 0x39e340, 0x3ded00, 0x3c59c0, 0x3e8480, 0x3f3040,
    0x2dd400, 0x2c60c0, 0x2ebd80, 0x2f0940, 0x2b0700, 0x2ab3c0, 0x286e80, 0x29da40,
    0x207200, 0x21c6c0, 0x231b80, 0x22af40, 0x26a100, 0x2715c0, 0x25c880, 0x247c40,
    0x6d3000, 0x6c84c0, 0x6e5980, 0x6fed40, 0x6be300, 0x6a57c0, 0x688a80, 0x693e40,
    0x609600, 0x6122c0, 0x63ff80, 0x624b40, 0x664500, 0x67f1c0, 0x652c80, 0x649840,
    0x767c00, 0x77c8c0, 0x751580, 0x74a140, 0x70af00, 0x711bc0, 0x73c680, 0x727240,
    0x7bda00, 0x7a6ec0, 0x78b380, 0x790740, 0x7d0900, 0x7cbdc0, 0x7e6080, 0x7fd440,
    0x5ba800, 0x5a1cc0, 0x58c180, 0x597540, 0x5d7b00, 0x5ccfc0, 0x5e1280, 0x5fa640,
    0x560e00, 0x57bac0, 0x556780, 0x54d340, 0x50dd00, 0x5169c0, 0x53b480, 0x520040,
    0x40e400, 0x4150c0, 0x438d80, 0x423940, 0x463700, 0x4783c0, 0x455e80, 0x44ea40,
    0x4d4200, 0x4cf6c0, 0x4e2b80, 0x4f9f40, 0x4b9100, 0x4a25c0, 0x48f880, 0x494c40,
    0xda6000, 0xdbd4c0, 0xd90980, 0xd8bd40, 0xdcb300, 0xdd07c0, 0xdfda80, 0xde6e40,
    0xd7c600, 0xd672c0, 0xd4af80, 0xd51b40, 0xd11500, 0xd0a1c0, 0xd27c80, 0xd3c840,
    0xc12c00, 0xc098c0, 0xc24580, 0xc3f140, 0xc7ff00, 0xc64bc0, 0xc49680, 0xc52240,
    0xcc8a00, 0xcd3ec0, 0xcfe380, 0xce5740, 0xca5900, 0xcbedc0, 0xc93080, 0xc88440,
    0xecf800, 0xed4cc0, 0xef9180, 0xee2540, 0xea2b00, 0xeb9fc0, 0xe94280, 0xe8f640,
    0xe15e00, 0xe0eac0, 0xe23780, 0xe38340, 0xe78d00, 0xe639c0, 0xe4e480, 0xe55040,
    0xf7b400, 0xf600c0, 0xf4dd80, 0xf56940, 0xf16700, 0xf0d3c0, 0xf20e80, 0xf3ba40,
    0xfa1200, 0xfba6c0, 0xf97b80, 0xf8cf40, 0xfcc100, 0xfd75c0, 0xffa880, 0xfe1c40,
    0xb75000, 0xb6e4c0, 0xb43980, 0xb58d40, 0xb18300, 0xb037c0, 0xb2ea80, 0xb35e40,
    0xbaf600, 0xbb42c0, 0xb99f80, 0xb82b40, 0xbc2500, 0xbd91c0, 0xbf4c80, 0xbef840,
    0xac1c00, 0xada8c0, 0xaf7580, 0xaec140, 0xaacf00, 0xab7bc0, 0xa9a680, 0xa81240,
    0xa1ba00, 0xa00ec0, 0xa2d380, 0xa36740, 0xa76900, 0xa6ddc0, 0xa40080, 0xa5b440,
    0x81c800, 0x807cc0, 0x82a180, 0x831540, 0x871b00, 0x86afc0, 0x847280, 0x85c640,
    0x8c6e00, 0x8ddac0, 0x8f0780, 0x8eb340, 0x8abd00, 0x8b09c0, 0x89d480, 0x886040,
    0x9a8400, 0x9b30c0, 0x99ed80, 0x985940, 0x9c5700, 0x9de3c0, 0x9f3e80, 0x9e8a40,
    0x972200, 0x9696c0, 0x944b80, 0x95ff40, 0x91f100, 0x9045c0, 0x929880, 0x932c40
};

/**
 * Update the crc value with new data.
 *
 * \param crc      The current crc value.
 * \param data     Pointer to a buffer of \a data_len bytes.
 * \param data_len Number of bytes in the \a data buffer.
 * \return         The updated crc value.
 *****************************************************************************/
uint_fast32_t crc_update(uint_fast32_t crc, const void *data, size_t data_len)
{
    const unsigned char *d = (const unsigned char *)data;
    unsigned int tbl_idx;

    while (data_len--) {
            tbl_idx = (crc ^ *d) & 0xff;
            crc = (crc_table[tbl_idx] ^ (crc >> 8)) & 0xffffff;

        d++;
    }
    return crc & 0xffffff;
}

uint_fast32_t crc24_byte(uint8_t *byte_in, int num_byte, int init_hex) {
  uint_fast32_t crc = init_hex;

  crc = crc_update(crc, byte_in, num_byte);

  return(crc);
}

void crc24(char *bit_in, int num_bit, char *init_hex, char *crc_result) {
  char bit_store[24], bit_store_update[24];
  int i;
  convert_hex_to_bit(init_hex, bit_store);

  for (i=0; i<num_bit; i++) {
    char new_bit = (bit_store[23]+bit_in[i])%2;
    bit_store_update[0] = new_bit;
    bit_store_update[1] = (bit_store[0]+new_bit)%2;
    bit_store_update[2] = bit_store[1];
    bit_store_update[3] = (bit_store[2]+new_bit)%2;
    bit_store_update[4] = (bit_store[3]+new_bit)%2;
    bit_store_update[5] = bit_store[4];
    bit_store_update[6] = (bit_store[5]+new_bit)%2;

    bit_store_update[7] = bit_store[6];
    bit_store_update[8] = bit_store[7];

    bit_store_update[9] = (bit_store[8]+new_bit)%2;
    bit_store_update[10] = (bit_store[9]+new_bit)%2;

    memcpy(bit_store_update+11, bit_store+10, 13);

    memcpy(bit_store, bit_store_update, 24);
  }

  for (i=0; i<24; i++) {
    crc_result[i] = bit_store[23-i];
  }
}

#include "scramble_table_ch37.h"
void scramble_byte(uint8_t *byte_in, int num_byte, int channel_number, uint8_t *byte_out) {
  int i;
  for(i=0; i<num_byte; i++){
    byte_out[i] = byte_in[i]^scramble_table_ch37[i];
  }
}

void scramble(char *bit_in, int num_bit, int channel_number, char *bit_out) {
  char bit_store[7], bit_store_update[7];
  int i;

  bit_store[0] = 1;
  bit_store[1] = 0x01&(channel_number>>5);
  bit_store[2] = 0x01&(channel_number>>4);
  bit_store[3] = 0x01&(channel_number>>3);
  bit_store[4] = 0x01&(channel_number>>2);
  bit_store[5] = 0x01&(channel_number>>1);
  bit_store[6] = 0x01&(channel_number>>0);

  for (i=0; i<num_bit; i++) {
    bit_out[i] = ( bit_store[6] + bit_in[i] )%2;

    bit_store_update[0] = bit_store[6];

    bit_store_update[1] = bit_store[0];
    bit_store_update[2] = bit_store[1];
    bit_store_update[3] = bit_store[2];

    bit_store_update[4] = (bit_store[3]+bit_store[6])%2;

    bit_store_update[5] = bit_store[4];
    bit_store_update[6] = bit_store[5];

    memcpy(bit_store, bit_store_update, 7);
  }
}

void fill_hop_sca(int hop, int sca, char *bit_out) {
  bit_out[0] = 0x01&(hop>>0);
  bit_out[1] = 0x01&(hop>>1);
  bit_out[2] = 0x01&(hop>>2);
  bit_out[3] = 0x01&(hop>>3);
  bit_out[4] = 0x01&(hop>>4);

  bit_out[5] = 0x01&(sca>>0);
  bit_out[6] = 0x01&(sca>>1);
  bit_out[7] = 0x01&(sca>>2);
}

void fill_data_pdu_header(int llid, int nesn, int sn, int md, int length, char *bit_out) {
  bit_out[0] = 0x01&(llid>>0);
  bit_out[1] = 0x01&(llid>>1);

  bit_out[2] = nesn;

  bit_out[3] = sn;

  bit_out[4] = md;

  bit_out[5] = 0;
  bit_out[6] = 0;
  bit_out[7] = 0;

  bit_out[8] = 0x01&(length>>0);
  bit_out[9] = 0x01&(length>>1);
  bit_out[10] = 0x01&(length>>2);
  bit_out[11] = 0x01&(length>>3);
  bit_out[12] = 0x01&(length>>4);

  bit_out[13] = 0;
  bit_out[14] = 0;
  bit_out[15] = 0;
}

void get_opcode(PKT_TYPE pkt_type, char *bit_out) {
  if (pkt_type == LL_CONNECTION_UPDATE_REQ) {
    convert_hex_to_bit("00", bit_out);
  } else if (pkt_type == LL_CHANNEL_MAP_REQ) {
    convert_hex_to_bit("01", bit_out);
  } else if (pkt_type == LL_TERMINATE_IND) {
    convert_hex_to_bit("02", bit_out);
  } else if (pkt_type == LL_ENC_REQ) {
    convert_hex_to_bit("03", bit_out);
  } else if (pkt_type == LL_ENC_RSP) {
    convert_hex_to_bit("04", bit_out);
  } else if (pkt_type == LL_START_ENC_REQ) {
    convert_hex_to_bit("05", bit_out);
  } else if (pkt_type == LL_START_ENC_RSP) {
    convert_hex_to_bit("06", bit_out);
  } else if (pkt_type == LL_UNKNOWN_RSP) {
    convert_hex_to_bit("07", bit_out);
  } else if (pkt_type == LL_FEATURE_REQ) {
    convert_hex_to_bit("08", bit_out);
  } else if (pkt_type == LL_FEATURE_RSP) {
    convert_hex_to_bit("09", bit_out);
  } else if (pkt_type == LL_PAUSE_ENC_REQ) {
    convert_hex_to_bit("0A", bit_out);
  } else if (pkt_type == LL_PAUSE_ENC_RSP) {
    convert_hex_to_bit("0B", bit_out);
  } else if (pkt_type == LL_VERSION_IND) {
    convert_hex_to_bit("0C", bit_out);
  } else if (pkt_type == LL_REJECT_IND) {
    convert_hex_to_bit("0D", bit_out);
  } else {
    convert_hex_to_bit("FF", bit_out);
    printf("Warning! Reserved TYPE!\n");
  }
}

void fill_adv_pdu_header_byte(PKT_TYPE pkt_type, int txadd, int rxadd, int payload_len, uint8_t *byte_out) {
  if (pkt_type == ADV_IND || pkt_type == IBEACON) {
    //bit_out[3] = 0; bit_out[2] = 0; bit_out[1] = 0; bit_out[0] = 0;
    byte_out[0] = 0;
  } else if (pkt_type == ADV_DIRECT_IND) {
    //bit_out[3] = 0; bit_out[2] = 0; bit_out[1] = 0; bit_out[0] = 1;
    byte_out[0] = 1;
  } else if (pkt_type == ADV_NONCONN_IND || pkt_type == DISCOVERY) {
    //bit_out[3] = 0; bit_out[2] = 0; bit_out[1] = 1; bit_out[0] = 0;
    byte_out[0] = 2;
  } else if (pkt_type == SCAN_REQ) {
    //bit_out[3] = 0; bit_out[2] = 0; bit_out[1] = 1; bit_out[0] = 1;
    byte_out[0] = 3;
  } else if (pkt_type == SCAN_RSP) {
    //bit_out[3] = 0; bit_out[2] = 1; bit_out[1] = 0; bit_out[0] = 0;
    byte_out[0] = 4;
  } else if (pkt_type == CONNECT_REQ) {
    //bit_out[3] = 0; bit_out[2] = 1; bit_out[1] = 0; bit_out[0] = 1;
    byte_out[0] = 5;
  } else if (pkt_type == ADV_SCAN_IND) {
    //bit_out[3] = 0; bit_out[2] = 1; bit_out[1] = 1; bit_out[0] = 0;
    byte_out[0] = 6;
  } else {
    //bit_out[3] = 1; bit_out[2] = 1; bit_out[1] = 1; bit_out[0] = 1;
    byte_out[0] = 0xF;
    printf("Warning! Reserved TYPE!\n");
  }

  /*bit_out[4] = 0;
  bit_out[5] = 0;

  bit_out[6] = txadd;
  bit_out[7] = rxadd;*/
  byte_out[0] =  byte_out[0] | (txadd << 6);
  byte_out[0] =  byte_out[0] | (rxadd << 7);

  /*bit_out[8] = 0x01&(payload_len>>0);
  bit_out[9] = 0x01&(payload_len>>1);
  bit_out[10] = 0x01&(payload_len>>2);
  bit_out[11] = 0x01&(payload_len>>3);
  bit_out[12] = 0x01&(payload_len>>4);
  bit_out[13] = 0x01&(payload_len>>5);

  bit_out[14] = 0;
  bit_out[15] = 0;*/
  byte_out[1] = payload_len;
}

void fill_adv_pdu_header(PKT_TYPE pkt_type, int txadd, int rxadd, int payload_len, char *bit_out) {
  if (pkt_type == ADV_IND || pkt_type == IBEACON) {
    bit_out[3] = 0; bit_out[2] = 0; bit_out[1] = 0; bit_out[0] = 0;
  } else if (pkt_type == ADV_DIRECT_IND) {
    bit_out[3] = 0; bit_out[2] = 0; bit_out[1] = 0; bit_out[0] = 1;
  } else if (pkt_type == ADV_NONCONN_IND || pkt_type == DISCOVERY) {
    bit_out[3] = 0; bit_out[2] = 0; bit_out[1] = 1; bit_out[0] = 0;
  } else if (pkt_type == SCAN_REQ) {
    bit_out[3] = 0; bit_out[2] = 0; bit_out[1] = 1; bit_out[0] = 1;
  } else if (pkt_type == SCAN_RSP) {
    bit_out[3] = 0; bit_out[2] = 1; bit_out[1] = 0; bit_out[0] = 0;
  } else if (pkt_type == CONNECT_REQ) {
    bit_out[3] = 0; bit_out[2] = 1; bit_out[1] = 0; bit_out[0] = 1;
  } else if (pkt_type == ADV_SCAN_IND) {
    bit_out[3] = 0; bit_out[2] = 1; bit_out[1] = 1; bit_out[0] = 0;
  } else {
    bit_out[3] = 1; bit_out[2] = 1; bit_out[1] = 1; bit_out[0] = 1;
    printf("Warning! Reserved TYPE!\n");
  }

  bit_out[4] = 0;
  bit_out[5] = 0;

  bit_out[6] = txadd;
  bit_out[7] = rxadd;

  bit_out[8] = 0x01&(payload_len>>0);
  bit_out[9] = 0x01&(payload_len>>1);
  bit_out[10] = 0x01&(payload_len>>2);
  bit_out[11] = 0x01&(payload_len>>3);
  bit_out[12] = 0x01&(payload_len>>4);
  bit_out[13] = 0x01&(payload_len>>5);

  bit_out[14] = 0;
  bit_out[15] = 0;
}

char* get_next_field_hex(char *current_p, char *hex_return, int stream_flip, int octet_limit, int *return_flag) {
// return_flag: -1 failed; 0 success; 1 success and this is the last field
// stream_flip: 0: normal order; 1: flip octets order in sequence
  int i;
  char *next_p = get_next_field(current_p, tmp_str, "-", MAX_NUM_CHAR_CMD);
  if (next_p == NULL) {
    (*return_flag) = -1;
    return(next_p);
  }
  int num_hex = strlen(tmp_str);
  while(tmp_str[num_hex-1]<=32 || tmp_str[num_hex-1]>=127) {
    num_hex--;
  }

  if (num_hex%2 != 0) {
    printf("get_next_field_hex: Half octet is encountered! num_hex %d\n", num_hex);
    printf("%s\n", tmp_str);
    (*return_flag) = -1;
    return(next_p);
  }

  if ( num_hex>(octet_limit*2) ) {
    printf("Too many octets! Maximum allowed is %d\n", octet_limit);
    (*return_flag) = -1;
    return(next_p);
  }

  if (stream_flip == 1) {
    strcpy(tmp_str1, tmp_str);
    for (i=0; i<num_hex; i=i+2) {
      tmp_str[num_hex-i-2] = tmp_str1[i];
      tmp_str[num_hex-i-1] = tmp_str1[i+1];
    }
  }

  strcpy(hex_return, tmp_str);
  hex_return[num_hex] = 0;

  if (next_p == current_p) {
    (*return_flag) = 1;
    return(next_p);
  }

  (*return_flag) = 0;
  return(next_p);
}

char *get_next_field_name_char(char *input_p, char *name, char *out_bit, int *num_bit, int flip_flag, int octet_limit, int *ret_last){
// ret_last: -1 failed; 0 success; 1 success and this is the last field
  int ret;
  char *current_p = input_p;

  char *next_p = get_next_field_name(current_p, name, &ret);
  if (ret != 0) { // failed or the last
    (*ret_last) = -1;
    return(NULL);
  }

  current_p = next_p;
  next_p = get_next_field_char(current_p, out_bit, num_bit, flip_flag, octet_limit, &ret);
  (*ret_last) = ret;
  if (ret == -1) { // failed
    return(NULL);
  }

  return(next_p);
}

char *get_next_field_name_hex(char *input_p, char *name, char *out_hex, int flip_flag, int octet_limit, int *ret_last){
// ret_last: -1 failed; 0 success; 1 success and this is the last field
  int ret;
  char *current_p = input_p;

  char *next_p = get_next_field_name(current_p, name, &ret);
  if (ret != 0) { // failed or the last
    (*ret_last) = -1;
    return(NULL);
  }

  current_p = next_p;
  next_p = get_next_field_hex(current_p, out_hex, flip_flag, octet_limit, &ret);
  (*ret_last) = ret;
  if (ret == -1) { // failed
    return(NULL);
  }

  return(next_p);
}

char *get_next_field_name_bit_part_flip(char *input_p, char *name, char *out_bit, int *num_bit, int flip_flag, int octet_limit, int *ret_last){
// ret_last: -1 failed; 0 success; 1 success and this is the last field
  int ret;
  char *current_p = input_p;

  char *next_p = get_next_field_name(current_p, name, &ret);
  if (ret != 0) { // failed or the last
    (*ret_last) = -1;
    return(NULL);
  }

  current_p = next_p;
  next_p = get_next_field_bit_part_flip(current_p, out_bit, num_bit, flip_flag, octet_limit, &ret);
  (*ret_last) = ret;
  if (ret == -1) { // failed
    return(NULL);
  }

  return(next_p);
}

char *get_next_field_name_bit(char *input_p, char *name, char *out_bit, int *num_bit, int flip_flag, int octet_limit, int *ret_last){
// ret_last: -1 failed; 0 success; 1 success and this is the last field
  int ret;
  char *current_p = input_p;

  char *next_p = get_next_field_name(current_p, name, &ret);
  if (ret != 0) { // failed or the last
    (*ret_last) = -1;
    return(NULL);
  }

  current_p = next_p;
  next_p = get_next_field_bit(current_p, out_bit, num_bit, flip_flag, octet_limit, &ret);
  (*ret_last) = ret;
  if (ret == -1) { // failed
    return(NULL);
  }

  return(next_p);
}

void disp_bit(char *bit, int num_bit)
{
  int i, bit_val;
  for(i=0; i<num_bit; i++) {
    bit_val = bit[i];
    if (i%8 == 0 && i != 0) {
      printf(" ");
    } else if (i%4 == 0 && i != 0) {
      printf("-");
    }
    printf("%d", bit_val);
  }
  printf("\n");
}

void disp_bit_in_hex(char *bit, int num_bit)
{
  int i, a;
  for(i=0; i<num_bit; i=i+8) {
    a = bit[i] + bit[i+1]*2 + bit[i+2]*4 + bit[i+3]*8 + bit[i+4]*16 + bit[i+5]*32 + bit[i+6]*64 + bit[i+7]*128;
    //a = bit[i+7] + bit[i+6]*2 + bit[i+5]*4 + bit[i+4]*8 + bit[i+3]*16 + bit[i+2]*32 + bit[i+1]*64 + bit[i]*128;
    printf("%02x", a);
  }
  printf("\n");
}

void disp_hex(uint8_t *hex, int num_hex)
{
  int i;
  for(i=0; i<num_hex; i++)
  {
     printf("%02x", hex[i]);
  }
  printf("\n");
}

void disp_hex_in_bit(uint8_t *hex, int num_hex)
{
  int i, j, bit_val;

  for(j=0; j<num_hex; j++) {

    for(i=0; i<8; i++) {
      bit_val = (hex[j]>>i)&0x01;
      if (i==4) {
        printf("-");
      }
      printf("%d", bit_val);
    }

    printf(" ");

  }

  printf("\n");
}

void crc24_and_scramble_to_gen_phy_bit(char *crc_init_hex, PKT_INFO *pkt) {
  crc24(pkt->info_bit+5*8, pkt->num_info_bit-5*8, crc_init_hex, pkt->info_bit+pkt->num_info_bit);

  printf("after crc24\n");
  disp_bit_in_hex(pkt->info_bit, pkt->num_info_bit + 3*8);

  scramble(pkt->info_bit+5*8, pkt->num_info_bit-5*8+24, pkt->channel_number, pkt->phy_bit+5*8);
  memcpy(pkt->phy_bit, pkt->info_bit, 5*8);
  pkt->num_phy_bit = pkt->num_info_bit + 24;

  printf("after scramble %d %d\n", pkt->num_phy_bit , pkt->num_phy_byte);
  disp_bit_in_hex(pkt->phy_bit, pkt->num_phy_bit);
}

void crc24_and_scramble_byte_to_gen_phy_bit(char *crc_init_hex, PKT_INFO *pkt) {
  crc24(pkt->info_bit+5*8, pkt->num_info_bit-5*8, crc_init_hex, pkt->info_bit+pkt->num_info_bit);

  int crc24_checksum = crc24_byte(pkt->info_byte+5, pkt->num_info_byte-5, 0xAAAAAA); // 0x555555 --> 0xaaaaaa
  (pkt->info_byte+pkt->num_info_byte)[0] = crc24_checksum & 0xFF;
  (pkt->info_byte+pkt->num_info_byte)[1] = (crc24_checksum>>8) & 0xFF;
  (pkt->info_byte+pkt->num_info_byte)[2] = (crc24_checksum>>16) & 0xFF;

  printf("after crc24\n");
  disp_bit_in_hex(pkt->info_bit, pkt->num_info_bit + 3*8);
  disp_hex(pkt->info_byte, pkt->num_info_byte + 3);

  scramble(pkt->info_bit+5*8, pkt->num_info_bit-5*8+24, pkt->channel_number, pkt->phy_bit+5*8);
  memcpy(pkt->phy_bit, pkt->info_bit, 5*8);
  pkt->num_phy_bit = pkt->num_info_bit + 24;

  scramble_byte(pkt->info_byte+5, pkt->num_info_byte-5+3, pkt->channel_number, pkt->phy_byte+5);
  memcpy(pkt->phy_byte, pkt->info_byte, 5);
  pkt->num_phy_byte = pkt->num_info_byte + 3;

  printf("after scramble %d %d\n", pkt->num_phy_bit , pkt->num_phy_byte);
  disp_bit_in_hex(pkt->phy_bit, pkt->num_phy_bit);
  disp_hex(pkt->phy_byte, pkt->num_phy_byte);
}

int calculate_sample_for_DISCOVERY(char *pkt_str, PKT_INFO*pkt) {
// example
// ./btle_tx 37-DISCOVERY-TxAdd-1-RxAdd-0-AdvA-010203040506-FLAGS-02-LOCALNAME09-CA-TXPOWER-03-SERVICE03-180D1810-SERVICEDATA-180D40-MANUFDATA-0001FF-CONN_INTERVAL-0006 (-SERVICESOLI-0123)
// FLAGS: 0x01 LE Limited Discoverable Mode; 0x02 LE General Discoverable Mode
// SERVICE:
// 0x02 16-bit Service UUIDs More 16-bit UUIDs available
// 0x03 16-bit Service UUIDs Complete list of 16-bit UUIDs available
// 0x04 32-bit Service UUIDs More 32-bit UUIDs available
// 0x05 32-bit Service UUIDs Complete list of 32-bit UUIDs available
// 0x06 128-bit Service UUIDs More 128-bit UUIDs available
// 0x07 128-bit Service UUIDs Complete list of 128-bit UUIDs available
  char *current_p;
  int ret, num_bit_tmp, num_octet_tmp, i, j;

  pkt->num_info_bit = 0;
  pkt->num_info_byte = 0;

// gen preamble and access address
  num_bit_tmp = convert_hex_to_bit("AA", pkt->info_bit);
  num_octet_tmp = 1;
  pkt->info_byte[0] = 0xAA;

  printf("AA %d\n", num_bit_tmp);
  disp_bit(pkt->info_bit, num_bit_tmp);
  disp_hex_in_bit(pkt->info_byte, num_octet_tmp);

  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;
  pkt->num_info_byte = pkt->num_info_byte + num_octet_tmp;

  num_bit_tmp = convert_hex_to_bit("D6BE898E", pkt->info_bit + pkt->num_info_bit);
  num_octet_tmp = 4;
  (pkt->info_byte + pkt->num_info_byte)[0] = 0xD6;
  (pkt->info_byte + pkt->num_info_byte)[1] = 0xBE;
  (pkt->info_byte + pkt->num_info_byte)[2] = 0x89;
  (pkt->info_byte + pkt->num_info_byte)[3] = 0x8E;

  printf("D6BE898E %d\n", num_bit_tmp);
  disp_bit(pkt->info_bit + pkt->num_info_bit, num_bit_tmp);
  disp_hex_in_bit(pkt->info_byte + pkt->num_info_byte, num_octet_tmp);

  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;
  pkt->num_info_byte = pkt->num_info_byte + num_octet_tmp;

// get txadd and rxadd
  current_p = pkt_str;
  int txadd, rxadd;
  current_p = get_next_field_name_value(current_p, "TXADD", &txadd, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }

  current_p = get_next_field_name_value(current_p, "RXADD", &rxadd, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + 16; // 16 is header length
  pkt->num_info_byte = pkt->num_info_byte + 2;

// get AdvA
  current_p = get_next_field_name_bit(current_p, "ADVA", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 1, 6, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }

  num_octet_tmp = 6;
  (pkt->info_byte + pkt->num_info_byte)[0] = 0x06;
  (pkt->info_byte + pkt->num_info_byte)[1] = 0x05;
  (pkt->info_byte + pkt->num_info_byte)[2] = 0x04;
  (pkt->info_byte + pkt->num_info_byte)[3] = 0x03;
  (pkt->info_byte + pkt->num_info_byte)[4] = 0x02;
  (pkt->info_byte + pkt->num_info_byte)[5] = 0x01;
  printf("ADVA buffer begin from %d\n",  pkt->num_info_byte);

  printf("010203040506 %d\n", num_bit_tmp);
  disp_bit(pkt->info_bit + pkt->num_info_bit, num_bit_tmp);
  disp_hex_in_bit(pkt->info_byte + pkt->num_info_byte, num_octet_tmp);

  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;
  pkt->num_info_byte = pkt->num_info_byte + num_octet_tmp;

// then get AdvData. maximum 31 octets
  int octets_left_room = 31;
  while(ret == 0) {
    // get name of next field
    for(i=0; i<NUM_AD_TYPE; i++) {
      get_next_field_name(current_p, AD_TYPE_STR[i], &ret);
      if (ret == 0) {
        break;
      }
    }

    //printf("i %d %s\n", i, AD_TYPE_STR[i]);

    if (ret != 0) {
      printf("Get name of AD TYPE failed. i %d ret %d NUM_AD_TYPE %d\n", i, ret, NUM_AD_TYPE);
      return(-1);
    }

    if (i==(NUM_AD_TYPE-1)) { // it is SPACE field, should be processed later on.
      break;
    }

    // get data followed according to AD TYPE
    // except LOCAL_NAME, all others are values.
    octets_left_room = octets_left_room  - 2; // 2 -- length and AD_TYPE
    if (i == LOCAL_NAME08 || i == LOCAL_NAME09) {
      current_p = get_next_field_name_char(current_p, AD_TYPE_STR[i], pkt->info_bit+ 2*8 + pkt->num_info_bit, &num_bit_tmp, 0, octets_left_room, &ret);

      num_octet_tmp = num_bit_tmp/8;
      
      //sprintf((char*)(pkt->info_byte + 2 + pkt->num_info_byte), "CA1308 11950 22.626 113.823 8"); // this is fake. let us use real.
      for(j=0; j<num_octet_tmp; j++) {
        pkt->info_byte[2+pkt->num_info_byte+j] = bit_to_int(pkt->info_bit+ 2*8 + pkt->num_info_bit + j*8);
      }
      pkt->info_byte[2+pkt->num_info_byte+j] = 0;
      
      printf("display buffer begin from %d\n",  2 + pkt->num_info_byte);

      //printf("CA1308 11950 22.626 113.823 8 %d\n", num_bit_tmp); // this is fake. let us use real.
      printf("%s %d\n", (char *)(pkt->info_byte + 2+ pkt->num_info_byte), num_bit_tmp);
      
      disp_bit(pkt->info_bit + 2*8 + pkt->num_info_bit, num_bit_tmp);
      disp_hex_in_bit(pkt->info_byte + 2+ pkt->num_info_byte, num_octet_tmp);

    } else if (i == SERVICE02 || i == SERVICE03 || i == SERVICE04 || i == SERVICE05 || i == SERVICE06 || i == SERVICE07) {
      current_p = get_next_field_name_bit(current_p, AD_TYPE_STR[i], pkt->info_bit+ 2*8 + pkt->num_info_bit, &num_bit_tmp, 1, octets_left_room, &ret);
    } else if (i == SERVICE_DATA) {
      current_p = get_next_field_name_bit_part_flip(current_p, AD_TYPE_STR[i], pkt->info_bit+ 2*8 + pkt->num_info_bit, &num_bit_tmp, 2, octets_left_room, &ret);
    } else {
      current_p = get_next_field_name_bit(current_p, AD_TYPE_STR[i], pkt->info_bit+ 2*8 + pkt->num_info_bit, &num_bit_tmp, 0, octets_left_room, &ret);
    }
    if (ret == -1) { // failed
      return(-1);
    }

    // fill length and AD_TYPE octets
    num_octet_tmp = num_bit_tmp/8;
    int_to_bit(num_octet_tmp+1, pkt->info_bit + pkt->num_info_bit);
    (pkt->info_byte + pkt->num_info_byte)[0] = num_octet_tmp+1;
    int_to_bit(AD_TYPE_VAL[i], pkt->info_bit + pkt->num_info_bit + 8 );
    (pkt->info_byte + 1 + pkt->num_info_byte)[0] = AD_TYPE_VAL[i];

    printf("length and AD_TYPE %d\n", 16);
    disp_bit(pkt->info_bit + pkt->num_info_bit,  2*8);
    disp_hex_in_bit(pkt->info_byte + pkt->num_info_byte,  2);

    pkt->num_info_bit = pkt->num_info_bit + 2*8 + num_bit_tmp;
    pkt->num_info_byte = pkt->num_info_byte + 2 + num_octet_tmp;

    octets_left_room = octets_left_room  - num_octet_tmp;
  }

  int payload_len = (pkt->num_info_bit/8) - 7;
  printf("payload_len %d\n", payload_len);
  printf("num_info_bit %d\n", pkt->num_info_bit);
  printf("num_info_byte %d\n", pkt->num_info_byte);

  fill_adv_pdu_header(pkt->pkt_type, txadd, rxadd, payload_len, pkt->info_bit+5*8);
  fill_adv_pdu_header_byte(pkt->pkt_type, txadd, rxadd, payload_len, pkt->info_byte+5);

  printf("before crc24\n");
  disp_bit_in_hex(pkt->info_bit, pkt->num_info_bit);
  disp_hex(pkt->info_byte, pkt->num_info_byte);

  crc24_and_scramble_byte_to_gen_phy_bit("555555", pkt);
  printf("num_phy_bit %d\n", pkt->num_phy_bit);

  pkt->num_phy_sample = gen_sample_from_phy_bit(pkt->phy_bit, pkt->phy_sample, pkt->num_phy_bit);
  gen_sample_from_phy_byte(pkt->phy_byte, pkt->phy_sample1, pkt->num_phy_byte);
  printf("num_phy_sample %d\n", pkt->num_phy_sample);

// get space value
  if (ret==1) { // if space value not present
    pkt->space = DEFAULT_SPACE_MS;
    printf("space %d\n", pkt->space);
    return(0);
  }

  int space;
  current_p = get_next_field_name_value(current_p, "SPACE", &space, &ret);
  if (ret == -1) { // failed
    return(-1);
  }

  if (space <= 0) {
    printf("Invalid space!\n");
    return(-1);
  }

  pkt->space = space;
  printf("space %d\n", pkt->space);

  return(0);
}

int calculate_sample_for_ADV_IND(char *pkt_str, PKT_INFO *pkt) {
// example
// ./btle_tx 37-ADV_IND-TxAdd-1-RxAdd-0-AdvA-010203040506-AdvData-00112233445566778899AABBCCDDEEFF
  char *current_p;
  int ret, num_bit_tmp;

  pkt->num_info_bit = 0;

// gen preamble and access address
  pkt->num_info_bit = pkt->num_info_bit + convert_hex_to_bit("AA", pkt->info_bit);
  pkt->num_info_bit = pkt->num_info_bit + convert_hex_to_bit("D6BE898E", pkt->info_bit + pkt->num_info_bit);

// get txadd and rxadd
  current_p = pkt_str;
  int txadd, rxadd;
  current_p = get_next_field_name_value(current_p, "TXADD", &txadd, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }

  current_p = get_next_field_name_value(current_p, "RXADD", &rxadd, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + 16; // 16 is header length

// get AdvA and AdvData
  current_p = get_next_field_name_bit(current_p, "ADVA", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 1, 6, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

  current_p = get_next_field_name_bit(current_p, "ADVDATA", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 0, 31, &ret);
  if (ret == -1) { // failed
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

  int payload_len = (pkt->num_info_bit/8) - 7;
  printf("payload_len %d\n", payload_len);
  printf("num_info_bit %d\n", pkt->num_info_bit);

  fill_adv_pdu_header(pkt->pkt_type, txadd, rxadd, payload_len, pkt->info_bit+5*8);

  crc24_and_scramble_to_gen_phy_bit("555555", pkt);
  printf("num_phy_bit %d\n", pkt->num_phy_bit);

  pkt->num_phy_sample = gen_sample_from_phy_bit(pkt->phy_bit, pkt->phy_sample, pkt->num_phy_bit);
  printf("num_phy_sample %d\n", pkt->num_phy_sample);

// get space value
  if (ret==1) { // if space value not present
    pkt->space = DEFAULT_SPACE_MS;
    printf("space %d\n", pkt->space);
    return(0);
  }

  int space;
  current_p = get_next_field_name_value(current_p, "SPACE", &space, &ret);
  if (ret == -1) { // failed
    return(-1);
  }

  if (space <= 0) {
    printf("Invalid space!\n");
    return(-1);
  }

  pkt->space = space;
  printf("space %d\n", pkt->space);

  return(0);
}
int calculate_sample_for_IBEACON(char *pkt_str, PKT_INFO *pkt) {
// example
// ./btle_tx 37-IBEACON-AdvA-010203040506-UUID-B9407F30F5F8466EAFF925556B57FE6D-Major-0008-Minor-0009-TxPower-C5-Space-100 r10
// UUID indicates Estimote
  char *current_p;
  int ret, num_bit_tmp;

  pkt->num_info_bit = 0;

// gen preamble and access address
  pkt->num_info_bit = pkt->num_info_bit + convert_hex_to_bit("AA", pkt->info_bit);
  pkt->num_info_bit = pkt->num_info_bit + convert_hex_to_bit("D6BE898E", pkt->info_bit + pkt->num_info_bit);

  int txadd = 1;
  int rxadd = 0;
  int payload_len = 36;
  fill_adv_pdu_header(ADV_IND, txadd, rxadd, payload_len, pkt->info_bit+5*8);
  pkt->num_info_bit = pkt->num_info_bit + 16; // 16 is header length
  printf("payload_len %d\n", payload_len);

// get AdvA
  current_p = pkt_str;
  current_p = get_next_field_name_bit(current_p, "ADVA", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 1, 6, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

// set fixed ibeacon prefix
  num_bit_tmp = convert_hex_to_bit("02011A1AFF4C000215", pkt->info_bit+pkt->num_info_bit);
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

// get UUID
  current_p = get_next_field_name_bit(current_p, "UUID", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 0, 16, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

// get major
  current_p = get_next_field_name_bit(current_p, "MAJOR", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 0, 2, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

// get minor
  current_p = get_next_field_name_bit(current_p, "MINOR", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 0, 2, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

// get tx power
  current_p = get_next_field_name_bit(current_p, "TXPOWER", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 1, 1, &ret);
  if (ret == -1) { // failed
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

  printf("num_info_bit %d\n", pkt->num_info_bit);

  crc24_and_scramble_to_gen_phy_bit("555555", pkt);
  printf("num_phy_bit %d\n", pkt->num_phy_bit);

  pkt->num_phy_sample = gen_sample_from_phy_bit(pkt->phy_bit, pkt->phy_sample, pkt->num_phy_bit);
  printf("num_phy_sample %d\n", pkt->num_phy_sample);

// get space value
  if (ret==1) { // if space value not present
    pkt->space = DEFAULT_SPACE_MS;
    printf("space %d\n", pkt->space);
    return(0);
  }

  int space;
  current_p = get_next_field_name_value(current_p, "SPACE", &space, &ret);
  if (ret == -1) { // failed
    return(-1);
  }

  if (space <= 0) {
    printf("Invalid space!\n");
    return(-1);
  }

  pkt->space = space;
  printf("space %d\n", pkt->space);

  return(0);
}
int calculate_sample_for_ADV_DIRECT_IND(char *pkt_str, PKT_INFO *pkt) {
// example
// ./btle_tx 37-ADV_DIRECT_IND-TxAdd-1-RxAdd-0-AdvA-010203040506-InitA-0708090A0B0C
  char *current_p;
  int ret, num_bit_tmp;

  pkt->num_info_bit = 0;

// gen preamble and access address
  pkt->num_info_bit = pkt->num_info_bit + convert_hex_to_bit("AA", pkt->info_bit);
  pkt->num_info_bit = pkt->num_info_bit + convert_hex_to_bit("D6BE898E", pkt->info_bit + pkt->num_info_bit);

// get txadd and rxadd
  current_p = pkt_str;
  int txadd, rxadd;
  current_p = get_next_field_name_value(current_p, "TXADD", &txadd, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }

  current_p = get_next_field_name_value(current_p, "RXADD", &rxadd, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + 16; // 16 is header length

// get AdvA and InitA
  current_p = get_next_field_name_bit(current_p, "ADVA", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 1, 6, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

  current_p = get_next_field_name_bit(current_p, "INITA", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 1, 6, &ret);
  if (ret == -1) { // failed
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

  int payload_len = (pkt->num_info_bit/8) - 7;
  printf("payload_len %d\n", payload_len);
  printf("num_info_bit %d\n", pkt->num_info_bit);

  fill_adv_pdu_header(pkt->pkt_type, txadd, rxadd, payload_len, pkt->info_bit+5*8);

  crc24_and_scramble_to_gen_phy_bit("555555", pkt);
  printf("num_phy_bit %d\n", pkt->num_phy_bit);

  pkt->num_phy_sample = gen_sample_from_phy_bit(pkt->phy_bit, pkt->phy_sample, pkt->num_phy_bit);
  printf("num_phy_sample %d\n", pkt->num_phy_sample);

// get space value
  if (ret==1) { // if space value not present
    pkt->space = DEFAULT_SPACE_MS;
    printf("space %d\n", pkt->space);
    return(0);
  }

  int space;
  current_p = get_next_field_name_value(current_p, "SPACE", &space, &ret);
  if (ret == -1) { // failed
    return(-1);
  }

  if (space <= 0) {
    printf("Invalid space!\n");
    return(-1);
  }

  pkt->space = space;
  printf("space %d\n", pkt->space);

  return(0);
}
int calculate_sample_for_ADV_NONCONN_IND(char *pkt_str, PKT_INFO *pkt) {
// example
// ./btle_tx 37-ADV_NONCONN_IND-TxAdd-1-RxAdd-0-AdvA-010203040506-AdvData-00112233445566778899AABBCCDDEEFF
  return( calculate_sample_for_ADV_IND(pkt_str, pkt) );
}
int calculate_sample_for_ADV_SCAN_IND(char *pkt_str, PKT_INFO *pkt) {
// example
// ./btle_tx 37-ADV_SCAN_IND-TxAdd-1-RxAdd-0-AdvA-010203040506-AdvData-00112233445566778899AABBCCDDEEFF
  return( calculate_sample_for_ADV_IND(pkt_str, pkt) );
}
int calculate_sample_for_SCAN_REQ(char *pkt_str, PKT_INFO *pkt) {
// example
// ./btle_tx 37-SCAN_REQ-TxAdd-1-RxAdd-0-ScanA-010203040506-AdvA-0708090A0B0C
  char *current_p;
  int ret, num_bit_tmp;

  pkt->num_info_bit = 0;

// gen preamble and access address
  pkt->num_info_bit = pkt->num_info_bit + convert_hex_to_bit("AA", pkt->info_bit);
  pkt->num_info_bit = pkt->num_info_bit + convert_hex_to_bit("D6BE898E", pkt->info_bit + pkt->num_info_bit);

// get txadd and rxadd
  current_p = pkt_str;
  int txadd, rxadd;
  current_p = get_next_field_name_value(current_p, "TXADD", &txadd, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }

  current_p = get_next_field_name_value(current_p, "RXADD", &rxadd, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + 16; // 16 is header length

// get ScanA and AdvA
  current_p = get_next_field_name_bit(current_p, "SCANA", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 1, 6, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

  current_p = get_next_field_name_bit(current_p, "ADVA", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 1, 6, &ret);
  if (ret == -1) { // failed
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

  int payload_len = (pkt->num_info_bit/8) - 7;
  printf("payload_len %d\n", payload_len);
  printf("num_info_bit %d\n", pkt->num_info_bit);

  fill_adv_pdu_header(pkt->pkt_type, txadd, rxadd, payload_len, pkt->info_bit+5*8);

  crc24_and_scramble_to_gen_phy_bit("555555", pkt);
  printf("num_phy_bit %d\n", pkt->num_phy_bit);

  pkt->num_phy_sample = gen_sample_from_phy_bit(pkt->phy_bit, pkt->phy_sample, pkt->num_phy_bit);
  printf("num_phy_sample %d\n", pkt->num_phy_sample);

// get space value
  if (ret==1) { // if space value not present
    pkt->space = DEFAULT_SPACE_MS;
    printf("space %d\n", pkt->space);
    return(0);
  }

  int space;
  current_p = get_next_field_name_value(current_p, "SPACE", &space, &ret);
  if (ret == -1) { // failed
    return(-1);
  }

  if (space <= 0) {
    printf("Invalid space!\n");
    return(-1);
  }

  pkt->space = space;
  printf("space %d\n", pkt->space);

  return(0);
}
int calculate_sample_for_SCAN_RSP(char *pkt_str, PKT_INFO *pkt) {
// example
// ./btle_tx 37-SCAN_RSP-TxAdd-1-RxAdd-0-AdvA-010203040506-ScanRspData-00112233445566778899AABBCCDDEEFF
  char *current_p;
  int ret, num_bit_tmp;

  pkt->num_info_bit = 0;

// gen preamble and access address
  pkt->num_info_bit = pkt->num_info_bit + convert_hex_to_bit("AA", pkt->info_bit);
  pkt->num_info_bit = pkt->num_info_bit + convert_hex_to_bit("D6BE898E", pkt->info_bit + pkt->num_info_bit);

// get txadd and rxadd
  current_p = pkt_str;
  int txadd, rxadd;
  current_p = get_next_field_name_value(current_p, "TXADD", &txadd, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }

  current_p = get_next_field_name_value(current_p, "RXADD", &rxadd, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + 16; // 16 is header length

// get AdvA and ScanRspData
  current_p = get_next_field_name_bit(current_p, "ADVA", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 1, 6, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

  current_p = get_next_field_name_bit(current_p, "SCANRSPDATA", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 0, 31, &ret);
  if (ret == -1) { // failed
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

  int payload_len = (pkt->num_info_bit/8) - 7;
  printf("payload_len %d\n", payload_len);
  printf("num_info_bit %d\n", pkt->num_info_bit);

  fill_adv_pdu_header(pkt->pkt_type, txadd, rxadd, payload_len, pkt->info_bit+5*8);

  crc24_and_scramble_to_gen_phy_bit("555555", pkt);
  printf("num_phy_bit %d\n", pkt->num_phy_bit);

  pkt->num_phy_sample = gen_sample_from_phy_bit(pkt->phy_bit, pkt->phy_sample, pkt->num_phy_bit);
  printf("num_phy_sample %d\n", pkt->num_phy_sample);

// get space value
  if (ret==1) { // if space value not present
    pkt->space = DEFAULT_SPACE_MS;
    printf("space %d\n", pkt->space);
    return(0);
  }

  int space;
  current_p = get_next_field_name_value(current_p, "SPACE", &space, &ret);
  if (ret == -1) { // failed
    return(-1);
  }

  if (space <= 0) {
    printf("Invalid space!\n");
    return(-1);
  }

  pkt->space = space;
  printf("space %d\n", pkt->space);

  return(0);
}
int calculate_sample_for_CONNECT_REQ(char *pkt_str, PKT_INFO *pkt) {
// example
// ./btle_tx 37-CONNECT_REQ-TxAdd-1-RxAdd-0-InitA-010203040506-AdvA-0708090A0B0C-AA-01020304-CRCInit-050607-WinSize-08-WinOffset-090A-Interval-0B0C-Latency-0D0E-Timeout-0F00-ChM-0102030405-Hop-3-SCA-4
  char *current_p;
  int ret, num_bit_tmp;

  pkt->num_info_bit = 0;

// gen preamble and access address
  pkt->num_info_bit = pkt->num_info_bit + convert_hex_to_bit("AA", pkt->info_bit);
  pkt->num_info_bit = pkt->num_info_bit + convert_hex_to_bit("D6BE898E", pkt->info_bit + pkt->num_info_bit);

// get txadd and rxadd
  current_p = pkt_str;
  int txadd, rxadd;
  current_p = get_next_field_name_value(current_p, "TXADD", &txadd, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }

  current_p = get_next_field_name_value(current_p, "RXADD", &rxadd, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + 16; // 16 is header length

// get InitA and AdvA
  current_p = get_next_field_name_bit(current_p, "INITA", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 1, 6, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

  current_p = get_next_field_name_bit(current_p, "ADVA", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 1, 6, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

// get AA CRCInit WinSize WinOffset Interval Latency Timeout ChM Hop SCA
  current_p = get_next_field_name_bit(current_p, "AA", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 1, 4, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

  current_p = get_next_field_name_bit(current_p, "CRCINIT", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 0, 3, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

  current_p = get_next_field_name_bit(current_p, "WINSIZE", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 1, 1, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

  current_p = get_next_field_name_bit(current_p, "WINOFFSET", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 1, 2, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

  current_p = get_next_field_name_bit(current_p, "INTERVAL", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 1, 2, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

  current_p = get_next_field_name_bit(current_p, "LATENCY", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 1, 2, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

  current_p = get_next_field_name_bit(current_p, "TIMEOUT", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 1, 2, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

  current_p = get_next_field_name_bit(current_p, "CHM", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 1, 5, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

  int hop;
  current_p = get_next_field_name_value(current_p, "HOP", &hop, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + 5;

  int sca;
  current_p = get_next_field_name_value(current_p, "SCA", &sca, &ret);
  if (ret == -1) { // failed
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + 3;

  int payload_len = (pkt->num_info_bit/8) - 7;
  printf("payload_len %d\n", payload_len);
  printf("num_info_bit %d\n", pkt->num_info_bit);

  fill_adv_pdu_header(pkt->pkt_type, txadd, rxadd, payload_len, pkt->info_bit+5*8);
  fill_hop_sca(hop, sca, pkt->info_bit+pkt->num_info_bit-8);

  crc24_and_scramble_to_gen_phy_bit("555555", pkt);
  printf("num_phy_bit %d\n", pkt->num_phy_bit);

  pkt->num_phy_sample = gen_sample_from_phy_bit(pkt->phy_bit, pkt->phy_sample, pkt->num_phy_bit);
  printf("num_phy_sample %d\n", pkt->num_phy_sample);

// get space value
  if (ret==1) { // if space value not present
    pkt->space = DEFAULT_SPACE_MS;
    printf("space %d\n", pkt->space);
    return(0);
  }

  int space;
  current_p = get_next_field_name_value(current_p, "SPACE", &space, &ret);
  if (ret == -1) { // failed
    return(-1);
  }

  if (space <= 0) {
    printf("Invalid space!\n");
    return(-1);
  }

  pkt->space = space;
  printf("space %d\n", pkt->space);

  return(0);
}
int calculate_sample_for_LL_DATA(char *pkt_str, PKT_INFO *pkt) {
// example
// Connection establishment (http://processors.wiki.ti.com/index.php/BLE_sniffer_guide)
// ./btle_tx 37-ADV_IND-TxAdd-0-RxAdd-0-AdvA-90D7EBB19299-AdvData-0201050702031802180418-Space-100  37-CONNECT_REQ-TxAdd-0-RxAdd-0-InitA-001830EA965F-AdvA-90D7EBB19299-AA-60850A1B-CRCInit-A77B22-WinSize-02-WinOffset-000F-Interval-0050-Latency-0000-Timeout-07D0-ChM-1FFFFFFFFF-Hop-9-SCA-5-Space-100 9-LL_DATA-AA-60850A1B-LLID-1-NESN-0-SN-0-MD-0-DATA-X-CRCInit-A77B22-Space-100
  char *current_p;
  int ret, num_bit_tmp;

  pkt->num_info_bit = 0;

// gen preamble (may be changed later according to access address
  pkt->num_info_bit = pkt->num_info_bit + convert_hex_to_bit("AA", pkt->info_bit);

// get access address
  current_p = pkt_str;
  current_p = get_next_field_name_bit(current_p, "AA", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 1, 4, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  if ( (*(pkt->info_bit+pkt->num_info_bit) ) == 1 ) {
    convert_hex_to_bit("55", pkt->info_bit);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

// get LLID NESN SN MD
  int llid, nesn, sn, md;
  current_p = get_next_field_name_value(current_p, "LLID", &llid, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }

  current_p = get_next_field_name_value(current_p, "NESN", &nesn, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }

  current_p = get_next_field_name_value(current_p, "SN", &sn, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }

  current_p = get_next_field_name_value(current_p, "MD", &md, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + 16; // 16 is header length

// get DATA
  current_p = get_next_field_name_bit(current_p, "DATA", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 0, 31, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

  int payload_len = (pkt->num_info_bit/8) - 7;
  printf("payload_len %d\n", payload_len);
  printf("num_info_bit %d\n", pkt->num_info_bit);

  fill_data_pdu_header(llid, nesn, sn, md, payload_len, pkt->info_bit+5*8);

// get CRC init
  char crc_init[7];
  current_p = get_next_field_name_hex(current_p, "CRCINIT", crc_init, 0, 3, &ret);
  if (ret == -1) { // failed
    return(-1);
  }
  crc24_and_scramble_to_gen_phy_bit(crc_init, pkt);
  printf("num_phy_bit %d\n", pkt->num_phy_bit);

  pkt->num_phy_sample = gen_sample_from_phy_bit(pkt->phy_bit, pkt->phy_sample, pkt->num_phy_bit);
  printf("num_phy_sample %d\n", pkt->num_phy_sample);

// get space value
  if (ret==1) { // if space value not present
    pkt->space = DEFAULT_SPACE_MS;
    printf("space %d\n", pkt->space);
    return(0);
  }

  int space;
  current_p = get_next_field_name_value(current_p, "SPACE", &space, &ret);
  if (ret == -1) { // failed
    return(-1);
  }

  if (space <= 0) {
    printf("Invalid space!\n");
    return(-1);
  }

  pkt->space = space;
  printf("space %d\n", pkt->space);

  return(0);
}
int calculate_sample_for_LL_CONNECTION_UPDATE_REQ(char *pkt_str, PKT_INFO *pkt) {
// example
// Connection establishment (http://processors.wiki.ti.com/index.php/BLE_sniffer_guide)
// ./btle_tx 37-ADV_IND-TxAdd-0-RxAdd-0-AdvA-90D7EBB19299-AdvData-0201050702031802180418-Space-100  37-CONNECT_REQ-TxAdd-0-RxAdd-0-InitA-001830EA965F-AdvA-90D7EBB19299-AA-60850A1B-CRCInit-A77B22-WinSize-02-WinOffset-000F-Interval-0050-Latency-0000-Timeout-07D0-ChM-1FFFFFFFFF-Hop-9-SCA-5-Space-100 9-LL_CONNECTION_UPDATE_REQ-AA-60850A1B-LLID-1-NESN-0-SN-0-MD-0-WinSize-02-WinOffset-000F-Interval-0050-Latency-0000-Timeout-07D0-Instant-0000-CRCInit-A77B22-Space-100
  char *current_p;
  int ret, num_bit_tmp;

  pkt->num_info_bit = 0;

// gen preamble (may be changed later according to access address
  pkt->num_info_bit = pkt->num_info_bit + convert_hex_to_bit("AA", pkt->info_bit);

// get access address
  current_p = pkt_str;
  current_p = get_next_field_name_bit(current_p, "AA", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 1, 4, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  if ( (*(pkt->info_bit+pkt->num_info_bit) ) == 1 ) {
    convert_hex_to_bit("55", pkt->info_bit);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

// get LLID NESN SN MD
  int llid, nesn, sn, md;
  current_p = get_next_field_name_value(current_p, "LLID", &llid, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }

  current_p = get_next_field_name_value(current_p, "NESN", &nesn, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }

  current_p = get_next_field_name_value(current_p, "SN", &sn, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }

  current_p = get_next_field_name_value(current_p, "MD", &md, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + 16; // 16 is header length

  // fill opcode
  get_opcode(pkt->pkt_type, pkt->info_bit + pkt->num_info_bit);
  pkt->num_info_bit = pkt->num_info_bit + 8; // 8 is opcode

// get WinSize WinOffset Interval Latency Timeout Instant
  current_p = get_next_field_name_bit(current_p, "WINSIZE", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 0, 1, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;
  current_p = get_next_field_name_bit(current_p, "WINOFFSET", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 1, 2, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

  current_p = get_next_field_name_bit(current_p, "INTERVAL", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 1, 2, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

  current_p = get_next_field_name_bit(current_p, "LATENCY", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 1, 2, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

  current_p = get_next_field_name_bit(current_p, "TIMEOUT", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 1, 2, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

  current_p = get_next_field_name_bit(current_p, "INSTANT", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 1, 2, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

  int payload_len = (pkt->num_info_bit/8) - 7;
  printf("payload_len %d\n", payload_len);
  printf("num_info_bit %d\n", pkt->num_info_bit);

  fill_data_pdu_header(llid, nesn, sn, md, payload_len, pkt->info_bit+5*8);

// get CRC init
  char crc_init[7];
  current_p = get_next_field_name_hex(current_p, "CRCINIT", crc_init, 0, 3, &ret);
  if (ret == -1) { // failed
    return(-1);
  }
  crc24_and_scramble_to_gen_phy_bit(crc_init, pkt);
  printf("num_phy_bit %d\n", pkt->num_phy_bit);

  pkt->num_phy_sample = gen_sample_from_phy_bit(pkt->phy_bit, pkt->phy_sample, pkt->num_phy_bit);
  printf("num_phy_sample %d\n", pkt->num_phy_sample);

// get space value
  if (ret==1) { // if space value not present
    pkt->space = DEFAULT_SPACE_MS;
    printf("space %d\n", pkt->space);
    return(0);
  }

  int space;
  current_p = get_next_field_name_value(current_p, "SPACE", &space, &ret);
  if (ret == -1) { // failed
    return(-1);
  }

  if (space <= 0) {
    printf("Invalid space!\n");
    return(-1);
  }

  pkt->space = space;
  printf("space %d\n", pkt->space);

  return(0);
}
int calculate_sample_for_LL_CHANNEL_MAP_REQ(char *pkt_str, PKT_INFO *pkt) {
// example
// Connection establishment (http://processors.wiki.ti.com/index.php/BLE_sniffer_guide)
// ./btle_tx 37-ADV_IND-TxAdd-0-RxAdd-0-AdvA-90D7EBB19299-AdvData-0201050702031802180418-Space-100  37-CONNECT_REQ-TxAdd-0-RxAdd-0-InitA-001830EA965F-AdvA-90D7EBB19299-AA-60850A1B-CRCInit-A77B22-WinSize-02-WinOffset-000F-Interval-0050-Latency-0000-Timeout-07D0-ChM-1FFFFFFFFF-Hop-9-SCA-5-Space-100 9-LL_CHANNEL_MAP_REQ-AA-60850A1B-LLID-1-NESN-0-SN-0-MD-0-ChM-1FFFFFFFFF-Instant-0001-CRCInit-A77B22-Space-100
  char *current_p;
  int ret, num_bit_tmp;

  pkt->num_info_bit = 0;

// gen preamble (may be changed later according to access address
  pkt->num_info_bit = pkt->num_info_bit + convert_hex_to_bit("AA", pkt->info_bit);

// get access address
  current_p = pkt_str;
  current_p = get_next_field_name_bit(current_p, "AA", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 1, 4, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  if ( (*(pkt->info_bit+pkt->num_info_bit) ) == 1 ) {
    convert_hex_to_bit("55", pkt->info_bit);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

// get LLID NESN SN MD
  int llid, nesn, sn, md;
  current_p = get_next_field_name_value(current_p, "LLID", &llid, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }

  current_p = get_next_field_name_value(current_p, "NESN", &nesn, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }

  current_p = get_next_field_name_value(current_p, "SN", &sn, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }

  current_p = get_next_field_name_value(current_p, "MD", &md, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + 16; // 16 is header length

  // fill opcode
  get_opcode(pkt->pkt_type, pkt->info_bit + pkt->num_info_bit);
  pkt->num_info_bit = pkt->num_info_bit + 8; // 8 is opcode

// get ChM Instant
  current_p = get_next_field_name_bit(current_p, "CHM", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 1, 5, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;
  current_p = get_next_field_name_bit(current_p, "INSTANT", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 1, 2, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

  int payload_len = (pkt->num_info_bit/8) - 7;
  printf("payload_len %d\n", payload_len);
  printf("num_info_bit %d\n", pkt->num_info_bit);

  fill_data_pdu_header(llid, nesn, sn, md, payload_len, pkt->info_bit+5*8);

// get CRC init
  char crc_init[7];
  current_p = get_next_field_name_hex(current_p, "CRCINIT", crc_init, 0, 3, &ret);
  if (ret == -1) { // failed
    return(-1);
  }
  crc24_and_scramble_to_gen_phy_bit(crc_init, pkt);
  printf("num_phy_bit %d\n", pkt->num_phy_bit);

  pkt->num_phy_sample = gen_sample_from_phy_bit(pkt->phy_bit, pkt->phy_sample, pkt->num_phy_bit);
  printf("num_phy_sample %d\n", pkt->num_phy_sample);

// get space value
  if (ret==1) { // if space value not present
    pkt->space = DEFAULT_SPACE_MS;
    printf("space %d\n", pkt->space);
    return(0);
  }

  int space;
  current_p = get_next_field_name_value(current_p, "SPACE", &space, &ret);
  if (ret == -1) { // failed
    return(-1);
  }

  if (space <= 0) {
    printf("Invalid space!\n");
    return(-1);
  }

  pkt->space = space;
  printf("space %d\n", pkt->space);

  return(0);
}
int calculate_sample_for_LL_TERMINATE_IND(char *pkt_str, PKT_INFO *pkt) {
// example
// Connection establishment (http://processors.wiki.ti.com/index.php/BLE_sniffer_guide)
// ./btle_tx 37-ADV_IND-TxAdd-0-RxAdd-0-AdvA-90D7EBB19299-AdvData-0201050702031802180418-Space-100  37-CONNECT_REQ-TxAdd-0-RxAdd-0-InitA-001830EA965F-AdvA-90D7EBB19299-AA-60850A1B-CRCInit-A77B22-WinSize-02-WinOffset-000F-Interval-0050-Latency-0000-Timeout-07D0-ChM-1FFFFFFFFF-Hop-9-SCA-5-Space-100 9-LL_TERMINATE_IND-AA-60850A1B-LLID-1-NESN-0-SN-0-MD-0-ErrorCode-00-CRCInit-A77B22-Space-100
  char *current_p;
  int ret, num_bit_tmp;

  pkt->num_info_bit = 0;

// gen preamble (may be changed later according to access address
  pkt->num_info_bit = pkt->num_info_bit + convert_hex_to_bit("AA", pkt->info_bit);

// get access address
  current_p = pkt_str;
  current_p = get_next_field_name_bit(current_p, "AA", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 1, 4, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  if ( (*(pkt->info_bit+pkt->num_info_bit) ) == 1 ) {
    convert_hex_to_bit("55", pkt->info_bit);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

// get LLID NESN SN MD
  int llid, nesn, sn, md;
  current_p = get_next_field_name_value(current_p, "LLID", &llid, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }

  current_p = get_next_field_name_value(current_p, "NESN", &nesn, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }

  current_p = get_next_field_name_value(current_p, "SN", &sn, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }

  current_p = get_next_field_name_value(current_p, "MD", &md, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + 16; // 16 is header length

  // fill opcode
  get_opcode(pkt->pkt_type, pkt->info_bit + pkt->num_info_bit);
  pkt->num_info_bit = pkt->num_info_bit + 8; // 8 is opcode

// get ErrorCode
  current_p = get_next_field_name_bit(current_p, "ERRORCODE", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 0, 1, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

  int payload_len = (pkt->num_info_bit/8) - 7;
  printf("payload_len %d\n", payload_len);
  printf("num_info_bit %d\n", pkt->num_info_bit);

  fill_data_pdu_header(llid, nesn, sn, md, payload_len, pkt->info_bit+5*8);

// get CRC init
  char crc_init[7];
  current_p = get_next_field_name_hex(current_p, "CRCINIT", crc_init, 0, 3, &ret);
  if (ret == -1) { // failed
    return(-1);
  }
  crc24_and_scramble_to_gen_phy_bit(crc_init, pkt);
  printf("num_phy_bit %d\n", pkt->num_phy_bit);

  pkt->num_phy_sample = gen_sample_from_phy_bit(pkt->phy_bit, pkt->phy_sample, pkt->num_phy_bit);
  printf("num_phy_sample %d\n", pkt->num_phy_sample);

// get space value
  if (ret==1) { // if space value not present
    pkt->space = DEFAULT_SPACE_MS;
    printf("space %d\n", pkt->space);
    return(0);
  }

  int space;
  current_p = get_next_field_name_value(current_p, "SPACE", &space, &ret);
  if (ret == -1) { // failed
    return(-1);
  }

  if (space <= 0) {
    printf("Invalid space!\n");
    return(-1);
  }

  pkt->space = space;
  printf("space %d\n", pkt->space);

  return(0);
}
int calculate_sample_for_LL_ENC_REQ(char *pkt_str, PKT_INFO *pkt) {
// example
// Connection establishment (http://processors.wiki.ti.com/index.php/BLE_sniffer_guide)
// ./btle_tx 37-ADV_IND-TxAdd-0-RxAdd-0-AdvA-90D7EBB19299-AdvData-0201050702031802180418-Space-100  37-CONNECT_REQ-TxAdd-0-RxAdd-0-InitA-001830EA965F-AdvA-90D7EBB19299-AA-60850A1B-CRCInit-A77B22-WinSize-02-WinOffset-000F-Interval-0050-Latency-0000-Timeout-07D0-ChM-1FFFFFFFFF-Hop-9-SCA-5-Space-100 9-LL_ENC_REQ-AA-60850A1B-LLID-1-NESN-0-SN-0-MD-0-Rand-0102030405060708-EDIV-090A-SKDm-0102030405060708-IVm-090A0B0C-CRCInit-A77B22-Space-100
  char *current_p;
  int ret, num_bit_tmp;

  pkt->num_info_bit = 0;

// gen preamble (may be changed later according to access address
  pkt->num_info_bit = pkt->num_info_bit + convert_hex_to_bit("AA", pkt->info_bit);

// get access address
  current_p = pkt_str;
  current_p = get_next_field_name_bit(current_p, "AA", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 1, 4, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  if ( (*(pkt->info_bit+pkt->num_info_bit) ) == 1 ) {
    convert_hex_to_bit("55", pkt->info_bit);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

// get LLID NESN SN MD
  int llid, nesn, sn, md;
  current_p = get_next_field_name_value(current_p, "LLID", &llid, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }

  current_p = get_next_field_name_value(current_p, "NESN", &nesn, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }

  current_p = get_next_field_name_value(current_p, "SN", &sn, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }

  current_p = get_next_field_name_value(current_p, "MD", &md, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + 16; // 16 is header length

  // fill opcode
  get_opcode(pkt->pkt_type, pkt->info_bit + pkt->num_info_bit);
  pkt->num_info_bit = pkt->num_info_bit + 8; // 8 is opcode

// get Rand EDIV SKDm IVm
  current_p = get_next_field_name_bit(current_p, "RAND", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 1, 8, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

  current_p = get_next_field_name_bit(current_p, "EDIV", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 1, 2, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

  current_p = get_next_field_name_bit(current_p, "SKDM", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 1, 8, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

  current_p = get_next_field_name_bit(current_p, "IVM", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 1, 4, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

  int payload_len = (pkt->num_info_bit/8) - 7;
  printf("payload_len %d\n", payload_len);
  printf("num_info_bit %d\n", pkt->num_info_bit);

  fill_data_pdu_header(llid, nesn, sn, md, payload_len, pkt->info_bit+5*8);

// get CRC init
  char crc_init[7];
  current_p = get_next_field_name_hex(current_p, "CRCINIT", crc_init, 0, 3, &ret);
  if (ret == -1) { // failed
    return(-1);
  }
  crc24_and_scramble_to_gen_phy_bit(crc_init, pkt);
  printf("num_phy_bit %d\n", pkt->num_phy_bit);

  pkt->num_phy_sample = gen_sample_from_phy_bit(pkt->phy_bit, pkt->phy_sample, pkt->num_phy_bit);
  printf("num_phy_sample %d\n", pkt->num_phy_sample);

// get space value
  if (ret==1) { // if space value not present
    pkt->space = DEFAULT_SPACE_MS;
    printf("space %d\n", pkt->space);
    return(0);
  }

  int space;
  current_p = get_next_field_name_value(current_p, "SPACE", &space, &ret);
  if (ret == -1) { // failed
    return(-1);
  }

  if (space <= 0) {
    printf("Invalid space!\n");
    return(-1);
  }

  pkt->space = space;
  printf("space %d\n", pkt->space);

  return(0);
}
int calculate_sample_for_LL_ENC_RSP(char *pkt_str, PKT_INFO *pkt) {
// example
// Connection establishment (http://processors.wiki.ti.com/index.php/BLE_sniffer_guide)
// ./btle_tx 37-ADV_IND-TxAdd-0-RxAdd-0-AdvA-90D7EBB19299-AdvData-0201050702031802180418-Space-100  37-CONNECT_REQ-TxAdd-0-RxAdd-0-InitA-001830EA965F-AdvA-90D7EBB19299-AA-60850A1B-CRCInit-A77B22-WinSize-02-WinOffset-000F-Interval-0050-Latency-0000-Timeout-07D0-ChM-1FFFFFFFFF-Hop-9-SCA-5-Space-100 9-LL_ENC_RSP-AA-60850A1B-LLID-1-NESN-0-SN-0-MD-0-SKDs-0102030405060708-IVs-01020304-CRCInit-A77B22-Space-100
  char *current_p;
  int ret, num_bit_tmp;

  pkt->num_info_bit = 0;

// gen preamble (may be changed later according to access address
  pkt->num_info_bit = pkt->num_info_bit + convert_hex_to_bit("AA", pkt->info_bit);

// get access address
  current_p = pkt_str;
  current_p = get_next_field_name_bit(current_p, "AA", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 1, 4, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  if ( (*(pkt->info_bit+pkt->num_info_bit) ) == 1 ) {
    convert_hex_to_bit("55", pkt->info_bit);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

// get LLID NESN SN MD
  int llid, nesn, sn, md;
  current_p = get_next_field_name_value(current_p, "LLID", &llid, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }

  current_p = get_next_field_name_value(current_p, "NESN", &nesn, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }

  current_p = get_next_field_name_value(current_p, "SN", &sn, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }

  current_p = get_next_field_name_value(current_p, "MD", &md, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + 16; // 16 is header length

  // fill opcode
  get_opcode(pkt->pkt_type, pkt->info_bit + pkt->num_info_bit);
  pkt->num_info_bit = pkt->num_info_bit + 8; // 8 is opcode

// get SKDs IVs
  current_p = get_next_field_name_bit(current_p, "SKDS", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 1, 8, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

  current_p = get_next_field_name_bit(current_p, "IVS", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 1, 4, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

  int payload_len = (pkt->num_info_bit/8) - 7;
  printf("payload_len %d\n", payload_len);
  printf("num_info_bit %d\n", pkt->num_info_bit);

  fill_data_pdu_header(llid, nesn, sn, md, payload_len, pkt->info_bit+5*8);

// get CRC init
  char crc_init[7];
  current_p = get_next_field_name_hex(current_p, "CRCINIT", crc_init, 0, 3, &ret);
  if (ret == -1) { // failed
    return(-1);
  }
  crc24_and_scramble_to_gen_phy_bit(crc_init, pkt);
  printf("num_phy_bit %d\n", pkt->num_phy_bit);

  pkt->num_phy_sample = gen_sample_from_phy_bit(pkt->phy_bit, pkt->phy_sample, pkt->num_phy_bit);
  printf("num_phy_sample %d\n", pkt->num_phy_sample);

// get space value
  if (ret==1) { // if space value not present
    pkt->space = DEFAULT_SPACE_MS;
    printf("space %d\n", pkt->space);
    return(0);
  }

  int space;
  current_p = get_next_field_name_value(current_p, "SPACE", &space, &ret);
  if (ret == -1) { // failed
    return(-1);
  }

  if (space <= 0) {
    printf("Invalid space!\n");
    return(-1);
  }

  pkt->space = space;
  printf("space %d\n", pkt->space);

  return(0);
}

int calculate_sample_for_LL_START_ENC_REQ(char *pkt_str, PKT_INFO *pkt) {
// example
// Connection establishment (http://processors.wiki.ti.com/index.php/BLE_sniffer_guide)
// ./btle_tx 37-ADV_IND-TxAdd-0-RxAdd-0-AdvA-90D7EBB19299-AdvData-0201050702031802180418-Space-100  37-CONNECT_REQ-TxAdd-0-RxAdd-0-InitA-001830EA965F-AdvA-90D7EBB19299-AA-60850A1B-CRCInit-A77B22-WinSize-02-WinOffset-000F-Interval-0050-Latency-0000-Timeout-07D0-ChM-1FFFFFFFFF-Hop-9-SCA-5-Space-100 9-LL_START_ENC_REQ-AA-60850A1B-LLID-1-NESN-0-SN-0-MD-0-CRCInit-A77B22-Space-100
  char *current_p;
  int ret, num_bit_tmp;

  pkt->num_info_bit = 0;

// gen preamble (may be changed later according to access address
  pkt->num_info_bit = pkt->num_info_bit + convert_hex_to_bit("AA", pkt->info_bit);

// get access address
  current_p = pkt_str;
  current_p = get_next_field_name_bit(current_p, "AA", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 1, 4, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  if ( (*(pkt->info_bit+pkt->num_info_bit) ) == 1 ) {
    convert_hex_to_bit("55", pkt->info_bit);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

// get LLID NESN SN MD
  int llid, nesn, sn, md;
  current_p = get_next_field_name_value(current_p, "LLID", &llid, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }

  current_p = get_next_field_name_value(current_p, "NESN", &nesn, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }

  current_p = get_next_field_name_value(current_p, "SN", &sn, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }

  current_p = get_next_field_name_value(current_p, "MD", &md, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + 16; // 16 is header length

  // fill opcode
  get_opcode(pkt->pkt_type, pkt->info_bit + pkt->num_info_bit);
  pkt->num_info_bit = pkt->num_info_bit + 8; // 8 is opcode

// get NO PAYLOAD
// ....

  int payload_len = (pkt->num_info_bit/8) - 7;
  printf("payload_len %d\n", payload_len);
  printf("num_info_bit %d\n", pkt->num_info_bit);

  fill_data_pdu_header(llid, nesn, sn, md, payload_len, pkt->info_bit+5*8);

// get CRC init
  char crc_init[7];
  current_p = get_next_field_name_hex(current_p, "CRCINIT", crc_init, 0, 3, &ret);
  if (ret == -1) { // failed
    return(-1);
  }
  crc24_and_scramble_to_gen_phy_bit(crc_init, pkt);
  printf("num_phy_bit %d\n", pkt->num_phy_bit);

  pkt->num_phy_sample = gen_sample_from_phy_bit(pkt->phy_bit, pkt->phy_sample, pkt->num_phy_bit);
  printf("num_phy_sample %d\n", pkt->num_phy_sample);

// get space value
  if (ret==1) { // if space value not present
    pkt->space = DEFAULT_SPACE_MS;
    printf("space %d\n", pkt->space);
    return(0);
  }

  int space;
  current_p = get_next_field_name_value(current_p, "SPACE", &space, &ret);
  if (ret == -1) { // failed
    return(-1);
  }

  if (space <= 0) {
    printf("Invalid space!\n");
    return(-1);
  }

  pkt->space = space;
  printf("space %d\n", pkt->space);

  return(0);
}
int calculate_sample_for_LL_START_ENC_RSP(char *pkt_str, PKT_INFO *pkt) {
// example
// Connection establishment (http://processors.wiki.ti.com/index.php/BLE_sniffer_guide)
// ./btle_tx 37-ADV_IND-TxAdd-0-RxAdd-0-AdvA-90D7EBB19299-AdvData-0201050702031802180418-Space-100  37-CONNECT_REQ-TxAdd-0-RxAdd-0-InitA-001830EA965F-AdvA-90D7EBB19299-AA-60850A1B-CRCInit-A77B22-WinSize-02-WinOffset-000F-Interval-0050-Latency-0000-Timeout-07D0-ChM-1FFFFFFFFF-Hop-9-SCA-5-Space-100 9-LL_START_ENC_RSP-AA-60850A1B-LLID-1-NESN-0-SN-0-MD-0-CRCInit-A77B22-Space-100

  return( calculate_sample_for_LL_START_ENC_REQ(pkt_str, pkt) );
}
int calculate_sample_for_LL_UNKNOWN_RSP(char *pkt_str, PKT_INFO *pkt) {
// example
// Connection establishment (http://processors.wiki.ti.com/index.php/BLE_sniffer_guide)
// ./btle_tx 37-ADV_IND-TxAdd-0-RxAdd-0-AdvA-90D7EBB19299-AdvData-0201050702031802180418-Space-100  37-CONNECT_REQ-TxAdd-0-RxAdd-0-InitA-001830EA965F-AdvA-90D7EBB19299-AA-60850A1B-CRCInit-A77B22-WinSize-02-WinOffset-000F-Interval-0050-Latency-0000-Timeout-07D0-ChM-1FFFFFFFFF-Hop-9-SCA-5-Space-100 9-LL_UNKNOWN_RSP-AA-60850A1B-LLID-1-NESN-0-SN-0-MD-0-UnknownType-01-CRCInit-A77B22-Space-100
  char *current_p;
  int ret, num_bit_tmp;

  pkt->num_info_bit = 0;

// gen preamble (may be changed later according to access address
  pkt->num_info_bit = pkt->num_info_bit + convert_hex_to_bit("AA", pkt->info_bit);

// get access address
  current_p = pkt_str;
  current_p = get_next_field_name_bit(current_p, "AA", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 1, 4, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  if ( (*(pkt->info_bit+pkt->num_info_bit) ) == 1 ) {
    convert_hex_to_bit("55", pkt->info_bit);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

// get LLID NESN SN MD
  int llid, nesn, sn, md;
  current_p = get_next_field_name_value(current_p, "LLID", &llid, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }

  current_p = get_next_field_name_value(current_p, "NESN", &nesn, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }

  current_p = get_next_field_name_value(current_p, "SN", &sn, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }

  current_p = get_next_field_name_value(current_p, "MD", &md, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + 16; // 16 is header length

  // fill opcode
  get_opcode(pkt->pkt_type, pkt->info_bit + pkt->num_info_bit);
  pkt->num_info_bit = pkt->num_info_bit + 8; // 8 is opcode

// get UnknownType
  current_p = get_next_field_name_bit(current_p, "UNKNOWNTYPE", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 0, 1, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

  int payload_len = (pkt->num_info_bit/8) - 7;
  printf("payload_len %d\n", payload_len);
  printf("num_info_bit %d\n", pkt->num_info_bit);

  fill_data_pdu_header(llid, nesn, sn, md, payload_len, pkt->info_bit+5*8);

// get CRC init
  char crc_init[7];
  current_p = get_next_field_name_hex(current_p, "CRCINIT", crc_init, 0, 3, &ret);
  if (ret == -1) { // failed
    return(-1);
  }
  crc24_and_scramble_to_gen_phy_bit(crc_init, pkt);
  printf("num_phy_bit %d\n", pkt->num_phy_bit);

  pkt->num_phy_sample = gen_sample_from_phy_bit(pkt->phy_bit, pkt->phy_sample, pkt->num_phy_bit);
  printf("num_phy_sample %d\n", pkt->num_phy_sample);

// get space value
  if (ret==1) { // if space value not present
    pkt->space = DEFAULT_SPACE_MS;
    printf("space %d\n", pkt->space);
    return(0);
  }

  int space;
  current_p = get_next_field_name_value(current_p, "SPACE", &space, &ret);
  if (ret == -1) { // failed
    return(-1);
  }

  if (space <= 0) {
    printf("Invalid space!\n");
    return(-1);
  }

  pkt->space = space;
  printf("space %d\n", pkt->space);

  return(0);
}
int calculate_sample_for_LL_FEATURE_REQ(char *pkt_str, PKT_INFO *pkt) {
// example
// Connection establishment (http://processors.wiki.ti.com/index.php/BLE_sniffer_guide)
// ./btle_tx 37-ADV_IND-TxAdd-0-RxAdd-0-AdvA-90D7EBB19299-AdvData-0201050702031802180418-Space-100  37-CONNECT_REQ-TxAdd-0-RxAdd-0-InitA-001830EA965F-AdvA-90D7EBB19299-AA-60850A1B-CRCInit-A77B22-WinSize-02-WinOffset-000F-Interval-0050-Latency-0000-Timeout-07D0-ChM-1FFFFFFFFF-Hop-9-SCA-5-Space-100 9-LL_FEATURE_REQ-AA-60850A1B-LLID-1-NESN-0-SN-0-MD-0-FeatureSet-0102030405060708-CRCInit-A77B22-Space-100
  char *current_p;
  int ret, num_bit_tmp;

  pkt->num_info_bit = 0;

// gen preamble (may be changed later according to access address
  pkt->num_info_bit = pkt->num_info_bit + convert_hex_to_bit("AA", pkt->info_bit);

// get access address
  current_p = pkt_str;
  current_p = get_next_field_name_bit(current_p, "AA", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 1, 4, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  if ( (*(pkt->info_bit+pkt->num_info_bit) ) == 1 ) {
    convert_hex_to_bit("55", pkt->info_bit);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

// get LLID NESN SN MD
  int llid, nesn, sn, md;
  current_p = get_next_field_name_value(current_p, "LLID", &llid, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }

  current_p = get_next_field_name_value(current_p, "NESN", &nesn, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }

  current_p = get_next_field_name_value(current_p, "SN", &sn, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }

  current_p = get_next_field_name_value(current_p, "MD", &md, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + 16; // 16 is header length

  // fill opcode
  get_opcode(pkt->pkt_type, pkt->info_bit + pkt->num_info_bit);
  pkt->num_info_bit = pkt->num_info_bit + 8; // 8 is opcode

// get FeatureSet
  current_p = get_next_field_name_bit(current_p, "FEATURESET", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 1, 8, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

  int payload_len = (pkt->num_info_bit/8) - 7;
  printf("payload_len %d\n", payload_len);
  printf("num_info_bit %d\n", pkt->num_info_bit);

  fill_data_pdu_header(llid, nesn, sn, md, payload_len, pkt->info_bit+5*8);

// get CRC init
  char crc_init[7];
  current_p = get_next_field_name_hex(current_p, "CRCINIT", crc_init, 0, 3, &ret);
  if (ret == -1) { // failed
    return(-1);
  }
  crc24_and_scramble_to_gen_phy_bit(crc_init, pkt);
  printf("num_phy_bit %d\n", pkt->num_phy_bit);

  pkt->num_phy_sample = gen_sample_from_phy_bit(pkt->phy_bit, pkt->phy_sample, pkt->num_phy_bit);
  printf("num_phy_sample %d\n", pkt->num_phy_sample);

// get space value
  if (ret==1) { // if space value not present
    pkt->space = DEFAULT_SPACE_MS;
    printf("space %d\n", pkt->space);
    return(0);
  }

  int space;
  current_p = get_next_field_name_value(current_p, "SPACE", &space, &ret);
  if (ret == -1) { // failed
    return(-1);
  }

  if (space <= 0) {
    printf("Invalid space!\n");
    return(-1);
  }

  pkt->space = space;
  printf("space %d\n", pkt->space);

  return(0);
}
int calculate_sample_for_LL_FEATURE_RSP(char *pkt_str, PKT_INFO *pkt) {

// example
// Connection establishment (http://processors.wiki.ti.com/index.php/BLE_sniffer_guide)
// ./btle_tx 37-ADV_IND-TxAdd-0-RxAdd-0-AdvA-90D7EBB19299-AdvData-0201050702031802180418-Space-100  37-CONNECT_REQ-TxAdd-0-RxAdd-0-InitA-001830EA965F-AdvA-90D7EBB19299-AA-60850A1B-CRCInit-A77B22-WinSize-02-WinOffset-000F-Interval-0050-Latency-0000-Timeout-07D0-ChM-1FFFFFFFFF-Hop-9-SCA-5-Space-100 9-LL_FEATURE_RSP-AA-60850A1B-LLID-1-NESN-0-SN-0-MD-0-FeatureSet-0102030405060708-CRCInit-A77B22-Space-100

  return(calculate_sample_for_LL_FEATURE_REQ(pkt_str, pkt));
}
int calculate_sample_for_LL_PAUSE_ENC_REQ(char *pkt_str, PKT_INFO *pkt) {
// example
// Connection establishment (http://processors.wiki.ti.com/index.php/BLE_sniffer_guide)
// ./btle_tx 37-ADV_IND-TxAdd-0-RxAdd-0-AdvA-90D7EBB19299-AdvData-0201050702031802180418-Space-100  37-CONNECT_REQ-TxAdd-0-RxAdd-0-InitA-001830EA965F-AdvA-90D7EBB19299-AA-60850A1B-CRCInit-A77B22-WinSize-02-WinOffset-000F-Interval-0050-Latency-0000-Timeout-07D0-ChM-1FFFFFFFFF-Hop-9-SCA-5-Space-100 9-LL_PAUSE_ENC_REQ-AA-60850A1B-LLID-1-NESN-0-SN-0-MD-0-CRCInit-A77B22-Space-100
  return( calculate_sample_for_LL_START_ENC_REQ(pkt_str, pkt) );
}
int calculate_sample_for_LL_PAUSE_ENC_RSP(char *pkt_str, PKT_INFO *pkt) {
// example
// Connection establishment (http://processors.wiki.ti.com/index.php/BLE_sniffer_guide)
// ./btle_tx 37-ADV_IND-TxAdd-0-RxAdd-0-AdvA-90D7EBB19299-AdvData-0201050702031802180418-Space-100  37-CONNECT_REQ-TxAdd-0-RxAdd-0-InitA-001830EA965F-AdvA-90D7EBB19299-AA-60850A1B-CRCInit-A77B22-WinSize-02-WinOffset-000F-Interval-0050-Latency-0000-Timeout-07D0-ChM-1FFFFFFFFF-Hop-9-SCA-5-Space-100 9-LL_PAUSE_ENC_RSP-AA-60850A1B-LLID-1-NESN-0-SN-0-MD-0-CRCInit-A77B22-Space-100
  return( calculate_sample_for_LL_START_ENC_REQ(pkt_str, pkt) );

}
int calculate_sample_for_LL_VERSION_IND(char *pkt_str, PKT_INFO *pkt) {
// example
// Connection establishment (http://processors.wiki.ti.com/index.php/BLE_sniffer_guide)
// ./btle_tx 37-ADV_IND-TxAdd-0-RxAdd-0-AdvA-90D7EBB19299-AdvData-0201050702031802180418-Space-100  37-CONNECT_REQ-TxAdd-0-RxAdd-0-InitA-001830EA965F-AdvA-90D7EBB19299-AA-60850A1B-CRCInit-A77B22-WinSize-02-WinOffset-000F-Interval-0050-Latency-0000-Timeout-07D0-ChM-1FFFFFFFFF-Hop-9-SCA-5-Space-100 9-LL_VERSION_IND-AA-60850A1B-LLID-1-NESN-0-SN-0-MD-0-VersNr-01-CompId-0203-SubVersNr-0405-CRCInit-A77B22-Space-100
  char *current_p;
  int ret, num_bit_tmp;

  pkt->num_info_bit = 0;

// gen preamble (may be changed later according to access address
  pkt->num_info_bit = pkt->num_info_bit + convert_hex_to_bit("AA", pkt->info_bit);

// get access address
  current_p = pkt_str;
  current_p = get_next_field_name_bit(current_p, "AA", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 1, 4, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  if ( (*(pkt->info_bit+pkt->num_info_bit) ) == 1 ) {
    convert_hex_to_bit("55", pkt->info_bit);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

// get LLID NESN SN MD
  int llid, nesn, sn, md;
  current_p = get_next_field_name_value(current_p, "LLID", &llid, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }

  current_p = get_next_field_name_value(current_p, "NESN", &nesn, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }

  current_p = get_next_field_name_value(current_p, "SN", &sn, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }

  current_p = get_next_field_name_value(current_p, "MD", &md, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + 16; // 16 is header length

  // fill opcode
  get_opcode(pkt->pkt_type, pkt->info_bit + pkt->num_info_bit);
  pkt->num_info_bit = pkt->num_info_bit + 8; // 8 is opcode

// get VersNr CompId SubVersNr
  current_p = get_next_field_name_bit(current_p, "VERSNR", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 0, 1, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

  current_p = get_next_field_name_bit(current_p, "COMPID", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 1, 2, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

  current_p = get_next_field_name_bit(current_p, "SUBVERSNR", pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 1, 2, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

  int payload_len = (pkt->num_info_bit/8) - 7;
  printf("payload_len %d\n", payload_len);
  printf("num_info_bit %d\n", pkt->num_info_bit);

  fill_data_pdu_header(llid, nesn, sn, md, payload_len, pkt->info_bit+5*8);

// get CRC init
  char crc_init[7];
  current_p = get_next_field_name_hex(current_p, "CRCINIT", crc_init, 0, 3, &ret);
  if (ret == -1) { // failed
    return(-1);
  }
  crc24_and_scramble_to_gen_phy_bit(crc_init, pkt);
  printf("num_phy_bit %d\n", pkt->num_phy_bit);

  pkt->num_phy_sample = gen_sample_from_phy_bit(pkt->phy_bit, pkt->phy_sample, pkt->num_phy_bit);
  printf("num_phy_sample %d\n", pkt->num_phy_sample);

// get space value
  if (ret==1) { // if space value not present
    pkt->space = DEFAULT_SPACE_MS;
    printf("space %d\n", pkt->space);
    return(0);
  }

  int space;
  current_p = get_next_field_name_value(current_p, "SPACE", &space, &ret);
  if (ret == -1) { // failed
    return(-1);
  }

  if (space <= 0) {
    printf("Invalid space!\n");
    return(-1);
  }

  pkt->space = space;
  printf("space %d\n", pkt->space);

  return(0);
}
int calculate_sample_for_LL_REJECT_IND(char *pkt_str, PKT_INFO *pkt) {
// example
// Connection establishment (http://processors.wiki.ti.com/index.php/BLE_sniffer_guide)
// ./btle_tx 37-ADV_IND-TxAdd-0-RxAdd-0-AdvA-90D7EBB19299-AdvData-0201050702031802180418-Space-100  37-CONNECT_REQ-TxAdd-0-RxAdd-0-InitA-001830EA965F-AdvA-90D7EBB19299-AA-60850A1B-CRCInit-A77B22-WinSize-02-WinOffset-000F-Interval-0050-Latency-0000-Timeout-07D0-ChM-1FFFFFFFFF-Hop-9-SCA-5-Space-100 9-LL_REJECT_IND-AA-60850A1B-LLID-1-NESN-0-SN-0-MD-0-ErrorCode-00-CRCInit-A77B22-Space-100

  return( calculate_sample_for_LL_TERMINATE_IND(pkt_str, pkt) );
}

int calculate_sample_from_pkt_type(char *type_str, char *pkt_str, PKT_INFO *pkt) {
  if ( strcmp( toupper_str(type_str, tmp_str), "RAW" ) == 0 ) {
    pkt->pkt_type = RAW;
    printf("pkt_type RAW\n");
    if ( calculate_sample_for_RAW(pkt_str, pkt) == -1 ) {
      return(-1);
    }
  } else if ( strcmp( toupper_str(type_str, tmp_str), "DISCOVERY" ) == 0 ) {
    pkt->pkt_type = DISCOVERY;
    printf("pkt_type DISCOVERY\n");
    if ( calculate_sample_for_DISCOVERY(pkt_str, pkt) == -1 ) {
      return(-1);
    }
  }
    else if ( strcmp( toupper_str(type_str, tmp_str), "IBEACON" ) == 0 ) {
    pkt->pkt_type = IBEACON;
    printf("pkt_type IBEACON\n");
    if ( calculate_sample_for_IBEACON(pkt_str, pkt) == -1 ) {
      return(-1);
    }
  } else if ( strcmp( toupper_str(type_str, tmp_str), "ADV_IND" ) == 0 ) {
    pkt->pkt_type = ADV_IND;
    printf("pkt_type ADV_IND\n");
    if ( calculate_sample_for_ADV_IND(pkt_str, pkt) == -1 ) {
      return(-1);
    }
  } else if ( strcmp( toupper_str(type_str, tmp_str), "ADV_DIRECT_IND" ) == 0 ) {
    pkt->pkt_type = ADV_DIRECT_IND;
    printf("pkt_type ADV_DIRECT_IND\n");
    if ( calculate_sample_for_ADV_DIRECT_IND(pkt_str, pkt) == -1 ) {
      return(-1);
    }
  } else if ( strcmp( toupper_str(type_str, tmp_str), "ADV_NONCONN_IND" ) == 0 ) {
    pkt->pkt_type = ADV_NONCONN_IND;
    printf("pkt_type ADV_NONCONN_IND\n");
    if ( calculate_sample_for_ADV_NONCONN_IND(pkt_str, pkt) == -1 ) {
      return(-1);
    }
  } else if ( strcmp( toupper_str(type_str, tmp_str), "ADV_SCAN_IND" ) == 0 ) {
    pkt->pkt_type = ADV_SCAN_IND;
    printf("pkt_type ADV_SCAN_IND\n");
    if ( calculate_sample_for_ADV_SCAN_IND(pkt_str, pkt) == -1 ) {
      return(-1);
    }
  } else if ( strcmp( toupper_str(type_str, tmp_str), "SCAN_REQ" ) == 0 ) {
    pkt->pkt_type = SCAN_REQ;
    printf("pkt_type SCAN_REQ\n");
    if ( calculate_sample_for_SCAN_REQ(pkt_str, pkt) == -1 ) {
      return(-1);
    }
  } else if ( strcmp( toupper_str(type_str, tmp_str), "SCAN_RSP" ) == 0 ) {
    pkt->pkt_type = SCAN_RSP;
    printf("pkt_type SCAN_RSP\n");
    if ( calculate_sample_for_SCAN_RSP(pkt_str, pkt) == -1 ) {
      return(-1);
    }
  } else if ( strcmp( toupper_str(type_str, tmp_str), "CONNECT_REQ" ) == 0 ) {
    pkt->pkt_type = CONNECT_REQ;
    printf("pkt_type CONNECT_REQ\n");
    if ( calculate_sample_for_CONNECT_REQ(pkt_str, pkt) == -1 ) {
      return(-1);
    }
  } else if ( strcmp( toupper_str(type_str, tmp_str), "LL_DATA" ) == 0 ) {
    pkt->pkt_type = LL_DATA;
    printf("pkt_type LL_DATA\n");
    if ( calculate_sample_for_LL_DATA(pkt_str, pkt) == -1 ) {
      return(-1);
    }
  } else if ( strcmp( toupper_str(type_str, tmp_str), "LL_CONNECTION_UPDATE_REQ" ) == 0 ) {
    pkt->pkt_type = LL_CONNECTION_UPDATE_REQ;
    printf("pkt_type LL_CONNECTION_UPDATE_REQ\n");
    if ( calculate_sample_for_LL_CONNECTION_UPDATE_REQ(pkt_str, pkt) == -1 ) {
      return(-1);
    }
  } else if ( strcmp( toupper_str(type_str, tmp_str), "LL_CHANNEL_MAP_REQ" ) == 0 ) {
    pkt->pkt_type = LL_CHANNEL_MAP_REQ;
    printf("pkt_type LL_CHANNEL_MAP_REQ\n");
    if ( calculate_sample_for_LL_CHANNEL_MAP_REQ(pkt_str, pkt) == -1 ) {
      return(-1);
    }
  } else if ( strcmp( toupper_str(type_str, tmp_str), "LL_TERMINATE_IND" ) == 0 ) {
    pkt->pkt_type = LL_TERMINATE_IND;
    printf("pkt_type LL_TERMINATE_IND\n");
    if ( calculate_sample_for_LL_TERMINATE_IND(pkt_str, pkt) == -1 ) {
      return(-1);
    }
  } else if ( strcmp( toupper_str(type_str, tmp_str), "LL_ENC_REQ" ) == 0 ) {
    pkt->pkt_type = LL_ENC_REQ;
    printf("pkt_type LL_ENC_REQ\n");
    if ( calculate_sample_for_LL_ENC_REQ(pkt_str, pkt) == -1 ) {
      return(-1);
    }
  } else if ( strcmp( toupper_str(type_str, tmp_str), "LL_ENC_RSP" ) == 0 ) {
    pkt->pkt_type = LL_ENC_RSP;
    printf("pkt_type LL_ENC_RSP\n");
    if ( calculate_sample_for_LL_ENC_RSP(pkt_str, pkt) == -1 ) {
      return(-1);
    }
  } else if ( strcmp( toupper_str(type_str, tmp_str), "LL_START_ENC_REQ" ) == 0 ) {
    pkt->pkt_type = LL_START_ENC_REQ;
    printf("pkt_type LL_START_ENC_REQ\n");
    if ( calculate_sample_for_LL_START_ENC_REQ(pkt_str, pkt) == -1 ) {
      return(-1);
    }
  } else if ( strcmp( toupper_str(type_str, tmp_str), "LL_START_ENC_RSP" ) == 0 ) {
    pkt->pkt_type = LL_START_ENC_RSP;
    printf("pkt_type LL_START_ENC_RSP\n");
    if ( calculate_sample_for_LL_START_ENC_RSP(pkt_str, pkt) == -1 ) {
      return(-1);
    }
  } else if ( strcmp( toupper_str(type_str, tmp_str), "LL_UNKNOWN_RSP" ) == 0 ) {
    pkt->pkt_type = LL_UNKNOWN_RSP;
    printf("pkt_type LL_UNKNOWN_RSP\n");
    if ( calculate_sample_for_LL_UNKNOWN_RSP(pkt_str, pkt) == -1 ) {
      return(-1);
    }
  } else if ( strcmp( toupper_str(type_str, tmp_str), "LL_FEATURE_REQ" ) == 0 ) {
    pkt->pkt_type = LL_FEATURE_REQ;
    printf("pkt_type LL_FEATURE_REQ\n");
    if ( calculate_sample_for_LL_FEATURE_REQ(pkt_str, pkt) == -1 ) {
      return(-1);
    }
  } else if ( strcmp( toupper_str(type_str, tmp_str), "LL_FEATURE_RSP" ) == 0 ) {
    pkt->pkt_type = LL_FEATURE_RSP;
    printf("pkt_type LL_FEATURE_RSP\n");
    if ( calculate_sample_for_LL_FEATURE_RSP(pkt_str, pkt) == -1 ) {
      return(-1);
    }
  } else if ( strcmp( toupper_str(type_str, tmp_str), "LL_PAUSE_ENC_REQ" ) == 0 ) {
    pkt->pkt_type = LL_PAUSE_ENC_REQ;
    printf("pkt_type LL_PAUSE_ENC_REQ\n");
    if ( calculate_sample_for_LL_PAUSE_ENC_REQ(pkt_str, pkt) == -1 ) {
      return(-1);
    }
  } else if ( strcmp( toupper_str(type_str, tmp_str), "LL_PAUSE_ENC_RSP" ) == 0 ) {
    pkt->pkt_type = LL_PAUSE_ENC_RSP;
    printf("pkt_type LL_PAUSE_ENC_RSP\n");
    if ( calculate_sample_for_LL_PAUSE_ENC_RSP(pkt_str, pkt) == -1 ) {
      return(-1);
    }
  } else if ( strcmp( toupper_str(type_str, tmp_str), "LL_VERSION_IND" ) == 0 ) {
    pkt->pkt_type = LL_VERSION_IND;
    printf("pkt_type LL_VERSION_IND\n");
    if ( calculate_sample_for_LL_VERSION_IND(pkt_str, pkt) == -1 ) {
      return(-1);
    }
  } else if ( strcmp( toupper_str(type_str, tmp_str), "LL_REJECT_IND" ) == 0 ) {
    pkt->pkt_type = LL_REJECT_IND;
    printf("pkt_type LL_REJECT_IND\n");
    if ( calculate_sample_for_LL_REJECT_IND(pkt_str, pkt) == -1 ) {
      return(-1);
    }
  } else {
    pkt->pkt_type = INVALID_TYPE;
    printf("pkt_type INVALID_TYPE\n");
    return(-1);
  }

  return(0);
}

int calculate_pkt_info( PKT_INFO *pkt ){
  char *cmd_str = pkt->cmd_str;
  char *next_p;
  int ret;

  // get channel number
  int channel_number;
  next_p = get_next_field_value(cmd_str, &channel_number, &ret);
  if (ret != 0) {
    printf("Getting channel number failed! It should be 0~39.\n");
    return(-1);
  }

  if (channel_number < 0 || channel_number > 39){
    printf("Invalid channel number is found. It should be 0~39.\n");
    return(-1);
  }

  if (channel_number == 0) {
    if (tmp_str[0] != '0' ||  tmp_str[1] != 0  ) {
      printf("Invalid channel number is found. It should be 0~39.\n");
      return(-1);
    }
  }

  pkt->channel_number = channel_number;
  printf("channel_number %d\n", channel_number);

  // get pkt_type
  char *current_p = next_p;
  next_p = get_next_field(current_p, tmp_str, "-", MAX_NUM_CHAR_CMD);
  if ( next_p == NULL  || next_p==current_p ) {
    printf("Getting packet type failed!\n");
    return(-1);
  }

  if ( calculate_sample_from_pkt_type(tmp_str, next_p, pkt) == -1 ){
    if ( pkt->pkt_type == INVALID_TYPE ) {
      printf("Invalid packet type!\n");
    } else {
      printf("Invalid packet content for specific packet type!\n");
    }
    return(-1);
  }

  return(0);
}

void save_phy_sample(char *IQ_sample, int num_IQ_sample, char *filename)
{
  int i;

  FILE *fp = fopen(filename, "w");
  if (fp == NULL) {
    printf("save_phy_sample: fopen failed!\n");
    return;
  }

  for(i=0; i<num_IQ_sample; i++) {
    if (i%24 == 0) {
      fprintf(fp, "\n");
    }
    fprintf(fp, "%d, ", IQ_sample[i]);
  }
  fprintf(fp, "\n");

  fclose(fp);
}

void save_phy_sample_for_matlab(char *IQ_sample, int num_IQ_sample, char *filename)
{
  int i;

  FILE *fp = fopen(filename, "w");
  if (fp == NULL) {
    printf("save_phy_sample_for_matlab: fopen failed!\n");
    return;
  }

  for(i=0; i<num_IQ_sample; i++) {
    if (i%24 == 0) {
      fprintf(fp, "...\n");
    }
    fprintf(fp, "%d ", IQ_sample[i]);
  }
  fprintf(fp, "\n");

  fclose(fp);
}

int parse_input(int num_input, char** argv, int *num_repeat_return){
  int repeat_specific = 0;

  int num_repeat = get_num_repeat(argv[num_input-1], &repeat_specific);
  if (num_repeat == -2) {
    return(-2);
  }

  int num_packet = 0;
  if (repeat_specific == 1){
    num_packet = num_input - 2;
  } else {
    num_packet = num_input - 1;
  }

  printf("num_repeat %d\n", num_repeat);
  printf("num_packet %d\n", num_packet);

  (*num_repeat_return) = num_repeat;

  int i;
  for (i=0; i<num_packet; i++) {

    if (strlen(argv[1+i]) > MAX_NUM_CHAR_CMD-1) {
      printf("Too long packet descriptor of packet %d! Maximum allowed are %d characters\n", i, MAX_NUM_CHAR_CMD-1);
      return(-2);
    }
    strcpy(packets[i].cmd_str, argv[1+i]);
    printf("\npacket %d\n", i);
    if (calculate_pkt_info( &(packets[i]) ) == -1){
      printf("failed!\n");
      return(-2);
    }
    printf("INFO bit:"); disp_bit_in_hex(packets[i].info_bit, packets[i].num_info_bit);
    printf(" PHY bit:"); disp_bit_in_hex(packets[i].phy_bit, packets[i].num_phy_bit);
    printf("PHY SMPL: PHY_bit_for_matlab.txt IQ_sample_for_matlab.txt IQ_sample.txt IQ_sample_byte.txt\n");
    save_phy_sample((char*)(packets[i].info_byte), packets[i].num_info_byte, "info_byte.txt");
    save_phy_sample((char*)(packets[i].phy_byte), packets[i].num_phy_byte, "phy_byte.txt");
    save_phy_sample(packets[i].phy_sample, 2*packets[i].num_phy_sample, "phy_sample.txt");
    save_phy_sample_for_matlab(packets[i].phy_sample, 2*packets[i].num_phy_sample, "IQ_sample_for_matlab.txt");
    save_phy_sample_for_matlab(packets[i].phy_bit, packets[i].num_phy_bit, "PHY_bit_for_matlab.txt");
  }

  return(num_packet);
}

int read_items_from_file(int *num_items, char **items_buf, int num_row, char *filename){

  FILE *fp = fopen(filename, "r");

  char file_line[MAX_NUM_CHAR_CMD*2];

  if (fp == NULL) {
    printf("fopen failed!\n");
    return(-1);
  }

  int num_lines = 0;
  char *p = (char *)12345;

  while( 1 ) {
    memset(file_line, 0, MAX_NUM_CHAR_CMD*2);
    p = fgets(file_line,  (MAX_NUM_CHAR_CMD*2), fp );

    if ( file_line[(MAX_NUM_CHAR_CMD*2)-1] != 0 ) {
      printf("A line is too long!\n");
      fclose(fp);
      return(-1);
    }

    if ( p==NULL ) {
      break;
    }

    if (file_line[0] != '#') {
      if ( (file_line[0] >= 48 && file_line[0] <= 57) || file_line[0] ==114 || file_line[0] == 82 ) { // valid line
        if (strlen(file_line) > (MAX_NUM_CHAR_CMD-1) ) {
          printf("A line is too long!\n");
          fclose(fp);
          return(-1);
        } else {

          if (num_lines == (num_row-1) ) {
            printf("Too many lines!\n");
            fclose(fp);
            return(-1);
          }

          strcpy(items_buf[num_lines + 1], file_line);
          num_lines++;
        }
      }
    }

    if (feof(fp)) {
      break;
    }
  }

  fclose(fp);

  (*num_items) = num_lines + 1;

  return(0);
}

char ** malloc_2d(int num_row, int num_col) {
  int i, j;

  char **items = (char **)malloc(num_row * sizeof(char *));

  if (items == NULL) {
    return(NULL);
  }

  for (i=0; i<num_row; i++) {
    items[i] = (char *)malloc( num_col * sizeof(char));

    if (items[i] == NULL) {
      for (j=i-1; j>=0; j--) {
        free(items[i]);
      }
      return(NULL);
    }
  }

  return(items);
}

void release_2d(char **items, int num_row) {
  int i;
  for (i=0; i<num_row; i++){
    free((char *) items[i]);
  }
  free ((char *) items);
}

int main(int argc, char** argv) {
  int num_packet, i, j, num_items;
  int num_repeat = 0; // -1: inf; 0: 1; other: specific

  if (argc < 2) {
    usage();
    return(0);
  } else if ( (argc-1-1) > MAX_NUM_PACKET ){
    printf("Too many packets input! Maximum allowed is %d\n", MAX_NUM_PACKET);
  } else if (argc == 2 && ( strstr(argv[1], ".txt")!=NULL || strstr(argv[1], ".TXT")!=NULL) ) {  // from file
    char **items = malloc_2d(MAX_NUM_PACKET+2, MAX_NUM_CHAR_CMD);
    if (items == NULL) {
      printf("malloc failed!\n");
      return(-1);
    }

    if ( read_items_from_file(&num_items, items, MAX_NUM_PACKET+2, argv[1]) == -1 ) {
      release_2d(items, MAX_NUM_PACKET+2);
      return(-1);
    }
    num_packet = parse_input(num_items, items, &num_repeat);

    release_2d(items, MAX_NUM_PACKET+2);

    if ( num_repeat == -2 ){
      return(-1);
    }
  } else { // from command line
    num_packet = parse_input(argc, argv, &num_repeat);
    if ( num_repeat == -2 ){
      return(-1);
    }
  }
  printf("\n");

  if ( init_board() == -1 )
      return(-1);

#if 0
//-----------------------------------test tx buf---------------------------------
  set_freq_by_channel_number(37);

  // open the board-----------------------------------------
  if (open_board() == -1) {
    printf("main: open_board() failed\n");
    goto main_out;
  }

  do_exit = false;

  int tx_buffer_length_old, tx_valid_length_old, tx_count_old;
  int result = hackrf_start_tx(device, tx_callback, NULL);
  if( result != HACKRF_SUCCESS ) {
    printf("main: hackrf_start_tx() failed: %s (%d)\n", hackrf_error_name(result), result);
    goto main_out;
  }

  tx_buffer_length_old = tx_buffer_length;
  tx_valid_length_old = tx_valid_length;
  tx_count_old = tx_count;
  while( (hackrf_is_streaming(device) == HACKRF_TRUE) &&
      (do_exit == false) )
  {
    if ( (tx_count-tx_count_old)>32 || (tx_buffer_length-tx_buffer_length_old)>512 || (tx_buffer_length-tx_buffer_length_old)<0 || (tx_valid_length-tx_valid_length_old)>512 || (tx_valid_length-tx_valid_length_old)<0 ) {
      printf("%d %d %d(old %d %d %d)\n", tx_buffer_length, tx_valid_length, tx_count, tx_buffer_length_old, tx_valid_length_old, tx_count_old);
      tx_buffer_length_old = tx_buffer_length;
      tx_valid_length_old = tx_valid_length;
      tx_count_old = tx_count;
    }
  }

  if (do_exit)
  {
    printf("\nmain: Exiting...\n");
  }

  result = hackrf_stop_tx(device);
  if( result != HACKRF_SUCCESS ) {
    printf("main: hackrf_stop_tx() failed: %s (%d)\n", hackrf_error_name(result), result);
  }
//----------------------------test tx buf-------------------------------
#endif

#if 1
  #ifndef USE_BLADERF
  //flush hackrf onboard buf
  #if 0
  for(i=0; i<(HACKRF_ONBOARD_BUF_SIZE/HACKRF_USB_BUF_SIZE)+16; i++) {
    if ( tx_one_buf(tx_zeros, HACKRF_USB_BUF_SIZE-NUM_PRE_SEND_DATA, packets[0].channel_number) == -1 ){
        close_board();
        goto main_out;
    }
  }
  #endif
  
  #if 0
  if ( tx_one_buf(tx_zeros, HACKRF_USB_BUF_SIZE-NUM_PRE_SEND_DATA, packets[0].channel_number) == -1 ){
      close_board();
      goto main_out;
    }
  if ( tx_one_buf(tx_zeros, HACKRF_USB_BUF_SIZE-NUM_PRE_SEND_DATA, packets[0].channel_number) == -1 ){
      close_board();
      goto main_out;
    }
  #endif
  
  #endif
  
  struct timeval time_tmp, time_current_pkt, time_pre_pkt;
  gettimeofday(&time_current_pkt, NULL);
  for (j=0; j<num_repeat; j++ ) {
    for (i=0; i<num_packet; i++) {
      time_pre_pkt = time_current_pkt;
      gettimeofday(&time_current_pkt, NULL);

      if ( tx_one_buf(packets[i].phy_sample, 2*packets[i].num_phy_sample, packets[i].channel_number) == -1 ){
        close_board();
        goto main_out;
      }

      #if 0
      if ( tx_one_buf(tx_zeros, HACKRF_USB_BUF_SIZE-NUM_PRE_SEND_DATA, packets[0].channel_number) == -1 ){
        close_board();
        goto main_out;
      }
      #endif
      
      printf("r%d p%d at %dus\n", j, i,  TimevalDiff(&time_current_pkt, &time_pre_pkt) );

      gettimeofday(&time_tmp, NULL);
      while(TimevalDiff(&time_tmp, &time_current_pkt)<( packets[i].space*1000 ) ) {
        gettimeofday(&time_tmp, NULL);
      }
    }
  }
  printf("\n");
#endif 

main_out:
  exit_board();
	printf("exit\n");

	return(0);
}
