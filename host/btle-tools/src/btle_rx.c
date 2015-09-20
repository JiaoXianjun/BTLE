// BTLE signal scanner by Xianjun Jiao (putaoshu@gmail.com)

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
#include <getopt.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>

//----------------------------------some sys stuff----------------------------------
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

static inline float
TimevalDiff(const struct timeval *a, const struct timeval *b)
{
   return (a->tv_sec - b->tv_sec) + 1e-6f * (a->tv_usec - b->tv_usec);
}

volatile bool do_exit = false;
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

//----------------------------------some sys stuff----------------------------------

//----------------------------------print_usage----------------------------------
static void print_usage() {
	printf("Usage:\n");
  printf("    -h --help\n");
  printf("      print this help screen\n");
  printf("    -c --chan\n");
  printf("      channel number. default 37. valid range 0~39\n");
  printf("    -g --gain\n");
  printf("      rx gain in dB. HACKRF rxvga default 40, valid 0~62, lna in max gain. bladeRF default is max rx gain 66dB (valid 0~66)\n");
  printf("\nSee README for detailed information.\n");
}
//----------------------------------print_usage----------------------------------

//----------------------------------MISC MISC MISC----------------------------------
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
  int num_hex = strlen(hex);
  while(hex[num_hex-1]<=32 || hex[num_hex-1]>=127) {
    num_hex--;
  }

  if (num_hex%2 != 0) {
    printf("convert_hex_to_bit: Half octet is encountered! num_hex %d\n", num_hex);
    printf("%s\n", hex);
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
//----------------------------------MISC MISC MISC----------------------------------

//----------------------------------some basic signal definition----------------------------------
#define SAMPLE_PER_SYMBOL 4 // 4M sampling rate

#define MOD_IDX (0.5)
#define LEN_GAUSS_FILTER (4) // pre 2, post 2

volatile int rx_buf_offset; // remember to initialize it!

#define LEN_BUF_IN_SAMPLE (4*4096) //4096 samples = ~1ms for 4Msps
#define LEN_BUF (LEN_BUF_IN_SAMPLE*2)
//----------------------------------some basic signal definition----------------------------------

//----------------------------------BTLE SPEC related----------------------------------
#include "scramble_table_ch37.h"
#define MAX_NUM_CHAR_CMD (256)
#define DEFAULT_CHANNEL 37
#define MAX_CHANNEL_NUMBER 39
#define MAX_NUM_INFO_BYTE (43)
#define MAX_NUM_PHY_BYTE (47)
//#define MAX_NUM_PHY_SAMPLE ((MAX_NUM_PHY_BYTE*8*SAMPLE_PER_SYMBOL)+(LEN_GAUSS_FILTER*SAMPLE_PER_SYMBOL))
#define MAX_NUM_PHY_SAMPLE (MAX_NUM_PHY_BYTE*8*SAMPLE_PER_SYMBOL)
#define LEN_BUF_MAX_NUM_PHY_SAMPLE (MAX_NUM_PHY_BYTE*8*SAMPLE_PER_SYMBOL)

#define NUM_PREAMBLE_BYTE (1)
#define NUM_ACCESS_ADDR_BYTE (4)
#define NUM_PREAMBLE_ACCESS_BYTE (NUM_PREAMBLE_BYTE+NUM_ACCESS_ADDR_BYTE)
#define NUM_PRE_SAMPLE (NUM_PREAMBLE_ACCESS_BYTE*8*SAMPLE_PER_SYMBOL)
#define MAX_NUM_BODY_BYTE (MAX_NUM_PHY_BYTE-NUM_PREAMBLE_ACCESS_BYTE)
#define MAX_NUM_BODY_SAMPLE (MAX_NUM_BODY_BYTE*8*SAMPLE_PER_SYMBOL)
#define LEN_BUF_MAX_NUM_BODY (MAX_NUM_BODY_SAMPLE*2)

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

uint64_t get_freq_by_channel_number(int channel_number) {

uint64_t freq_hz;

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
} else {
  freq_hz = 0xffffffffffffffff;
}
  
return(freq_hz);
  
}

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

