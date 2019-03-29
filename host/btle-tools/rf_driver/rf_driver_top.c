#include <pthread.h>
#include <signal.h>

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

#include "../common_misc.h"
#include "rf_driver_top.h"
#include "rf_driver_hackrf.h"
#include "rf_driver_bladerf.h"
#include "rf_driver_usrp.h"

extern volatile bool do_exit;

volatile bool do_exit = false;
static volatile int rx_buf_offset=0; // remember to initialize it!
static volatile IQ_TYPE rx_buf[LEN_BUF + LEN_BUF_MAX_NUM_PHY_SAMPLE];

pthread_mutex_t callback_lock;

uint64_t freq_hz_tx_driver_internal = 0;
uint64_t freq_hz_rx_driver_internal = 0;

int (*tx_one_buf_internal)(void *dev, char *buf, int length);
int (*rf_tune_rx_internal)(void *dev, uint64_t freq_hz);
int (*rf_tune_tx_internal)(void *dev, uint64_t freq_hz);
void (*stop_close_rf_internal)(void *dev, bool trx_flag);

void sigint_callback_handler(int signum)
{
	fprintf(stderr, "Caught signal %d\n", signum);
	do_exit = true;
//  exit(1);
}

int get_rx_sample(void *dev, void *buf, int *len) {
  static phase = 0;
  int rx_buf_offset_tmp;
  int sample_ready_flag = 0;
  IQ_TYPE *rxp;

  rx_buf_offset_tmp = rx_buf_offset - LEN_BUF_MAX_NUM_PHY_SAMPLE;
  // cross point 0
  if (rx_buf_offset_tmp>=0 && rx_buf_offset_tmp<(LEN_BUF/2) && phase==1) {
    //printf("rx_buf_offset cross 0: %d %d %d\n", rx_buf_offset, (LEN_BUF/2), LEN_BUF_MAX_NUM_PHY_SAMPLE);
    phase = 0;
    memcpy((void *)(rx_buf+LEN_BUF), (void *)rx_buf, LEN_BUF_MAX_NUM_PHY_SAMPLE*sizeof(IQ_TYPE));
    rxp = (IQ_TYPE*)(rx_buf + (LEN_BUF/2));
    sample_ready_flag = 1;
  }

  // cross point 1
  if (rx_buf_offset_tmp>=(LEN_BUF/2) && phase==0) {
    //printf("rx_buf_offset cross 1: %d %d %d\n", rx_buf_offset, (LEN_BUF/2), LEN_BUF_MAX_NUM_PHY_SAMPLE);
    phase = 1;
    rxp = (IQ_TYPE*)rx_buf;
    sample_ready_flag = 1;
  }

  (*buf) = rxp;

  return(sample_ready_flag);
}

int rf_tune_rx_direct(void *dev, uint64_t freq_hz){
  freq_hz_rx_driver_internal = freq_hz;
  return( (*rf_tune_rx_internal)(dev, freq_hz_rx_driver_internal) );
}

int rf_tune_rx(void *dev, uint64_t freq_hz){
  if (freq_hz!=freq_hz_rx_driver_internal) {
    freq_hz_rx_driver_internal = freq_hz;
  } else
    return(0);

  return( (*rf_tune_rx_internal)(dev, freq_hz_rx_driver_internal) );
}

int rf_tune_tx_direct(void *dev, uint64_t freq_hz){
  freq_hz_tx_driver_internal = freq_hz;
  return( (*rf_tune_tx_internal)(dev, freq_hz_tx_driver_internal) );
}

int rf_tune_tx(void *dev, uint64_t freq_hz){
  if (freq_hz!=freq_hz_tx_driver_internal) {
    freq_hz_tx_driver_internal = freq_hz;
  } else
    return(0);
    
  return( (*rf_tune_tx_internal)(dev, freq_hz_tx_driver_internal) );
}

int tx_one_buf_direct(void *dev, char *buf, int length) {
  return( (*tx_one_buf_internal)(dev, buf, length) );
}

int tx_one_buf_freq(void *dev, uint64_t freq_hz, char *buf, int length) {
  if (rf_tune_tx(dev, freq_hz) != 0)
    return(-1);

  return( (*tx_one_buf_internal)(dev, buf,length) );
}

void stop_close_rf(void *dev, int trx_flag){
  if (dev)
    (*stop_close_rf_internal)(dev, int trx_flag);
}

