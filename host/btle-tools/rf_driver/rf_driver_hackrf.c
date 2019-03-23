#include "rf_driver_cfg.h"

#ifdef HAS_HACKRF
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

#include <hackrf.h>
#include "rf_driver_hackrf.h"
#include "../common_misc.h"

#include "rf_driver_top.h"

extern pthread_mutex_t callback_lock;
extern volatile IQ_TYPE rx_buf[];
extern volatile int rx_buf_offset; // remember to initialize it!
extern volatile bool do_exit;

extern void sigint_callback_handler(int signum);

//---------------------for TX---------------------------

volatile int hackrf_stop_tx = 1;
volatile int hackrf_tx_len;
volatile void *hackrf_tx_len;

int hackrf_tx_callback(hackrf_transfer* transfer) {
  int size_left;
  if (hackrf_stop_tx == 0) {
    memset(transfer->buffer, 0, NUM_PRE_SEND_DATA);
    memcpy(transfer->buffer+NUM_PRE_SEND_DATA, (char *)(hackrf_tx_len), hackrf_tx_len);

    size_left = (transfer->valid_length - hackrf_tx_len - NUM_PRE_SEND_DATA);
    memset(transfer->buffer+NUM_PRE_SEND_DATA+hackrf_tx_len, 0, size_left);
  } else {
    memset(transfer->buffer, 0, transfer->valid_length);
  }
  hackrf_stop_tx++;
 
  return(0);
}

int hackrf_rx_callback(hackrf_transfer* transfer) {
  int i;
  int8_t *p = (int8_t *)transfer->buffer;
  if (transfer->valid_length>0) {
    pthread_mutex_lock(&callback_lock);
    for( i=0; i<transfer->valid_length; i++) {
      rx_buf[rx_buf_offset] = p[i];
      rx_buf_offset = (rx_buf_offset+1)&( LEN_BUF-1 ); //cyclic buffer
    }
    pthread_mutex_unlock(&callback_lock);
  }
  //printf("%d\n", transfer->valid_length); // !!!!it is 262144 always!!!! Now it is 4096. Defined in hackrf.c lib_device->buffer_size
  return(0);
}

int hackrf_tune(void *device, uint64_t freq_hz) {
  int result = hackrf_set_freq((hackrf_device*)device, freq_hz);
  if( result != HACKRF_SUCCESS ) {
    fprintf(stderr,"hackrf_tune: hackrf_set_freq() failed: %s (%d)\n", hackrf_error_name(result), result);
    return(-1);
  }
  return(HACKRF_SUCCESS);
}

int hackrf_init_board() {
	int result = hackrf_init();
	if( result != HACKRF_SUCCESS ) {
		fprintf(stderr,"hackrf_init_board: hackrf_init() failed: %s (%d)\n", hackrf_error_name(result), result);
		//print_usage();
		return(EXIT_FAILURE);
	}

  return(0);
}

inline int hackrf_open_board(uint64_t freq_hz, int gain, hackrf_device** device) {
  int result;

	result = hackrf_open(device);
	if( result != HACKRF_SUCCESS ) {
		printf("hackrf_open_board: hackrf_open() failed: %s (%d)\n", hackrf_error_name(result), result);
 //   print_usage();
		return(-1);
	}

  result = hackrf_set_freq(*device, freq_hz);
  if( result != HACKRF_SUCCESS ) {
    printf("hackrf_open_board: hackrf_set_freq() failed: %s (%d)\n", hackrf_error_name(result), result);
 //   print_usage();
    return(-1);
  }

  result = hackrf_set_sample_rate(*device, SAMPLE_PER_SYMBOL*1000000ul);
  if( result != HACKRF_SUCCESS ) {
    printf("hackrf_open_board: hackrf_set_sample_rate() failed: %s (%d)\n", hackrf_error_name(result), result);
 //   print_usage();
    return(-1);
  }
  
  result = hackrf_set_baseband_filter_bandwidth(*device, SAMPLE_PER_SYMBOL*1000000ul/2);
  if( result != HACKRF_SUCCESS ) {
    printf("hackrf_open_board: hackrf_set_baseband_filter_bandwidth() failed: %s (%d)\n", hackrf_error_name(result), result);
 //   print_usage();
    return(-1);
  }
  
  result = hackrf_set_vga_gain(*device, gain);
	result |= hackrf_set_lna_gain(*device, HACKRF_MAX_LNA_GAIN);
  if( result != HACKRF_SUCCESS ) {
    printf("hackrf_open_board: hackrf_set_txvga_gain() failed: %s (%d)\n", hackrf_error_name(result), result);
//    print_usage();
    return(-1);
  }

  return(0);
}

