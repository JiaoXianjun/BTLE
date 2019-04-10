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

extern volatile bool do_exit;
extern void sigint_callback_handler(int signum);
static int hackrf_stop_tx_internal;

int hackrf_tx_callback(hackrf_transfer* transfer) {
  struct rf_cfg_op *tx = (struct rf_cfg_op *)tranfer->tx_ctx;
  int size_left;
  if (hackrf_stop_tx_internal == 0) {
    memset(transfer->buffer, 0, HACKRF_NUM_PRE_SEND_DATA);
    memcpy(transfer->buffer+HACKRF_NUM_PRE_SEND_DATA, (char *)(tx->app_buf), tx->num_sample_app_buf);

    size_left = (transfer->valid_length - tx->num_sample_app_buf - HACKRF_NUM_PRE_SEND_DATA);
    memset(transfer->buffer+HACKRF_NUM_PRE_SEND_DATA+tx->num_sample_app_buf, 0, size_left);
  } else {
    memset(transfer->buffer, 0, transfer->valid_length);
  }
  hackrf_stop_tx_internal++;
 
  return(0);
}

int hackrf_rx_callback(hackrf_transfer* transfer) {
  struct rf_cfg_op *rx = (struct rf_cfg_op *)tranfer->rx_ctx;
  int i;
  int8_t *p = (int8_t *)transfer->buffer;
  char *rx_buf = (char*)(rx->app_buf);
  int num_sample_app_buf = rx->num_sample_app_buf;
  int len_buf = 2*num_sample_app_buf;
  if (transfer->valid_length>0) {
    pthread_mutex_lock(&(rx->callback_lock));
    for( i=0; i<transfer->valid_length; i++) {
      rx_buf[rx->app_buf_offset] = p[i];
      rx->app_buf_offset = (rx->app_buf_offset+1)&( len_buf-1 ); //cyclic buffer
    }
    pthread_mutex_unlock(&(rx->callback_lock));
  }
  //printf("%d\n", transfer->valid_length); // !!!!it is 262144 always!!!! Now it is 4096. Defined in hackrf.c lib_device->buffer_size
  return(0);
}

int hackrf_get_rx_sample(void *rf, void *buf, int *len) {
  static phase = 0;
  int rx_buf_offset_tmp;
  int sample_ready_flag = 0;
  IQ_TYPE *rxp;
  struct rf_cfg_op *rx = (struct rf_cfg_op *)rf;
  char *rx_buf = (char*)(rx->app_buf);
  int num_sample_app_buf = rx->num_sample_app_buf;
  int num_sample_app_buf_tail = rx->num_sample_app_buf_tail;
  int len_buf = 2*num_sample_app_buf;

  rx_buf_offset_tmp = rx->app_buf_offset - num_sample_app_buf_tail;
  // cross point 0
  if (rx_buf_offset_tmp>=0 && rx_buf_offset_tmp<num_sample_app_buf && phase==1) {
    phase = 0;
    memcpy((void *)(rx_buf+len_buf), (void *)rx_buf, num_sample_app_buf_tail*sizeof(IQ_TYPE));
    rxp = (IQ_TYPE*)(rx_buf + num_sample_app_buf);
    sample_ready_flag = 1;
  }

  // cross point 1
  if (rx_buf_offset_tmp>=num_sample_app_buf && phase==0) {
    phase = 1;
    rxp = (IQ_TYPE*)rx_buf;
    sample_ready_flag = 1;
  }

  (*((IQ_TYPE**)buf)) = rxp;

  return(sample_ready_flag);
}