void probe_run_rf(struct trx_cfg_op *trx) {
  pthread_mutex_init(&callback_lock, NULL);

  #ifdef _MSC_VER
    SetConsoleCtrlHandler( (PHANDLER_ROUTINE) sighandler, TRUE );
  #else
    if (signal(SIGINT, sigint_callback_handler)==SIG_ERR ||
        signal(SIGILL, sigint_callback_handler)==SIG_ERR ||
        signal(SIGFPE, sigint_callback_handler)==SIG_ERR ||
        signal(SIGSEGV,sigint_callback_handler)==SIG_ERR ||
        signal(SIGTERM,sigint_callback_handler)==SIG_ERR ||
        signal(SIGABRT,sigint_callback_handler)==SIG_ERR) {
        fprintf(stderr, "probe_run_rf: Failed to set up signal handler\n");
        exit(1);
      }
  #endif

  do_exit = false;
  if ( trx->hw_type == NOTVALID) { // NEED to detect
    printf("probe_run_rf: Start to probe avaliable board...\n");

    if ( hackrf_config_run_board(trx) ){
      //printf("hhhhh%d\n",*rf_dev);
      //exit(1);
      hackrf_stop_close_board(*rf_dev, trx_flag);

      if ( (*gain)==-1 ) 
        gain_tmp = BLADERF_DEFAULT_GAIN;
      else
        gain_tmp = (*gain);
      if ( bladerf_config_run_board(freq_hz, gain_tmp, sampl_rate, bw, trx_flag, rf_dev) ){
        bladerf_stop_close_board(*rf_dev, trx_flag);

        if ( (*gain)==-1 ) 
          gain_tmp = USRP_DEFAULT_GAIN;
        else
          gain_tmp = (*gain);
        if ( usrp_config_run_board(freq_hz, gain_tmp, sampl_rate, bw, trx_flag, rf_dev) ){
          //exit(1);
          printf("probe_run_rf: No RF board is detected!\n");
          usrp_stop_close_board(*rf_dev, trx_flag);
          exit(-1);
        } else {
          (*rf_in_use) = USRP;
          (*gain) = gain_tmp;
        }
      } else {
        (*rf_in_use) = BLADERF;
        (*gain) = gain_tmp;
      }
    } else {
      (*rf_in_use) = HACKRF;
      (*gain) = gain_tmp;
    }
  } else { //user specified the board
    if ( rf_cfg->hw_type == HACKRF) {
      printf("probe_run_rf: Try to probe HackRF...\n");

      if ( (*gain)==-1 ) 
        gain_tmp = HACKRF_DEFAULT_GAIN;
      else
        gain_tmp = (*gain);
      if ( hackrf_config_run_board(freq_hz, gain_tmp, sampl_rate, bw, trx_flag, rf_dev) ){
        hackrf_stop_close_board(*rf_dev, trx_flag);
        printf("probe_run_rf: No HackRF board is detected!\n");
        exit(-1);
      } else 
        (*gain) = gain_tmp;
    } else if ( rf_cfg->hw_type == BLADERF) {
      printf("probe_run_rf: Try to probe bladeRF...\n");

      if ( (*gain)==-1 ) 
        gain_tmp = BLADERF_DEFAULT_GAIN;
      else
        gain_tmp = (*gain);
      if ( bladerf_config_run_board(freq_hz, gain_tmp, sampl_rate, bw, trx_flag, rf_dev) ){
        bladerf_stop_close_board(*rf_dev, trx_flag);
        printf("probe_run_rf: No bladeRF board is detected!\n");
        exit(-1);
      } else 
        (*gain) = gain_tmp;
    } else if ( rf_cfg->hw_type == USRP) {
      printf("probe_run_rf: Try to probe USRP...\n");

      if ( (*gain)==-1 ) 
        gain_tmp = USRP_DEFAULT_GAIN;
      else
        gain_tmp = (*gain);
      if ( usrp_config_run_board(freq_hz, gain_tmp, sampl_rate, bw, trx_flag, rf_dev) ){
        usrp_stop_close_board(*rf_dev, trx_flag);
        printf("probe_run_rf: No USRP board is detected!\n");
        exit(-1);
      } else
        (*gain) = gain_tmp;
    } 
  }

  #if 0
  if ( rf_cfg->hw_type == HACKRF) {
    rf_tune_rx_internal = hackrf_tune;
    rf_tune_tx_internal = hackrf_tune;
    tx_one_buf_internal = hackrf_tx_one_buf;
    stop_close_rf_internal = hackrf_stop_close_board;
    printf("rf_in_use == HACKRF\n");
  } else if ((*rf_in_use) == BLADERF) {
    rf_tune_rx_internal = bladerf_tune_rx;
    rf_tune_tx_internal = bladerf_tune_tx;
    tx_one_buf_internal = bladerf_tx_one_buf;
    stop_close_rf_internal = bladerf_stop_close_board;
    printf("rf_in_use == BLADERF\n");
  } else if ((*rf_in_use) == USRP) {
    rf_tune_rx_internal = usrp_tune_rx;
    rf_tune_tx_internal = usrp_tune_tx;
    tx_one_buf_internal = usrp_tx_one_buf;
    stop_close_rf_internal = usrp_stop_close_board;
    printf("rf_in_use == USRP\n");
  } 
  #endif
}
