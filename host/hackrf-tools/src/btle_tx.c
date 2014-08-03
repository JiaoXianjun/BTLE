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

#define FREQ_ONE_MHZ (1000000ull)
#define DEFAULT_BASEBAND_FILTER_BANDWIDTH (8000000) /* 8MHz default */

#if defined _WIN32
	#define sleep(a) Sleep( (a*1000) )
#endif

static inline float
TimevalDiff(const struct timeval *a, const struct timeval *b)
{
   return (a->tv_sec - b->tv_sec) + 1e-6f * (a->tv_usec - b->tv_usec);
}

#define AMPLITUDE (110.0)
#define MOD_IDX (0.6)
#define SAMPLE_PER_SYMBOL (8)
#define LEN_GAUSS_FILTER (3)
#define MAX_NUM_INFO_BYTE (43)
#define MAX_NUM_PHY_BYTE (47)
#define MAX_NUM_PHY_SAMPLE ((MAX_NUM_PHY_BYTE*8*SAMPLE_PER_SYMBOL)+(LEN_GAUSS_FILTER*SAMPLE_PER_SYMBOL))

float gauss_coef[LEN_GAUSS_FILTER*SAMPLE_PER_SYMBOL] = {8.05068379156060e-05,	0.000480405201766898,	0.00232683283115742,	0.00917699278400763,	0.0295990801678164,	0.0785284246648025,	0.172747370208161,	0.318566802305277,	0.499919493162062,	0.680941868522779,	0.824924599006030,	0.912294476105987,	0.940801824540822,	0.912294476105987,	0.824924599006030,	0.680941868522779,	0.499919493162062,	0.318566802305277,	0.172747370208161,	0.0785284246648025,	0.0295990801678164,	0.00917699278400763,	0.00232683283115742,	0.000480405201766898};

uint64_t freq_hz = 2480000000ull;  //channel 39
//uint64_t freq_hz = 2402000000ull;  //channel 37
//uint64_t freq_hz = 2426000000ull;  //channel 38
const uint32_t sample_rate_hz = 8000000;
uint32_t baseband_filter_bw_hz;

volatile bool do_exit = false;

