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

#include <unistd.h>
#include <sys/time.h>

#include <signal.h>

#include "common_misc.h"

#include "rf_driver_cfg.h"
#include "rf_driver_top.h"

#include "btle_lib.h"

volatile bool do_exit = false;

#define NUM_PRE_SEND_DATA (256)

#ifdef USE_BLADERF
#define NUM_BLADERF_BUF_SAMPLE 4096
volatile int16_t tx_buf[NUM_BLADERF_BUF_SAMPLE*2];
struct bladerf *dev = NULL;
#else
//volatile char tx_buf[MAX_NUM_PHY_SAMPLE_TX*2];
#define HACKRF_ONBOARD_BUF_SIZE (32768) // in usb_bulk_buffer.h
#define HACKRF_USB_BUF_SIZE (4096) // in hackrf.c lib_device->buffer_size
char tx_zeros[HACKRF_USB_BUF_SIZE-NUM_PRE_SEND_DATA] = {0};
volatile char *tx_buf;
static hackrf_device* device = NULL;

PKT_INFO packets[MAX_NUM_PACKET];

#include "gauss_cos_sin_table.h"

#include "scramble_table_ch37.h"

int tx_callback(hackrf_transfer* transfer) {
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
 
  return(0);
}
#endif

void sigint_callback_handler(int signum)
{
	fprintf(stdout, "Caught signal %d\n", signum);
	do_exit = true;
}

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

char tmp_str[MAX_NUM_CHAR_CMD];
char tmp_str1[MAX_NUM_CHAR_CMD];
float tmp_phy_bit_over_sampling[MAX_NUM_PHY_SAMPLE_TX + 2*LEN_GAUSS_FILTER*SAMPLE_PER_SYMBOL];
float tmp_phy_bit_over_sampling1[MAX_NUM_PHY_SAMPLE_TX];
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
    char phy_sample[2*MAX_NUM_PHY_SAMPLE_TX]; // GFSK output to D/A (hackrf board)
    int8_t phy_sample1[2*MAX_NUM_PHY_SAMPLE_TX]; // GFSK output to D/A (hackrf board)

    int space; // how many millisecond null signal shouwl be padded after this packet
} PKT_INFO;

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

      printf("r%d p%d at %dus\n", j, i,  TimevalDiff(&time_current_pkt, &time_pre_pkt) );

      gettimeofday(&time_tmp, NULL);
      while(TimevalDiff(&time_tmp, &time_current_pkt)<( packets[i].space*1000 ) ) {
        gettimeofday(&time_tmp, NULL);
      }
    }
  }
  printf("\n");

main_out:
  exit_board();
	printf("exit\n");

	return(0);
}