int hackrf_tx_one_buf(void *rf, void *buf, int *len) {
  struct rf_cfg_op *tx = (struct rf_cfg_op *)rf;
  int result;
  hackrf_device *device = tx->dev;

  tx->num_sample_app_buf = (*len);
  tx->app_buf = buf;
#if 0
  // open the board-----------------------------------------
  if (open_board() == -1) {
    printf("tx_one_buf: open_board() failed\n");
    return(-1);
  }
#endif
  // first round TX---------------------------------
  hackrf_stop_tx_internal = 0;

  result = hackrf_start_tx(device, hackrf_tx_callback, tx);
  if( result != HACKRF_SUCCESS ) {
    fprintf(stderr, "hackrf_tx_one_buf: hackrf_start_tx failed. %s (%d)\n", hackrf_error_name(result), result);
    return(result);
  }

  while( (hackrf_is_streaming(device) == HACKRF_TRUE) && (do_exit == false) ) {
    if (hackrf_stop_tx_internal>=9)
      break;
  }

  if (do_exit)
  {
    fprintf(stderr,"\hackrf_tx_one_buf: Exiting...\n");
    return(-1);
  }
#if 0
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
#endif

  do_exit = false;

  return(0);
}

int hackrf_update_tx_freq(void *rf_in, uint64_t freq_hz) {
  struct rf_cfg_op *rf = (struct rf_cfg_op *)rf_in;
  struct hackrf_device *dev = rf->dev;
  int result;
  
  if (rf->en != TX_ENABLE){
    fprintf(stderr, "hackrf_update_tx_freq: rf->en is not correct!\n");
    return(status);
  }

  if (freq_hz!=-1) {
    if (rf->freq == freq_hz)
      return(HACKRF_SUCCESS);
    else
      rf->freq = freq_hz;
  } else
    freq_hz = rf->freq;

  result = hackrf_set_freq(dev,freq_hz);
  if( result != HACKRF_SUCCESS ) {
    fprintf(stderr,"hackrf_update_tx_freq: hackrf_set_freq() failed. %s (%d)\n", hackrf_error_name(result), result);
    return(result);
  }

  return(HACKRF_SUCCESS);
}

int hackrf_update_rx_freq(void *rf_in, uint64_t freq_hz) {
  struct rf_cfg_op *rf = (struct rf_cfg_op *)rf_in;
  struct hackrf_device *dev = rf->dev;
  int result;
  
  if (rf->en != RX_ENABLE){
    fprintf(stderr, "hackrf_update_rx_freq: rf->en is not correct!\n");
    return(status);
  }

  if (freq_hz!=-1) {
    if (rf->freq == freq_hz)
      return(HACKRF_SUCCESS);
    else
      rf->freq = freq_hz;
  } else
    freq_hz = rf->freq;

  result = hackrf_set_freq(dev,freq_hz);
  if( result != HACKRF_SUCCESS ) {
    fprintf(stderr,"hackrf_update_rx_freq: hackrf_set_freq() failed. %s (%d)\n", hackrf_error_name(result), result);
    return(result);
  }

  return(HACKRF_SUCCESS);
}

int hackrf_update_tx_gain(void *rf_in, int gain_in) {
  struct rf_cfg_op *rf = (struct rf_cfg_op *)rf_in;
  struct hackrf_device *dev = rf->dev;
  int result;

  if (rf->en != TX_ENABLE){
    fprintf(stderr, "hackrf_update_tx_gain: rf->en is not correct!\n");
    return(status);
  }

  if (gain_in!=-1) {
    if (rf->gain == gain_in)
      return(HACKRF_SUCCESS);
    else
      rf->gain = gain_in;
  } else
    gain_in = rf->gain;

  result = hackrf_set_txvga_gain(dev,gain_in);
  if( result != HACKRF_SUCCESS ) {
    fprintf(stderr,"hackrf_update_tx_gain: hackrf_set_txvga_gain() failed. %s (%d)\n", hackrf_error_name(result), result);
    return(result);
  }
  
  return(HACKRF_SUCCESS);
}

