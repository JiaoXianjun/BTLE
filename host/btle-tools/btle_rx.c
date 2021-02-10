// SPDX-FileCopyrightText: 2021 Xianjun Jiao <putaoshu@msn.com>
// SPDX-License-Identifier: Apache-2.0

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
#include <signal.h>

#include <unistd.h>
#include <sys/time.h>
#include <pthread.h>

#include "common_misc.h"

#include "rf_driver_cfg.h"
#include "rf_driver_top.h"

#include "btle_lib.h"

//----------------------------------print_usage----------------------------------
static void print_usage() {
	printf("Usage:\n");
  printf("    -h --help\n");
  printf("      Print this help screen\n");
  printf("    -c --chan\n");
  printf("      Channel number. default 37. valid range 0~39\n");
  printf("    -g --gain\n");
  printf("      Rx gain in dB. HACKRF rxvga default %d, valid 0~%d, LNA fixed gain %d. bladeRF default gain %d (valid 0~%d). USRP default gain %d\n", HACKRF_DEFAULT_GAIN,HACKRF_MAX_GAIN,HACKRF_MAX_LNA_GAIN, BLADERF_DEFAULT_GAIN,BLADERF_MAX_GAIN,USRP_DEFAULT_GAIN);
  printf("    -a --access\n");
  printf("      Access address. 4 bytes. Hex format (like 89ABCDEF). Default %08x for channel 37 38 39. For other channel you should pick correct value according to sniffed link setup procedure\n", DEFAULT_ACCESS_ADDR);
  printf("    -k --crcinit\n");
  printf("      CRC init value. 3 bytes. Hex format (like 555555). Default %06x for channel 37 38 39. For other channel you should pick correct value according to sniffed link setup procedure\n", DEFAULT_CRC_INIT);
  printf("    -v --verbose\n");
  printf("      Print more information when there is error\n");
  printf("    -r --raw\n");
  printf("      Raw mode. After access addr is detected, print out following raw 42 bytes (without descrambling, parsing)\n");
  printf("    -f --freq_hz\n");
  printf("      This frequency (Hz) will override channel setting (In case someone want to work on freq other than BTLE. More general purpose)\n");
  printf("    -m --access_mask\n");
  printf("      If a bit is 1 in this mask, corresponding bit in access address will be taken into packet existing decision (In case someone want a shorter/sparser unique word to do packet detection. More general purpose)\n");
  printf("    -o --hop\n");
  printf("      This will turn on data channel tracking (frequency hopping) after link setup information is captured in ADV_CONNECT_REQ packet\n");
  printf("    -b --board\n");
  printf("      Board selection. %d HackRF; %d bladeRF; %d USRP\n", HACKRF, BLADERF, USRP);
  printf("    -s --args\n");
  printf("      USRP args string\n");
  printf("\nSee README for detailed information.\n");
}
//----------------------------------print_usage----------------------------------

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
  int* gain,
  uint32_t* access_addr,
  uint32_t* crc_init,
  int* verbose_flag,
  int* raw_flag,
  uint64_t* freq_hz, 
  uint32_t* access_mask, 
  int* hop_flag,
  enum board_type *rf_in_use,
  char *arg_string
) {
  printf("BLE sniffer. Xianjun Jiao. putaoshu@msn.com\n\n");
  
  // Default values
  (*chan) = DEFAULT_CHANNEL;

  (*gain) = -1;
  
  (*access_addr) = DEFAULT_ACCESS_ADDR;
  
  (*crc_init) = 0x555555;
  
  (*verbose_flag) = 0;
  
  (*raw_flag) = 0;
  
  (*freq_hz) = 0;
  
  (*access_mask) = 0xFFFFFFFF;
  
  (*hop_flag) = 0;

  (*rf_in_use) = NOTVALID;

  strcpy(arg_string,"");

  while (1) {
    static struct option long_options[] = {
      {"help",        no_argument,       0, 'h'},
      {"chan",        required_argument, 0, 'c'},
      {"gain",        required_argument, 0, 'g'},
      {"access",      required_argument, 0, 'a'},
      {"crcinit",     required_argument, 0, 'k'},
      {"verbose",     no_argument,       0, 'v'},
      {"raw",         no_argument,       0, 'r'},
      {"freq_hz",     required_argument, 0, 'f'},
      {"access_mask", required_argument, 0, 'm'},
      {"hop",         no_argument,       0, 'o'},
      {"board",       required_argument, 0, 'b'},
      {"s",           required_argument, 0, 's'},
      {0, 0, 0, 0}
    };
    /* getopt_long stores the option index here. */
    int option_index = 0;
    int c = getopt_long (argc, argv, "hc:g:a:k:vrf:m:o:b:s:", // ： means parameter
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
      
      case 'v':
        (*verbose_flag) = 1;
        break;
        
      case 'r':
        (*raw_flag) = 1;
        break;
      
      case 'o':
        (*hop_flag) = 1;
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
      
      case 'f':
        (*freq_hz) = strtol(optarg,&endp,10);
        break;
        
      case 'a':
        (*access_addr) = strtol(optarg,&endp,16);
        break;
      
      case 'm':
        (*access_mask) = strtol(optarg,&endp,16);
        break;
        
      case 'k':
        (*crc_init) = strtol(optarg,&endp,16);
        break;

      case 'b':
        (*rf_in_use) = strtol(optarg,&endp,10);
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

  if ( (*chan)<0 || (*chan)>MAX_CHANNEL_NUMBER ) {
    fprintf(stderr,"Error: Channel number must be within 0~%d!\n", MAX_CHANNEL_NUMBER);
    goto abnormal_quit;
  }
  
//  if ( (*gain)<0 || (*gain)>HACKRF_MAX_GAIN ) {
//  if ( (*gain)<0 ) {
//    printf("rx gain must be > 0!\n", HACKRF_MAX_GAIN);
//    goto abnormal_quit;
//  }
  
  if ( (*rf_in_use)<0 || (*rf_in_use)>NOTVALID ) {
    fprintf(stderr,"Error: Board type must be from %d, %d, %d, %d.!\n", HACKRF, BLADERF, USRP, NOTVALID);
    goto abnormal_quit;
  }

  // Error if extra arguments are found on the command line
  if (optind < argc) {
    fprintf(stderr,"Error: Unknown/extra arguments specified on command line!\n");
    goto abnormal_quit;
  }

  if ( (*freq_hz) == 0)
    (*freq_hz) = get_freq_by_channel_number((*chan));

  return;
  
abnormal_quit:
  print_usage();
  exit(-1);
}

int main(int argc, char** argv) {
  uint64_t freq_hz;
  int gain, chan, verbose_flag, raw_flag, hop_flag;
  uint32_t access_addr, access_addr_mask, crc_init, crc_init_internal;
  char arg_string[MAX_NUM_CHAR_CMD];
  struct trx_cfg_op trx;
  enum board_type rf_in_use,
  IQ_TYPE *rxp;

  parse_commandline(argc, argv, &chan, &gain, &access_addr, &crc_init, &verbose_flag, &raw_flag, &freq_hz, &access_addr_mask, &hop_flag, &rf_in_use, arg_string);
  //printf("arg string %d\n", arg_string);

  trx.tx.en = false;//for sniffer, we only need rx

  trx.rx.en   = true;
  trx.rx.chan = chan;
  trx.rx.freq = freq_hz; // or -1
  trx.rx.rate = SAMPLE_PER_SYMBOL*1000000;
  trx.rx.bw   = SAMPLE_PER_SYMBOL*1000000/2;
  trx.rx.num_sample_app_buf      = LEN_BUF_RX_SAMPLE/2;
  trx.rx.num_sample_app_buf_tail = MAX_NUM_PHY_SAMPLE;
  trx.rx.app_buf_offset = 0;
  trx.rx.num_sample_dev_buf = 0; // will be decided later
  trx.rx.num_dev_buf        = 0; // will be decided later
  trx.rx.dev_buf_idx    = 0;
  trx.rx.app_buf = NULL;
  trx.rx.dev_buf = NULL;
  trx.rx.streamer= NULL;
  trx.rx.metadata= NULL;
  trx.rx.dev     = NULL;
  //pthread_mutex_init(&(trx.rx.callback_lock), NULL);
  trx.rx.tid     = 0;
  trx.rx.update_freq = NULL;
  trx.rx.update_gain = NULL;
  trx.rx.update_rate = NULL;
  trx.rx.update_bw   = NULL;
  trx.rx.proc_one_buf= NULL;
  
  // should set 
  if (USRP)
    trx.rx.gain = gain;// or -1
    trx->rx.num_dev_buf = 0;
    trx->rx.num_sample_dev_buf = 0;
  else if (BLADERF)
    trx->rx.num_sample_dev_buf = LEN_BUF_RX_SAMPLE/2;
    trx->rx.num_dev_buf = 2;
  else if (HACKRF)

  probe_run_rf(&trx);
  printf("Cmd line input: chan %d, freq %ldMHz, access addr %08x, crc init %06x raw %d verbose %d rx %ddB RF %d\n", chan, freq_hz/1000000, access_addr, crc_init, raw_flag, verbose_flag, gain, rf_in_use);
  
  crc_init_internal = receiver_init(access_addr_mask, crc_init);

  while(do_exit == false) { //hackrf_is_streaming(hackrf_dev) == HACKRF_TRUE?
    if (get_rx_sample(NULL, &rxp, NULL)) {
      receiver(rxp, (LEN_DEMOD_BUF_ACCESS-1)*2*SAMPLE_PER_SYMBOL+(LEN_BUF)/2, chan, access_addr, crc_init_internal, verbose_flag, raw_flag);

      if (hop_flag){
        if ( receiver_controller(rf_dev, verbose_flag, &chan, &access_addr, &crc_init_internal) )
          goto main_out;
      }
    }
  }

main_out:
  fprintf(stderr,"Exit ...\n");
  trx.stop_close(&trx);
  
  return(0);
}