inline int hackrf_run_board(hackrf_device* device) {
  int result;

	result = hackrf_stop_rx(device);
	if( result != HACKRF_SUCCESS ) {
		printf("run_board: hackrf_stop_rx() failed: %s (%d)\n", hackrf_error_name(result), result);
		return(-1);
	}
  
  result = hackrf_start_rx(device, hackrf_rx_callback, NULL);
  if( result != HACKRF_SUCCESS ) {
    printf("run_board: hackrf_start_rx() failed: %s (%d)\n", hackrf_error_name(result), result);
    return(-1);
  }

  return(0);
}

int hackrf_config_run_board(struct trx_cfg_op *trx) {
  hackrf_device *dev = NULL;
  uint64_t freq;
  int rate, bw;

  trx->dev = NULL;
  
	int result = hackrf_init();
	if( result != HACKRF_SUCCESS ) {
		fprintf(stderr,"hackrf_config_run_board: hackrf_init() failed: %s (%d)\n", hackrf_error_name(result), result);
		return(EXIT_FAILURE);
	}

	result = hackrf_open(&dev);
	if( result != HACKRF_SUCCESS ) {
		printf("hackrf_config_run_board: hackrf_open() failed: %s (%d)\n", hackrf_error_name(result), result);
		return(-1);
	}

  if (trx->tx.en) {
    freq = trx->tx.freq;
    rate = trx->tx.rate;
    bw   = trx->tx.bw;
  }
  else if (trx->rx.en) {
    freq = trx->rx.freq;
    rate = trx->rx.rate;
    bw   = trx->rx.bw;
  }
  else {
    printf("hackrf_config_run_board: trx->tx.en and trx->rx.en are both false!\n";
    return(-1);
  }
  result = hackrf_set_freq(dev, freq);
  if( result != HACKRF_SUCCESS ) {
    printf("hackrf_config_run_board: hackrf_set_freq() failed: %s (%d)\n", hackrf_error_name(result), result);
    return(-1);
  }

  result = hackrf_set_sample_rate(dev, rate);
  if( result != HACKRF_SUCCESS ) {
    printf("hackrf_config_run_board: hackrf_set_sample_rate() failed: %s (%d)\n", hackrf_error_name(result), result);
    return(-1);
  }
  
  result = hackrf_set_baseband_filter_bandwidth(dev, bw);
  if( result != HACKRF_SUCCESS ) {
    printf("hackrf_config_run_board: hackrf_set_baseband_filter_bandwidth() failed: %s (%d)\n", hackrf_error_name(result), result);
    return(-1);
  }
  
  if (trx->tx.en) {
    if (trx->tx.gain!=-1)
      result = hackrf_set_txvga_gain(dev, trx->tx.gain);
    else 
      result = hackrf_set_txvga_gain(dev, HACKRF_DEFAULT_TX_GAIN);
    if( result != HACKRF_SUCCESS ) {
      printf("hackrf_config_run_board: hackrf_set_txvga_gain() failed: %s (%d)\n", hackrf_error_name(result), result);
      return(-1);
    }

    result = hackrf_stop_tx(dev);
    if( result != HACKRF_SUCCESS ) {
      printf("hackrf_config_run_board: hackrf_stop_tx() failed: %s (%d)\n", hackrf_error_name(result), result);
      return(-1);
    }
    
    result = hackrf_start_tx(dev, hackrf_tx_callback, NULL);
    if( result != HACKRF_SUCCESS ) {
      printf("hackrf_config_run_board: hackrf_start_tx() failed: %s (%d)\n", hackrf_error_name(result), result);
      return(-1);
    }
  }

  if (trx->rx.en) {
    if (trx->rx.gain!=-1)
      result = hackrf_set_vga_gain(dev, trx->rx.gain);
    else
      result = hackrf_set_vga_gain(dev, HACKRF_DEFAULT_RX_GAIN);
    
    result |= hackrf_set_lna_gain(dev, HACKRF_MAX_LNA_GAIN);
    if( result != HACKRF_SUCCESS ) {
      printf("hackrf_config_run_board: hackrf_set_vga_gain() hackrf_set_lna_gain() failed: %s (%d)\n", hackrf_error_name(result), result);
      return(-1);
    }

    result = hackrf_stop_rx(dev);
    if( result != HACKRF_SUCCESS ) {
      printf("hackrf_config_run_board: hackrf_stop_rx() failed: %s (%d)\n", hackrf_error_name(result), result);
      return(-1);
    }
    
    result = hackrf_start_rx(dev, hackrf_rx_callback, NULL);
    if( result != HACKRF_SUCCESS ) {
      printf("hackrf_config_run_board: hackrf_start_rx() failed: %s (%d)\n", hackrf_error_name(result), result);
      return(-1);
    }
  }

  // set result to instance pointed by trx pointer
  trx->dev = dev;
  trx->hw_type = HACKRF;
  
  if (trx->tx.en) {
    if (trx->tx.gain==-1)
      trx->tx.gain = HACKRF_DEFAULT_TX_GAIN;
    
    trx->tx.update_freq = ;
    trx->tx.update_gain = ;
    trx->tx.update_rate = ;
    trx->tx.update_bw = ;
    trx->tx.proc_one_buf = ;
  }

  if (trx->rx.en) {
    if (trx->rx.gain==-1)
      trx->rx.gain = HACKRF_DEFAULT_RX_GAIN;

    trx->rx.update_freq = ;
    trx->rx.update_gain = ;
    trx->rx.update_rate = ;
    trx->rx.update_bw = ;
    trx->rx.proc_one_buf = ;
  }

  trx->stop_close = hackrf_stop_close_board;

  return(0);
}

int hackrf_stop_close_board(void* device, void *trx_input){
  struct trx_cfg_op *trx = (struct trx_cfg_op *)trx_input;
  hackrf_device *dev = (hackrf_device* )device;

  if (dev==NULL)
    return;

  if (trx->tx.en) {
    result = hackrf_stop_tx(dev);
    if( result != HACKRF_SUCCESS ) {
      printf("hackrf_stop_close_board: hackrf_stop_tx() failed: %s (%d)\n", hackrf_error_name(result), result);
      return(-1);
    }
  }
  
  if (trx->rx.en) {
    result = hackrf_stop_rx(dev);
    if( result != HACKRF_SUCCESS ) {
      printf("hackrf_stop_close_board: hackrf_stop_rx() failed: %s (%d)\n", hackrf_error_name(result), result);
      return(-1);
    }
  }

  result = hackrf_close(dev);
  if( result != HACKRF_SUCCESS )
  {
    printf("hackrf_stop_close_board: hackrf_close() failed: %s (%d)\n", hackrf_error_name(result), result);
    return(-1);
  }

  hackrf_exit();
  return(0);
}

//---------------------------FROM TX-------------

inline int hackrf_tx_one_buf(void *dev, char *buf, int length) {
  int result;

  hackrf_tx_len = buf;
  hackrf_tx_len = length;

  // open the board-----------------------------------------
  if (open_board() == -1) {
    printf("tx_one_buf: open_board() failed\n");
    return(-1);
  }

  // first round TX---------------------------------
  hackrf_stop_tx = 0;

  result = hackrf_start_tx(device, hackrf_tx_callback, NULL);
  if( result != HACKRF_SUCCESS ) {
    printf("tx_one_buf: hackrf_start_tx() failed: %s (%d)\n", hackrf_error_name(result), result);
    return(-1);
  }

  while( (hackrf_is_streaming(device) == HACKRF_TRUE) &&
      (do_exit == false) )
  {
    if (hackrf_stop_tx>=9) {
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

  // close the board---------------------------------------
  if (close_board() == -1) {
    printf("tx_one_buf: close_board() failed\n");
    return(-1);
  }

  do_exit = false;

  return(0);
}

#endif