int hackrf_update_rx_gain(void *rf_in, int gain_in) {
  struct rf_cfg_op *rf = (struct rf_cfg_op *)rf_in;
  struct hackrf_device *dev = rf->dev;
  int result;

  if (rf->en != RX_ENABLE){
    fprintf(stderr, "hackrf_update_rx_gain: rf->en is not correct!\n");
    return(status);
  }

  if (gain_in!=-1) {
    if (rf->gain == gain_in)
      return(HACKRF_SUCCESS);
    else
      rf->gain = gain_in;
  } else
    gain_in = rf->gain;

  result = hackrf_set_vga_gain(dev, gain_in);
  if( result != HACKRF_SUCCESS ) {
    fprintf(stderr,"hackrf_update_rx_gain: hackrf_set_vga_gain() failed. %s (%d)\n", hackrf_error_name(result), result);
    return(result);
  }
  
  return(HACKRF_SUCCESS);
}

int hackrf_update_tx_rate(void *rf_in, int rate) {
  struct rf_cfg_op *rf = (struct rf_cfg_op *)rf_in;
  struct hackrf_device *dev = rf->dev;
  int result;
  
  if (rf->en != TX_ENABLE){
    fprintf(stderr, "hackrf_update_tx_rate: rf->en is not correct!\n");
    return(status);
  }

  if (rate!=-1) {
    if (rf->rate == rate)
      return(HACKRF_SUCCESS);
    else
      rf->rate = rate;
  } else
    rate = rf->rate;

  result = hackrf_set_sample_rate(dev, rate);
  if( result != HACKRF_SUCCESS ) {
    fprintf(stderr,"hackrf_update_tx_rate: hackrf_set_sample_rate() failed. %s (%d)\n", hackrf_error_name(result), result);
    return(result);
  } 

  return(HACKRF_SUCCESS);
}

int hackrf_update_rx_rate(void *rf_in, int rate) {
  struct rf_cfg_op *rf = (struct rf_cfg_op *)rf_in;
  struct hackrf_device *dev = rf->dev;
  int result;
  
  if (rf->en != RX_ENABLE){
    fprintf(stderr, "hackrf_update_rx_rate: rf->en is not correct!\n");
    return(status);
  }

  if (rate!=-1) {
    if (rf->rate == rate)
      return(HACKRF_SUCCESS);
    else
      rf->rate = rate;
  } else
    rate = rf->rate;

  result = hackrf_set_sample_rate(dev, rate);
  if( result != HACKRF_SUCCESS ) {
    fprintf(stderr,"hackrf_update_rx_rate: hackrf_set_sample_rate() failed. %s (%d)\n", hackrf_error_name(result), result);
    return(result);
  } 
  
  return(HACKRF_SUCCESS);
}

int hackrf_update_tx_bw(void *rf_in, int bw) {
  struct rf_cfg_op *rf = (struct rf_cfg_op *)rf_in;
  struct hackrf_device *dev = rf->dev;
  int result;
  
  if (rf->en != TX_ENABLE){
    fprintf(stderr, "hackrf_update_tx_bw: rf->en is not correct!\n");
    return(status);
  }

  if (bw!=-1) {
    if (rf->bw == bw)
      return(HACKRF_SUCCESS);
    else
      rf->bw = bw;
  } else
    bw = rf->bw;

  result = hackrf_set_baseband_filter_bandwidth(dev, bw);
  if( result != HACKRF_SUCCESS ) {
    fprintf(stderr,"hackrf_update_tx_bw: hackrf_set_baseband_filter_bandwidth() failed. %s (%d)\n", hackrf_error_name(result), result);
    return(result);
  }

  return(HACKRF_SUCCESS);
}

int hackrf_update_rx_bw(void *rf_in, int bw) {
  struct rf_cfg_op *rf = (struct rf_cfg_op *)rf_in;
  struct hackrf_device *dev = rf->dev;
  int result;
  
  if (rf->en != RX_ENABLE){
    fprintf(stderr, "hackrf_update_rx_bw: rf->en is not correct!\n");
    return(status);
  }

  if (bw!=-1) {
    if (rf->bw == bw)
      return(HACKRF_SUCCESS);
    else
      rf->bw = bw;
  } else
    bw = rf->bw;

  result = hackrf_set_baseband_filter_bandwidth(dev, bw);
  if( result != HACKRF_SUCCESS ) {
    fprintf(stderr,"hackrf_update_rx_bw: hackrf_set_baseband_filter_bandwidth() failed. %s (%d)\n", hackrf_error_name(result), result);
    return(result);
  }
  
  return(HACKRF_SUCCESS);
}