volatile int stop_tx = 1;
volatile char tx_buf[MAX_NUM_PHY_SAMPLE*2];
volatile int tx_len;
#define NUM_PRE_SEND_DATA (4096)
int tx_callback(hackrf_transfer* transfer) {
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

  printf("open_board: call hackrf_set_freq(%.03f MHz)\n", ((double)freq_hz/(double)FREQ_ONE_MHZ) );
  result = hackrf_set_freq(device, freq_hz);
  if( result != HACKRF_SUCCESS ) {
    printf("open_board: hackrf_set_freq() failed: %s (%d)\n", hackrf_error_name(result), result);
    usage();
    return(-1);
  }

  printf("open_board: call hackrf_set_amp_enable(%u)\n", 0);
  result = hackrf_set_amp_enable(device, (uint8_t)0);
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

inline int set_freq_by_channel_number(int channel_number) {
  int result;
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
  result = hackrf_set_freq(device, freq_hz);
  if( result != HACKRF_SUCCESS ) {
    printf("tx_one_buf: hackrf_set_freq() failed: %s (%d)\n", hackrf_error_name(result), result);
    return(-1);
  }
  return(0);
}

inline int tx_one_buf(char *buf, int length) {
  int result;

  memcpy((char *)(tx_buf), buf, length);
  tx_len = length;

//  printf("stop_tx %d\n", stop_tx);
  stop_tx = false;

//  printf("%d\n", length);
  result = hackrf_start_tx(device, tx_callback, NULL);
  if( result != HACKRF_SUCCESS ) {
    printf("tx_one_buf: hackrf_start_tx() failed: %s (%d)\n", hackrf_error_name(result), result);
    return(-1);
  }

  while( (hackrf_is_streaming(device) == HACKRF_TRUE) &&
      (do_exit == false) )
  {
    if (stop_tx) {
//      printf("stop_tx %d\n", stop_tx);
//      printf("do_exit %d\n", do_exit);
      break;
    }
  }

  if (do_exit)
  {
    printf("\ntx_one_buf-1: Abnormal, exiting...\n");
    return(-1);
  }

  result = hackrf_stop_tx(device);
  if( result != HACKRF_SUCCESS ) {
    printf("tx_one_buf: hackrf_stop_tx() failed: %s (%d)\n", hackrf_error_name(result), result);
    return(-1);
  }

  do_exit = false;

  return(0);
}

typedef enum
{
    INVALID_TYPE,
    RAW,
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
//    char info_bit[MAX_NUM_INFO_BYTE*8]; // without preamble and CRC
    char info_bit[MAX_NUM_PHY_BYTE*8]; // without CRC and whitening
    int num_phy_bit;
    char phy_bit[MAX_NUM_PHY_BYTE*8]; // all bits which will be fed to GFSK modulator
    int num_phy_sample;
    char phy_sample[2*MAX_NUM_PHY_SAMPLE]; // GFSK output to D/A (hackrf board)
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

#define MAX_NUM_PACKET (128)
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

int convert_hex_to_bit(char *hex, char *bit){
  int num_hex = strlen(hex);

  if (num_hex%2 != 0) {
    return(-1);
  }

  int num_bit = num_hex*4;

  int i, j;
  for (i=0; i<num_hex; i=i+2) {
    j = i*4;
    octet_hex_to_bit(hex+i, bit+j);
  }

  return(num_bit);
}

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

  sample[0] = (char)AMPLITUDE;
  sample[1] = 0;
  for (i=1; i<num_sample; i++) {
    tmp = tmp + (M_PI*MOD_IDX)*tmp_phy_bit_over_sampling1[i-1]/((float)SAMPLE_PER_SYMBOL);
    sample[i*2 + 0] = (char)round( cos(tmp)*(float)AMPLITUDE );
    sample[i*2 + 1] = (char)round( sin(tmp)*(float)AMPLITUDE );
  }

  return(num_sample);
}

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
    printf("%s field is expected!\n", name);
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

char* get_next_field_bit(char *current_p, char *bit_return, int *num_bit_return, int stream_flip, int octet_limit, int *return_flag) {
// return_flag: -1 failed; 0 success; 1 success and this is the last field
// stream_flip: 0: normal sequence; 1: flip octets order in sequence
  int i;
  char *next_p = get_next_field(current_p, tmp_str, "-", MAX_NUM_CHAR_CMD);
  if (next_p == NULL) {
    (*return_flag) = -1;
    return(next_p);
  }
  if ( strlen(tmp_str)>(octet_limit*2) ) {
    printf("Too many octets! Maximum allowed is %d\n", octet_limit);
    (*return_flag) = -1;
    return(next_p);
  }

  int num_bit_tmp;
  if (stream_flip == 1) {
    int num_hex = strlen(tmp_str);
    if (num_hex%2 != 0) {
      (*return_flag) = -1;
      return(next_p);
    }
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

#define DEFAULT_SPACE_MS (200)
int calculate_sample_for_RAW(char *pkt_str, PKT_INFO *pkt) {
// example
// ./btle_tx 39-RAW-AAD6BE898E5F134B5D86F2999CC3D7DF5EDF15DEE39AA2E5D0728EB68B0E449B07C547B80EAA8DD257A0E5EACB0B-SPACE-1000
  char *current_p, *next_p;
  int ret;

  pkt->num_info_bit = 0;
  printf("num_info_bit %d\n", pkt->num_info_bit);

  current_p = pkt_str;
  next_p = get_next_field_bit(current_p, pkt->phy_bit, &(pkt->num_phy_bit), 0, MAX_NUM_PHY_BYTE, &ret);
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

  current_p = next_p;
  next_p = get_next_field_name(current_p, "SPACE", &ret);
  if (ret == -1) { // failed
    return(-1);
  }
  if (ret == 1) { // last field
    pkt->space = DEFAULT_SPACE_MS;
    printf("space %d\n", pkt->space);
    return(0);
  }

  current_p = next_p;
  int space;
  get_next_field_value(current_p, &space, &ret);
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


void fill_adv_pdu_header(PKT_TYPE pkt_type, int txadd, int rxadd, int payload_len, char *bit_out) {
  if (pkt_type == ADV_IND || pkt_type == IBEACON) {
    bit_out[3] = 0; bit_out[2] = 0; bit_out[1] = 0; bit_out[0] = 0;
  } else if (pkt_type == ADV_DIRECT_IND) {
    bit_out[3] = 0; bit_out[2] = 0; bit_out[1] = 0; bit_out[0] = 1;
  } else if (pkt_type == ADV_NONCONN_IND) {
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

int calculate_sample_for_ADV_IND(char *pkt_str, PKT_INFO *pkt) {
// example
// ./btle_tx 39-ADV_IND-TXADD-1-RXADD-0-ADVA-010203040506-ADVDATA-00112233445566778899AABBCCDDEEFF
  char *current_p, *next_p;
  int ret, num_bit_tmp;

  pkt->num_info_bit = 0;
// gen preamble and access address
  pkt->num_info_bit = pkt->num_info_bit + convert_hex_to_bit("AA", pkt->info_bit);
  pkt->num_info_bit = pkt->num_info_bit + convert_hex_to_bit("D6BE898E", pkt->info_bit + pkt->num_info_bit);

// get txadd and rxadd
  current_p = pkt_str;
  next_p = get_next_field_name(current_p, "TXADD", &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  current_p = next_p;
  int txadd;
  next_p = get_next_field_value(current_p, &txadd, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }

  current_p = next_p;
  next_p = get_next_field_name(current_p, "RXADD", &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  current_p = next_p;
  int rxadd;
  next_p = get_next_field_value(current_p, &rxadd, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + 16; // 16 is header length

// get AdvA and AdvData
  current_p = next_p;
  next_p = get_next_field_name(current_p, "ADVA", &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  current_p = next_p;
  next_p = get_next_field_bit(current_p, pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 1, 6, &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

  current_p = next_p;
  next_p = get_next_field_name(current_p, "ADVDATA", &ret);
  if (ret != 0) { // failed or the last
    return(-1);
  }
  current_p = next_p;
  next_p = get_next_field_bit(current_p, pkt->info_bit+pkt->num_info_bit, &num_bit_tmp, 0, 31, &ret);
  if (ret == -1) { // failed
    return(-1);
  }
  pkt->num_info_bit = pkt->num_info_bit + num_bit_tmp;

  int payload_len = (pkt->num_info_bit/8) - 7;
  if (payload_len < 6 || payload_len > 37) {
    printf("payload length should be 6~37. Actual %d\n", payload_len);
  }

  printf("payload_len %d\n", payload_len);
  printf("num_info_bit %d\n", pkt->num_info_bit);
  fill_adv_pdu_header(pkt->pkt_type, txadd, rxadd, payload_len, pkt->info_bit+5*8);

  crc24(pkt->info_bit+5*8, pkt->num_info_bit-5*8, "555555", pkt->info_bit+pkt->num_info_bit);
  scramble(pkt->info_bit+5*8, pkt->num_info_bit-5*8+24, pkt->channel_number, pkt->phy_bit+5*8);
  memcpy(pkt->phy_bit, pkt->info_bit, 5*8);
  pkt->num_phy_bit = pkt->num_info_bit + 24;
  printf("num_phy_bit %d\n", pkt->num_phy_bit);

  pkt->num_phy_sample = gen_sample_from_phy_bit(pkt->phy_bit, pkt->phy_sample, pkt->num_phy_bit);
  printf("num_phy_sample %d\n", pkt->num_phy_sample);

// get space value
  if (ret==1) {
    pkt->space = DEFAULT_SPACE_MS;
    printf("space %d\n", pkt->space);
    return(0);
  }

  current_p = next_p;
  next_p = get_next_field_name(current_p, "SPACE", &ret);
  if (ret == -1) { // failed
    return(-1);
  }
  if (ret == 1) { // last field
    pkt->space = DEFAULT_SPACE_MS;
    printf("space %d\n", pkt->space);
    return(0);
  }

  current_p = next_p;
  int space;
  get_next_field_value(current_p, &space, &ret);
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
int calculate_sample_for_ADV_DIRECT_IND(char *pkt_str, PKT_INFO *pkt) {
  return(0);
}
int calculate_sample_for_ADV_NONCONN_IND(char *pkt_str, PKT_INFO *pkt) {
  return(0);
}
int calculate_sample_for_ADV_SCAN_IND(char *pkt_str, PKT_INFO *pkt) {
  return(0);
}
int calculate_sample_for_SCAN_REQ(char *pkt_str, PKT_INFO *pkt) {
  return(0);
}
int calculate_sample_for_SCAN_RSP(char *pkt_str, PKT_INFO *pkt) {
  return(0);
}
int calculate_sample_for_CONNECT_REQ(char *pkt_str, PKT_INFO *pkt) {
  return(0);
}
int calculate_sample_for_LL_DATA(char *pkt_str, PKT_INFO *pkt) {
  return(0);
}
int calculate_sample_for_LL_CONNECTION_UPDATE_REQ(char *pkt_str, PKT_INFO *pkt) {
  return(0);
}
int calculate_sample_for_LL_CHANNEL_MAP_REQ(char *pkt_str, PKT_INFO *pkt) {
  return(0);
}
int calculate_sample_for_LL_TERMINATE_IND(char *pkt_str, PKT_INFO *pkt) {
  return(0);
}
int calculate_sample_for_LL_ENC_REQ(char *pkt_str, PKT_INFO *pkt) {
  return(0);
}
int calculate_sample_for_LL_ENC_RSP(char *pkt_str, PKT_INFO *pkt) {
  return(0);
}
int calculate_sample_for_LL_START_ENC_REQ(char *pkt_str, PKT_INFO *pkt) {
  return(0);
}
int calculate_sample_for_LL_START_ENC_RSP(char *pkt_str, PKT_INFO *pkt) {
  return(0);
}
int calculate_sample_for_LL_UNKNOWN_RSP(char *pkt_str, PKT_INFO *pkt) {
  return(0);
}
int calculate_sample_for_LL_FEATURE_REQ(char *pkt_str, PKT_INFO *pkt) {
  return(0);
}
int calculate_sample_for_LL_FEATURE_RSP(char *pkt_str, PKT_INFO *pkt) {
  return(0);
}
int calculate_sample_for_LL_PAUSE_ENC_REQ(char *pkt_str, PKT_INFO *pkt) {
  return(0);
}
int calculate_sample_for_LL_PAUSE_ENC_RSP(char *pkt_str, PKT_INFO *pkt) {
  return(0);
}
int calculate_sample_for_LL_VERSION_IND(char *pkt_str, PKT_INFO *pkt) {
  return(0);
}
int calculate_sample_for_LL_REJECT_IND(char *pkt_str, PKT_INFO *pkt) {
  return(0);
}

int calculate_sample_from_pkt_type(char *type_str, char *pkt_str, PKT_INFO *pkt) {
  if ( strcmp( toupper_str(type_str, tmp_str), "RAW" ) == 0 ) {
    pkt->pkt_type = RAW;
    printf("pkt_type RAW\n");
    if ( calculate_sample_for_RAW(pkt_str, pkt) == -1 ) {
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
      return(-2);
    }

//    // display for debug
//    int j;
//    for (j=0; j<packets[i].num_phy_sample; j++) {
//      printf("%d ", packets[i].phy_sample[j]);
//    }
  }

  return(num_packet);
}

int main(int argc, char** argv) {
  int num_packet, i, j;
  int num_repeat = 0; // -1: inf; 0: 1; other: specific

  if ( open_board() == -1 )
      return(-1);

  if (argc < 2) {
    usage();
    return(0);
  } else if ( (argc-1-1) > MAX_NUM_PACKET ){
    printf("Too many packets input! Maximum allowed is %d\n", MAX_NUM_PACKET);
  } else {
    num_packet = parse_input(argc, argv, &num_repeat);
    if ( num_repeat == -2 ){
      return(-1);
    }
  }
  printf("\n");

  struct timeval time_now, time_old;

  // don't know why the first tx won't work. do the 1st as pre warming.
  if (set_freq_by_channel_number(packets[0].channel_number) == -1) {
    close_board();
    return(-1);
  }
  if ( tx_one_buf(packets[0].phy_sample, 2*packets[0].num_phy_sample) == -1 ){
    close_board();
    return(-1);
  }
  gettimeofday(&time_old, NULL);
  gettimeofday(&time_now, NULL);
  for (j=0; j<num_repeat; j++ ) {
    for (i=0; i<num_packet; i++) {
      if ( tx_one_buf(packets[i].phy_sample, 2*packets[i].num_phy_sample) == -1 ){
        close_board();
        return(-1);
      }
      if (i<(num_packet-1) ) {
        if (set_freq_by_channel_number(packets[i+1].channel_number) == -1) {
          close_board();
          return(-1);
        }
      }

      printf("%d %d\n", j, i);

      if (do_exit)
        break;

      while(TimevalDiff(&time_now, &time_old)<( (float)packets[i].space/(float)1000 ) ) {
        gettimeofday(&time_now, NULL);
      }
      gettimeofday(&time_old, NULL);
    }
  }
  printf("\n");

  close_board();
	printf("exit\n");

//////// // ---------already test-------------------------
//#define FILE_LEN (5936)
//  if ( open_board() == -1 )
//    return(-1);
//
//  char buf[FILE_LEN];
//
//  FILE *fp = fopen("ibeacon_single_packet.bin", "rb");
//  fread(buf, sizeof(char), FILE_LEN, fp);
//  fclose(fp);
//
//  struct timeval time_now, time_start;
//
//  // don't know why the first tx won't work. do the 1st as pre warming.
//  if ( tx_one_buf(buf, FILE_LEN) == -1 ){
//    close_board();
//    return(-1);
//  }
//
//  gettimeofday(&time_start, NULL);
//  for (i=0; i<3; i++) {
//    if ( tx_one_buf(buf, FILE_LEN) == -1 ){
//      close_board();
//      return(-1);
//    }
//    printf("%d\n", i);
//
//    while(TimevalDiff(&time_now, &time_start)<0.1) {
//      gettimeofday(&time_now, NULL);
//    }
//    gettimeofday(&time_start, NULL);
//
//    if (do_exit)
//      break;
//  }
//
//  close_board();
//	printf("exit\n");
//////// // ---------already test-------------------------

	return(0);
}
