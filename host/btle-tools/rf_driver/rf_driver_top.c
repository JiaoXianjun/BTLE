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

pthread_mutex_t callback_lock;

uint64_t freq_hz_tx_driver_internal = 0;
uint64_t freq_hz_rx_driver_internal = 0;

int (*tx_one_buf_internal)(void *dev, char *buf, int length);
int (*rf_tune_rx_internal)(void *dev, uint64_t freq_hz);
int (*rf_tune_tx_internal)(void *dev, uint64_t freq_hz);
void (*stop_close_rf_internal)(void *dev);

void sigint_callback_handler(int signum)
{
	fprintf(stderr, "Caught signal %d\n", signum);
	do_exit = true;
//  exit(1);
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

void stop_close_rf(void *dev){
  (*stop_close_rf_internal)(dev);
}

void probe_run_rf(void **rf_dev, uint64_t freq_hz, char *arg_string, int *gain, enum rf_type* rf_in_use) {
  // check board and run cyclic recv in background
  int gain_tmp;
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
  if ((*rf_in_use) == NOTVALID) { // NEED to detect
    printf("probe_run_rf: Start to probe avaliable board...\n");

    if ( (*gain)==-1 ) 
      gain_tmp = HACKRF_DEFAULT_GAIN;
    else
      gain_tmp = (*gain);
    if ( hackrf_config_run_board(freq_hz, gain_tmp, rf_dev) ){
      //printf("hhhhh%d\n",*rf_dev);
      //exit(1);
      hackrf_stop_close_board(*rf_dev);

      if ( (*gain)==-1 ) 
        gain_tmp = BLADERF_DEFAULT_GAIN;
      else
        gain_tmp = (*gain);
      if ( bladerf_config_run_board(freq_hz, gain_tmp, rf_dev) ){
        bladerf_stop_close_board(*rf_dev);

        if ( (*gain)==-1 ) 
          gain_tmp = USRP_DEFAULT_GAIN;
        else
          gain_tmp = (*gain);
        if ( usrp_config_run_board(freq_hz, arg_string, gain_tmp, rf_dev) ){
          //exit(1);
          printf("probe_run_rf: No RF board is detected!\n");
          usrp_stop_close_board(*rf_dev);
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
    if ((*rf_in_use) == HACKRF) {
      printf("probe_run_rf: Try to probe HackRF...\n");

      if ( (*gain)==-1 ) 
        gain_tmp = HACKRF_DEFAULT_GAIN;
      else
        gain_tmp = (*gain);
      if ( hackrf_config_run_board(freq_hz, gain_tmp, rf_dev) ){
        hackrf_stop_close_board(*rf_dev);
        printf("probe_run_rf: No HackRF board is detected!\n");
        exit(-1);
      } else 
        (*gain) = gain_tmp;
    } else if ((*rf_in_use) == BLADERF) {
      printf("probe_run_rf: Try to probe bladeRF...\n");

      if ( (*gain)==-1 ) 
        gain_tmp = BLADERF_DEFAULT_GAIN;
      else
        gain_tmp = (*gain);
      if ( bladerf_config_run_board(freq_hz, gain_tmp, rf_dev) ){
        bladerf_stop_close_board(*rf_dev);
        printf("probe_run_rf: No bladeRF board is detected!\n");
        exit(-1);
      } else 
        (*gain) = gain_tmp;
    } else if ((*rf_in_use) == USRP) {
      printf("probe_run_rf: Try to probe USRP...\n");

      if ( (*gain)==-1 ) 
        gain_tmp = USRP_DEFAULT_GAIN;
      else
        gain_tmp = (*gain);
      if ( usrp_config_run_board(freq_hz, arg_string, gain_tmp, rf_dev) ){
        usrp_stop_close_board(*rf_dev);
        printf("probe_run_rf: No USRP board is detected!\n");
        exit(-1);
      } else
        (*gain) = gain_tmp;
    } 
  }
  
  if ((*rf_in_use) == HACKRF) {
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
}