int hackrf_stop_close_board(void *tmp){
  struct trx_cfg_op *trx = (struct trx_cfg_op *)tmp;
  struct hackrf_device *dev = NULL;;

  if (trx->rx.en == RX_ENABLE) {
    dev = trx->rx.dev;
    if (trx->rx.app_buf)
      free(trx->rx.app_buf);
    result = hackrf_stop_rx(dev);
    if( result != HACKRF_SUCCESS ) {
      printf("hackrf_stop_close_board: hackrf_stop_rx() failed. %s (%d)\n", hackrf_error_name(result), result);
//      return(result);
    }
  }

  if (trx->tx.en == TX_ENABLE) {
    dev = trx->tx.dev;
    result = hackrf_stop_tx(dev);
    if( result != HACKRF_SUCCESS ) {
      printf("hackrf_stop_close_board: hackrf_stop_tx() failed. %s (%d)\n", hackrf_error_name(result), result);
      //return(-1);
    }
  }

  if (dev==NULL)
    return;

  result = hackrf_close(dev);
  if( result != HACKRF_SUCCESS )
  {
    printf("hackrf_stop_close_board: hackrf_close() failed. %s (%d)\n", hackrf_error_name(result), result);
    //return(-1);
  }

  hackrf_exit();
  return(0);
}