void crc24_and_scramble_to_gen_phy_bit(char *crc_init_hex, PKT_INFO *pkt) {
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
//----------------------------------BTLE SPEC related----------------------------------


//----------------------------------board specific operation----------------------------------

#ifdef USE_BLADERF //--------------------------------------BladeRF-----------------------
char *board_name = "BladeRF";
#define MAX_GAIN 66
#define DEFAULT_GAIN 66
typedef struct bladerf_devinfo bladerf_devinfo;
typedef struct bladerf bladerf_device;
typedef int16_t IQ_TYPE;
volatile IQ_TYPE rx_buf[LEN_BUF+LEN_BUF_MAX_NUM_PHY_SAMPLE];
static inline const char *backend2str(bladerf_backend b)
{
    switch (b) {
        case BLADERF_BACKEND_LIBUSB:
            return "libusb";
        case BLADERF_BACKEND_LINUX:
            return "Linux kernel driver";
        default:
            return "Unknown";
    }
}

int init_board(bladerf_device *dev, bladerf_devinfo *dev_info) {
  int n_devices = bladerf_get_device_list(&dev_info);

  if (n_devices < 0) {
    if (n_devices == BLADERF_ERR_NODEV) {
        printf("init_board: No bladeRF devices found.\n");
    } else {
        printf("init_board: Failed to probe for bladeRF devices: %s\n", bladerf_strerror(n_devices));
    }
		print_usage();
		return(-1);
  }

  printf("init_board: %d bladeRF devices found! The 1st one will be used:\n", n_devices);
  printf("    Backend:        %s\n", backend2str(dev_info[0].backend));
  printf("    Serial:         %s\n", dev_info[0].serial);
  printf("    USB Bus:        %d\n", dev_info[0].usb_bus);
  printf("    USB Address:    %d\n", dev_info[0].usb_addr);

  int fpga_loaded;
  int status = bladerf_open(&dev, NULL);
  if (status != 0) {
    printf("init_board: Failed to open bladeRF device: %s\n",
            bladerf_strerror(status));
    return(-1);
  }

  fpga_loaded = bladerf_is_fpga_configured(dev);
  if (fpga_loaded < 0) {
      printf("init_board: Failed to check FPGA state: %s\n",
                bladerf_strerror(fpga_loaded));
      status = -1;
      goto initialize_device_out_point;
  } else if (fpga_loaded == 0) {
      printf("init_board: The device's FPGA is not loaded.\n");
      status = -1;
      goto initialize_device_out_point;
  }

  unsigned int actual_sample_rate;
  status = bladerf_set_sample_rate(dev, BLADERF_MODULE_RX, SAMPLE_PER_SYMBOL*1000000ul, &actual_sample_rate);
  if (status != 0) {
      printf("init_board: Failed to set samplerate: %s\n",
              bladerf_strerror(status));
      goto initialize_device_out_point;
  }

  status = bladerf_set_frequency(dev, BLADERF_MODULE_RX, 2402000000ul);
  if (status != 0) {
      printf("init_board: Failed to set frequency: %s\n",
              bladerf_strerror(status));
      goto initialize_device_out_point;
  }

  unsigned int actual_frequency;
  status = bladerf_get_frequency(dev, BLADERF_MODULE_RX, &actual_frequency);
  if (status != 0) {
      printf("init_board: Failed to read back frequency: %s\n",
              bladerf_strerror(status));
      goto initialize_device_out_point;
  }

initialize_device_out_point:
  if (status != 0) {
      bladerf_close(dev);
      dev = NULL;
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

  printf("init_board: set bladeRF to %f MHz %u sps BLADERF_LB_NONE.\n", (float)actual_frequency/1000000.0f, actual_sample_rate);
  return(0);
}

inline int open_board(uint64_t freq_hz, int gain, bladerf_device *dev) {
  int status;

  status = bladerf_set_frequency(dev, BLADERF_MODULE_RX, freq_hz);
  if (status != 0) {
    printf("open_board: Failed to set frequency: %s\n",
            bladerf_strerror(status));
    return(-1);
  }

  status = bladerf_set_gain(dev, BLADERF_MODULE_RX, gain);
  if (status != 0) {
    printf("open_board: Failed to set gain: %s\n",
            bladerf_strerror(status));
    return(-1);
  }

  status = bladerf_sync_config(dev, BLADERF_MODULE_RX, BLADERF_FORMAT_SC16_Q11, 2, LEN_BUF_IN_SAMPLE, 1, 3500);
  if (status != 0) {
     printf("open_board: Failed to configure sync interface: %s\n",
             bladerf_strerror(status));
     return(-1);
  }

  status = bladerf_enable_module(dev, BLADERF_MODULE_RX, true);
  if (status != 0) {
     printf("open_board: Failed to enable module: %s\n",
             bladerf_strerror(status));
     return(-1);
  }

  return(0);
}

inline int close_board(bladerf_device *dev) {
  // Disable TX module, shutting down our underlying TX stream
  int status = bladerf_enable_module(dev, BLADERF_MODULE_RX, false);
  if (status != 0) {
    printf("close_board: Failed to disable module: %s\n",
             bladerf_strerror(status));
    return(-1);
  }

  return(0);
}

void exit_board(bladerf_device *dev) {
  bladerf_close(dev);
  dev = NULL;
}

bladerf_device* config_run_board(uint64_t freq_hz, int gain, void **rf_dev) {
  bladerf_device *dev = NULL;
  return(dev);
}

void stop_close_board(bladerf_device* rf_dev){
  
}

#else //-----------------------------the board is HACKRF-----------------------------
char *board_name = "HACKRF";
#define MAX_GAIN 62
#define DEFAULT_GAIN 40
#define MAX_LNA_GAIN 40

typedef int8_t IQ_TYPE;
volatile IQ_TYPE rx_buf[LEN_BUF + LEN_BUF_MAX_NUM_PHY_SAMPLE];

int rx_callback(hackrf_transfer* transfer) {
  int i;
  for( i=0; i<transfer->valid_length; i++) {
    rx_buf[rx_buf_offset] = transfer->buffer[i];
    rx_buf_offset = (rx_buf_offset+1)&( LEN_BUF-1 ); //cyclic buffer
  }
  return(0);
}

int init_board() {
	int result = hackrf_init();
	if( result != HACKRF_SUCCESS ) {
		printf("open_board: hackrf_init() failed: %s (%d)\n", hackrf_error_name(result), result);
		print_usage();
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

inline int open_board(uint64_t freq_hz, int gain, hackrf_device** device) {
  int result;

	result = hackrf_open(device);
	if( result != HACKRF_SUCCESS ) {
		printf("open_board: hackrf_open() failed: %s (%d)\n", hackrf_error_name(result), result);
		return(-1);
	}

  result = hackrf_set_freq(*device, freq_hz);
  if( result != HACKRF_SUCCESS ) {
    printf("open_board: hackrf_set_freq() failed: %s (%d)\n", hackrf_error_name(result), result);
    return(-1);
  }

  result = hackrf_set_sample_rate(*device, SAMPLE_PER_SYMBOL*1000000ul);
  if( result != HACKRF_SUCCESS ) {
    printf("open_board: hackrf_set_sample_rate() failed: %s (%d)\n", hackrf_error_name(result), result);
    return(-1);
  }
  
  result = hackrf_set_baseband_filter_bandwidth(*device, SAMPLE_PER_SYMBOL*1000000ul/2);
  if( result != HACKRF_SUCCESS ) {
    printf("open_board: hackrf_set_baseband_filter_bandwidth() failed: %s (%d)\n", hackrf_error_name(result), result);
    return(-1);
  }
  
  result = hackrf_set_vga_gain(*device, gain);
	result |= hackrf_set_lna_gain(*device, MAX_LNA_GAIN);
  if( result != HACKRF_SUCCESS ) {
    printf("open_board: hackrf_set_txvga_gain() failed: %s (%d)\n", hackrf_error_name(result), result);
    return(-1);
  }

  return(0);
}

void exit_board(hackrf_device *device) {
	if(device != NULL)
	{
		hackrf_exit();
		printf("hackrf_exit() done\n");
	}
}

inline int close_board(hackrf_device *device) {
  int result;

	if(device != NULL)
	{
    result = hackrf_stop_rx(device);
    if( result != HACKRF_SUCCESS ) {
      printf("close_board: hackrf_stop_rx() failed: %s (%d)\n", hackrf_error_name(result), result);
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

inline int run_board(hackrf_device* device) {
  int result;

	result = hackrf_stop_rx(device);
	if( result != HACKRF_SUCCESS ) {
		printf("run_board: hackrf_stop_rx() failed: %s (%d)\n", hackrf_error_name(result), result);
		return(-1);
	}
  
  result = hackrf_start_rx(device, rx_callback, NULL);
  if( result != HACKRF_SUCCESS ) {
    printf("run_board: hackrf_start_rx() failed: %s (%d)\n", hackrf_error_name(result), result);
    return(-1);
  }

  return(0);
}

inline int config_run_board(uint64_t freq_hz, int gain, void **rf_dev) {
  hackrf_device *dev = NULL;
  
  (*rf_dev) = dev;
  
  if (init_board() != 0) {
    return(-1);
  }
  
  if ( open_board(freq_hz, gain, &dev) != 0 ) {
    (*rf_dev) = dev;
    return(-1);
  }

  (*rf_dev) = dev;
  if ( run_board(dev) != 0 ) {
    return(-1);
  }
  
  return(0);
}

void stop_close_board(hackrf_device* device){
  if (close_board(device)!=0){
    return;
  }
  exit_board(device);
}

#endif  //#ifdef USE_BLADERF
//----------------------------------board specific operation----------------------------------


//----------------------------------command line parameters----------------------------------
// Parse the command line arguments and return optional parameters as
// variables.
// Also performs some basic sanity checks on the parameters.
void parse_commandline(
  // Inputs
  int argc,
  char * const argv[],
  // Outputs
  int* chan,
  int* gain
) {
  printf("BTLE/BT4.0 Scanner(NOT support bladeRF so far). Xianjun Jiao. putaoshu@gmail.com\n\n");
  
  // Default values
  (*chan) = DEFAULT_CHANNEL;

  (*gain) = DEFAULT_GAIN;

  while (1) {
    static struct option long_options[] = {
      {"help",         no_argument,       0, 'h'},
      {"chan",   required_argument, 0, 'c'},
      {"gain",         required_argument, 0, 'g'},
      {0, 0, 0, 0}
    };
    /* getopt_long stores the option index here. */
    int option_index = 0;
    int c = getopt_long (argc, argv, "hc:g:",
                     long_options, &option_index);

    /* Detect the end of the options. */
    if (c == -1)
      break;

    switch (c) {
      char * endp;
      case 0:
        // Code should only get here if a long option was given a non-null
        // flag value.
        printf("Check code!\n");
        goto abnormal_quit;
        break;
        
      case 'h':
        goto abnormal_quit;
        break;
        
      case 'c':
        (*chan) = strtol(optarg,&endp,10);
        break;
        
      case 'g':
        (*gain) = strtol(optarg,&endp,10);
        break;
        
      case '?':
        /* getopt_long already printed an error message. */
        goto abnormal_quit;
        
      default:
        goto abnormal_quit;
    }
    
  }

  if ( (*chan)<0 || (*chan)>MAX_CHANNEL_NUMBER ) {
    printf("channel number must be within 0~%d!\n", MAX_CHANNEL_NUMBER);
    goto abnormal_quit;
  }
  
  if ( (*gain)<0 || (*gain)>MAX_GAIN ) {
    printf("rx gain must be within 0~%d!\n", MAX_GAIN);
    goto abnormal_quit;
  }
  
  // Error if extra arguments are found on the command line
  if (optind < argc) {
    printf("Error: unknown/extra arguments specified on command line\n");
    goto abnormal_quit;
  }

  return;
  
abnormal_quit:
  print_usage();
  exit(-1);
}
//----------------------------------command line parameters----------------------------------

//----------------------------------receiver----------------------------------

bool search_unique_bytes(IQ_TYPE* rxp, const uint8_t *unique_bytes, const int num_bytes) {

  return(true);
}

void demod_bytes(IQ_TYPE* rxp, uint8_t *out_bytes, int num_bytes) {

}

inline void receiver(int phase, int buf_sp){
  IQ_TYPE *rxp = (IQ_TYPE *)(rx_buf + buf_sp);
  
  if (phase==0) {
    memcpy((void *)(rx_buf+LEN_BUF), (void *)rx_buf, LEN_BUF_MAX_NUM_PHY_SAMPLE*sizeof(IQ_TYPE));
  }

  //printf("phase %d rx_buf_offset %d buf_sp %d LEN_BUF/2 %d mem scale %d\n", phase, rx_buf_offset, buf_sp, LEN_BUF/2, sizeof(IQ_TYPE));
  
  static uint8_t tmp_bytes[MAX_NUM_BODY_BYTE];
  const uint8_t preamble_access_bytes[NUM_PREAMBLE_ACCESS_BYTE] = {0xAA, 0xD6, 0xBE, 0x89, 0x8E};
  int i = 0;
  int running_sp, num_demod_bytes;
  while( i< (LEN_BUF/2) ) {
    running_sp = i;
    if (~search_unique_bytes(rxp+running_sp, preamble_access_bytes, NUM_PREAMBLE_ACCESS_BYTE)) {
      continue;
    }
    
    running_sp = running_sp + 8*NUM_PREAMBLE_ACCESS_BYTE*2*SAMPLE_PER_SYMBOL;
    num_demod_bytes = 1;
    demod_bytes(rxp+running_sp, tmp_bytes, num_demod_bytes);
    
    i = i + running_sp + 8*num_demod_bytes*2*SAMPLE_PER_SYMBOL;
  }
}
//----------------------------------receiver----------------------------------

int main(int argc, char** argv) {
  uint64_t freq_hz;
  int gain, chan, phase, rx_buf_offset_tmp, buf_sp;
  bool run_flag = false;
  void* rf_dev;

  parse_commandline(argc, argv, &chan, &gain);
  freq_hz = get_freq_by_channel_number(chan);
  printf("cmd line input: chan %d, freq %ldMHz, rx %ddB (%s)\n", chan, freq_hz/1000000, gain, board_name);
  
  // run cyclic recv in background
  do_exit = false;
  if ( config_run_board(freq_hz, gain, &rf_dev) != 0 ){
    if (rf_dev != NULL) {
      goto program_quit;
    }
    else {
      return(1);
    }
  }
  
  // scan
  do_exit = false;
  phase = 0;
  rx_buf_offset = 0;
  while(do_exit == false) { //hackrf_is_streaming(hackrf_dev) == HACKRF_TRUE?
    /*
    if ( (rx_buf_offset-rx_buf_offset_old) > 65536 || (rx_buf_offset-rx_buf_offset_old) < -65536 ) {
      printf("%d\n", rx_buf_offset);
      rx_buf_offset_old = rx_buf_offset;
    }
     * */
    // total buf len LEN_BUF = (4*4096)*2 =  (~ 4ms); tail length MAX_NUM_PHY_SAMPLE*2=LEN_BUF_MAX_NUM_PHY_SAMPLE
    
    rx_buf_offset_tmp = rx_buf_offset - LEN_BUF_MAX_NUM_PHY_SAMPLE;
    // cross point 0
    if (rx_buf_offset_tmp>=0 && rx_buf_offset_tmp<(LEN_BUF/2) && phase==1) {
      //printf("rx_buf_offset cross 0: %d %d %d\n", rx_buf_offset, (LEN_BUF/2), LEN_BUF_MAX_NUM_PHY_SAMPLE);
      phase = 0;
      
      buf_sp = (LEN_BUF/2);
      run_flag = true;
    }

    // cross point 1
    if (rx_buf_offset_tmp>=(LEN_BUF/2) && phase==0) {
      //printf("rx_buf_offset cross 1: %d %d %d\n", rx_buf_offset, (LEN_BUF/2), LEN_BUF_MAX_NUM_PHY_SAMPLE);
      phase = 1;

      buf_sp = 0;
      run_flag = true;
    }
    
    if (run_flag) {
      receiver(phase, buf_sp);
      run_flag = false;
    }
  }

program_quit:
  stop_close_board(rf_dev);
  
  return(0);
}
