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
PKT_INFO packets[MAX_NUM_PACKET];

static void print_usage() {
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

int parse_packet_seq(int num_input, char** argv, int *num_repeat_return){
  int repeat_specific = 0;

  int num_repeat = get_num_repeat(argv[num_input-1], &repeat_specific);
  if (num_repeat == -2) {
    return(-2);
  }

  int num_packet = 0;
  if (repeat_specific == 1){
    num_packet = num_input - 1;
  } else {
    num_packet = num_input - 0;
  }

  printf("num_repeat %d\n", num_repeat);
  printf("num_packet %d\n", num_packet);

  (*num_repeat_return) = num_repeat;

  int i;
  for (i=0; i<num_packet; i++) {

    if (strlen(argv[i]) >= MAX_NUM_CHAR_CMD) {
      fprintf(stderr, "parse_packet_seq: Too long packet descriptor of packet %d! Maximum allowed are %d characters\n", i, MAX_NUM_CHAR_CMD-1);
      return(-2);
    }
    strcpy(packets[i].cmd_str, argv[i]);
    printf("\npacket %d\n", i);
    if (calculate_pkt_info( &(packets[i]) ) == -1){
      fprintf(stderr, "parse_packet_seq: calculate_pkt_info failed!\n");
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

int parse_commandline(
  // Inputs
  int argc,
  char * const argv[],
  // Outputs
  int* gain,
  enum board_type *rf_in_use,
  char *arg_string,
  int *num_item,
  char **descriptor
) {
  char *filename=NULL;
  char *descriptor_raw=NULL;

  printf("BLE sniffer. Xianjun Jiao. putaoshu@msn.com\n\n");
  
  (*gain) = -1;
  
  (*rf_in_use) = NOTVALID;

  strcpy(arg_string,"");

  while (1) {
    static struct option long_options[] = {
      {"help",       no_argument,       0, 'h'},
      {"gain",       required_argument, 0, 'g'},
      {"board",      required_argument, 0, 'b'},
      {"descriptor", required_argument, 0, 'd'},
      {"filename",   required_argument, 0, 'i'},
      {"s",          required_argument, 0, 's'},
      {0, 0, 0, 0}
    };
    /* getopt_long stores the option index here. */
    int option_index = 0;
    int c = getopt_long (argc, argv, "hg:b:d:i:s:", // ： means parameter
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

      case 'g':
        (*gain) = strtol(optarg,&endp,10);
        break;
      
      case 'b':
        (*rf_in_use) = strtol(optarg,&endp,10);
        break;

      case 'd':
        descriptor_raw = strdup(optarg);
        break;

      case 'i':
        filename = strdup(optarg);
        break;

      case 's':
        if (strlen(optarg)>=MAX_NUM_CHAR_CMD) {
          fprintf(stderr,"Error: USRP argument string is too long. Should < %d!\n",MAX_NUM_CHAR_CMD);
          goto abnormal_quit;
        }
        else
          strcpy(arg_string,optarg);
        break;

      case '?':
        /* getopt_long already printed an error message. */
        goto abnormal_quit;
        
      default:
        goto abnormal_quit;
    }
    
  }

  if ( (*rf_in_use)<0 || (*rf_in_use)>NOTVALID ) {
    fprintf(stderr,"Board type must be from %d, %d, %d, %d.!\n", HACKRF, BLADERF, USRP, NOTVALID);
    goto abnormal_quit;
  }

  if (descriptor_raw) {//if user input a string
    if (get_word(descriptor_raw, MAX_NUM_PACKET, MAX_NUM_CHAR_CMD, num_item, descriptor))
      goto abnormal_quit;
  } else if (filename) {//if user specify a file
    if ( read_items_from_file(filename, MAX_NUM_PACKET, MAX_NUM_CHAR_CMD, num_item, descriptor) )
      goto abnormal_quit;
  } else {
    fprintf(stderr,"Please specify packet descriptor string or a description file!\n");
    goto abnormal_quit;
  }

  if (filename) free(filename);
  if (descriptor_raw) free(descriptor_raw);
  return(0);
  
abnormal_quit:
  print_usage();
  if (filename) free(filename);
  if (descriptor_raw) free(descriptor_raw);
  return(-1);
}

int main(int argc, char** argv) {
  int num_packet, num_item, i, j, num_items, gain;
  int num_repeat = 0; // -1: inf; 0: 1; other: specific
  void* rf_dev=NULL;
  enum board_type rf_in_use = NOTVALID;
  char arg_string[MAX_NUM_CHAR_CMD];
  char **descriptor = malloc_2d(MAX_NUM_PACKET, MAX_NUM_CHAR_CMD);
 
  if (descriptor==NULL) {
    fprintf(stderr, "malloc_2d failed!\n");
    exit(-1);
  }

  if ( parse_commandline(argc, argv, &gain, &rf_in_use, arg_string, &num_item, descriptor) )
    goto main_out;

  num_packet = parse_packet_seq(num_item, descriptor, &num_repeat);
  if ( num_repeat == -2 )
    goto main_out;

  release_2d(descriptor, MAX_NUM_PACKET);
  printf("\n");

  if (USRP)
    trx->tx.num_dev_buf = 0;
    trx->tx.num_sample_dev_buf = 0; // will be decided automatically by HW during initialization
    trx->tx.num_sample_app_buf = 0; // app buffer will be maintained in main program
    trx->tx.num_sample_app_buf_tail = 0;
  else if (BLADERF)
    trx->tx.num_dev_buf = 0;
    trx->tx.num_sample_dev_buf = NUM_BLADERF_BUF_SAMPLE_TX;
    trx->tx.num_sample_app_buf = 0;
    trx->tx.num_sample_app_buf_tail = 0;
  else if (HACKRF)

  probe_run_rf(&rf_dev, get_freq_by_channel_number(37), arg_string, &gain, &rf_in_use);

  struct timeval time_tmp, time_current_pkt, time_pre_pkt;
  gettimeofday(&time_current_pkt, NULL);
  for (j=0; j<num_repeat; j++ ) {
    for (i=0; i<num_packet; i++) {
      time_pre_pkt = time_current_pkt;
      gettimeofday(&time_current_pkt, NULL);

      if ( tx_one_buf_btle_ch(rf_dev, packets[i].channel_number, packets[i].phy_sample, 2*packets[i].num_phy_sample) )
        goto main_out;

      printf("r%d p%d at %dus\n", j, i,  TimevalDiff(&time_current_pkt, &time_pre_pkt) );

      gettimeofday(&time_tmp, NULL);
      while(TimevalDiff(&time_tmp, &time_current_pkt)<( packets[i].space*1000 ) ) {
        gettimeofday(&time_tmp, NULL);
      }
    }
  }
  printf("\n");

main_out:
  fprintf(stderr,"Exit ...\n");
  if (descriptor) release_2d(descriptor, MAX_NUM_PACKET);
  stop_close_rf(rf_dev);
	return(0);
}