int hackrf_config_run_board(struct trx_cfg_op *trx) {
  struct hackrf_device *dev = NULL;
  int num_sample_app_buf_total;

  if (trx->tx.en==TX_ENABLE) {
    trx->tx.app_buf = NULL;
    trx->tx.dev_buf = NULL;
    trx->tx.streamer = NULL;
    trx->tx.metadata = NULL;
    trx->tx.dev = NULL;
    trx->tx.app_buf_offset = 0;
    trx->tx.dev_buf_idx = 0;
    
    if (trx->tx.freq==-1)
      trx->tx.freq = HACKRF_DEFAULT_TX_FREQ;
    if (trx->tx.gain==-1)
      trx->tx.gain = HACKRF_DEFAULT_TX_GAIN;
    if (trx->tx.rate==-1)
      trx->tx.rate = HACKRF_DEFAULT_TX_RATE;
    if (trx->tx.bw==-1)
      trx->tx.bw = HACKRF_DEFAULT_TX_BW;
  }

  if (trx->rx.en==RX_ENABLE) {
    trx->rx.app_buf = NULL;
    trx->rx.dev_buf = NULL;
    trx->rx.streamer = NULL;
    trx->rx.metadata = NULL;
    trx->rx.dev = NULL;
    trx->rx.app_buf_offset = 0;
    trx->rx.dev_buf_idx = 0;

    num_sample_app_buf_total = 2*(trx->rx.num_sample_app_buf) + trx->rx.num_sample_app_buf_tail;

    if (trx->rx.freq==-1)
      trx->rx.freq = HACKRF_DEFAULT_RX_FREQ;
    if (trx->rx.gain==-1)
      trx->rx.gain = HACKRF_DEFAULT_RX_GAIN;
    if (trx->rx.rate==-1)
      trx->rx.rate = HACKRF_DEFAULT_RX_RATE;
    if (trx->rx.bw==-1)
      trx->rx.bw = HACKRF_DEFAULT_RX_BW;
  }

	int result = hackrf_init();
	if( result != HACKRF_SUCCESS ) {
		fprintf(stderr,"hackrf_config_run_board: hackrf_init() failed. %s (%d)\n", hackrf_error_name(result), result);
		return(result);
	}

	result = hackrf_open(&dev);
	if( result != HACKRF_SUCCESS ) {
		printf("hackrf_config_run_board: hackrf_open() failed. %s (%d)\n", hackrf_error_name(result), result);
		return(result);
	}

  if (trx->tx.en==TX_ENABLE) {
    if ( (result=hackrf_update_tx_freq(&(trx->tx),-1)) )
      goto fail_out;
    if ( (result=hackrf_update_tx_rate(&(trx->tx),-1)) )
      goto fail_out;
    if ( (result=hackrf_update_tx_bw(&(trx->tx),-1)) )
      goto fail_out;
    if ( (result=hackrf_update_tx_gain(&(trx->tx),-1)) )
      goto fail_out;

    result = hackrf_stop_tx(dev);
    if( result != HACKRF_SUCCESS ) {
      printf("hackrf_config_run_board: hackrf_stop_tx() failed. %s (%d)\n", hackrf_error_name(result), result);
      goto fail_out;
    }
    
    result = hackrf_start_tx(dev, hackrf_tx_callback, trx->tx);
    if( result != HACKRF_SUCCESS ) {
      printf("hackrf_config_run_board: hackrf_start_tx() failed. %s (%d)\n", hackrf_error_name(result), result);
      goto fail_out;
    }
  }

  if (trx->rx.en==RX_ENABLE) {
    if ( (result=hackrf_update_tx_freq(&(trx->tx),-1)) )
      goto fail_out;
    if ( (result=hackrf_update_tx_rate(&(trx->tx),-1)) )
      goto fail_out;
    if ( (result=hackrf_update_tx_bw(&(trx->tx),-1)) )
      goto fail_out;
    if ( (result=hackrf_update_tx_gain(&(trx->tx),-1)) )
      goto fail_out;

    trx->rx.app_buf = malloc(num_sample_app_buf_total * 2 * sizeof(IQ_TYPE)); // 2 for I and Q
    if(trx->rx.app_buf==NULL){
      fprintf(stderr, "hackrf_config_run_board: trx->rx.app_buf==NULL\n");
      goto fail_out;
    }

    result = hackrf_stop_rx(dev);
    if( result != HACKRF_SUCCESS ) {
      printf("hackrf_config_run_board: hackrf_stop_rx() failed. %s (%d)\n", hackrf_error_name(result), result);
      goto fail_out;
    }
    
    result = hackrf_start_rx(dev, hackrf_rx_callback, NULL);
    if( result != HACKRF_SUCCESS ) {
      printf("hackrf_config_run_board: hackrf_start_rx() failed. %s (%d)\n", hackrf_error_name(result), result);
      goto fail_out;
    }
  }

  // set result to instance pointed by trx pointer
  trx->board = HACKRF;
  trx->stop_close = hackrf_stop_close_board;
  
  if (trx->tx.en==TX_ENABLE) {
    trx->tx.dev = dev;
    trx->tx.update_freq =  hackrf_update_tx_freq;
    trx->tx.update_gain =  hackrf_update_tx_gain;
    trx->tx.update_rate =  hackrf_update_tx_rate;
    trx->tx.update_bw =    hackrf_update_tx_bw;
    trx->tx.proc_one_buf = hackrf_tx_one_buf;
  }

  if (trx->rx.en==RX_ENABLE) {
    trx->rx.dev = dev;
    trx->rx.update_freq =  hackrf_update_rx_freq;
    trx->rx.update_gain =  hackrf_update_rx_gain;
    trx->rx.update_rate =  hackrf_update_rx_rate;
    trx->rx.update_bw =    hackrf_update_rx_bw;
    trx->rx.proc_one_buf = hackrf_get_rx_sample;
  }

  return(0);

fail_out:
  fprintf(stderr, "hackrf_config_run_board: failed with: %s (%d)\n", hackrf_error_name(result), result);
  if (dev!=NULL) {
    hackrf_stop_tx(dev);
    hackrf_stop_rx(dev);
    hackrf_close(dev);
    hackrf_exit();
  }

}

#endif

