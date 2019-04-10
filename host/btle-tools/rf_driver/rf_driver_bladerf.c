#include "rf_driver_cfg.h"

#ifdef HAS_BLADERF
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

#include <libbladeRF.h>
#include "rf_driver_top.h"
#include "rf_driver_bladerf.h"
#include "../common_misc.h"

extern volatile bool do_exit;
extern void sigint_callback_handler(int signum);

void *bladerf_stream_callback(struct bladerf *dev, struct bladerf_stream *stream,
                      struct bladerf_metadata *metadata, void *samples,
                      size_t num_samples, void *user_data)
{
  struct rf_cfg_op *rx = (struct rf_cfg_op *)user_data;
  char *rx_buf = (char*)(rx->app_buf);
  int num_sample_app_buf = rx->num_sample_app_buf;
  int len_buf = 2*num_sample_app_buf;
  size_t i;
  int16_t *sample = (int16_t *)samples;

  if (num_samples>0) {
    pthread_mutex_lock(&(rx->callback_lock));
    for(i = 0; i < num_samples ; i++ ) {
        rx_buf[rx->app_buf_offset] = (((*sample)>>4)&0xFF);
        rx_buf[rx->app_buf_offset+1] = (((*(sample+1))>>4)&0xFF);
        rx->app_buf_offset = (rx->app_buf_offset+2)&( len_buf-1 ); //cyclic buffer

        sample += 2 ;
    }
    pthread_mutex_unlock(&(rx->callback_lock));
  }
  if (do_exit) {
      return NULL;
  } else {
      void *rv = ((int16_t**)(rf->dev_buf))[rx->dev_buf_idx];
      rx->dev_buf_idx = (rx->dev_buf_idx + 1) % rx->num_dev_buf;
      return rv ;
  }
}

void *bladerf_rx_task_run(void *tmp)
{
  struct rf_cfg_op *rx = (struct rf_cfg_op *)tmp;
  int status;

  /* Start stream and stay there until we kill the stream */
  status = bladerf_stream(rx->streamer, BLADERF_MODULE_RX);
  if (status < 0) {
    fprintf(stderr, "bladerf_rx_task_run: RX stream failure. %s\r\n", bladerf_strerror(status));
  }
  return NULL;
}

int bladerf_get_rx_sample(void *rf, void *buf, int *len) {
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

int bladerf_tx_one_buf(void *rf, void *buf, int *len) {
  struct rf_cfg_op *tx = (struct rf_cfg_op *)rf;
  IQ_TYPE *tx_buf = (IQ_TYPE*)buf;
  int status, i, num_sample_input = (*len);
  int16_t *bladerf_tx_buf = tx->dev_buf;
  int element_offset = (tx->num_sample_dev_buf-num_sample_input)*2;

  memset( (void *)bladerf_tx_buf, 0, element_offset*sizeof(int16_t) );

  for (i=element_offset; i<(tx->num_sample_dev_buf*2); i++) {
    bladerf_tx_buf[i] = ( (int)( tx_buf[i-element_offset] ) )*16;
  }

  // Transmit samples
  status = bladerf_sync_tx(tx->dev, (void *)bladerf_tx_buf, tx->num_sample_dev_buf, NULL, 10);
  if (status<0) {
    printf("bladerf_tx_one_buf: bladerf_sync_tx. %s\n", bladerf_strerror(status));
    return(status);
  }

  return(0);
}

int bladerf_update_tx_freq(void *rf_in, uint64_t freq_hz) {
  struct rf_cfg_op *rf = (struct rf_cfg_op *)rf_in;
  struct bladerf *dev = rf->dev;
  int status=-9999;
  uint64_t freq_hz_result;

  if (rf->en != TX_ENABLE){
    fprintf(stderr, "bladerf_update_tx_freq: rf->en is not correct!\n");
    return(status);
  }

  if (freq_hz!=-1) {
    if (rf->freq == freq_hz)
      return(0);
    else
      rf->freq = freq_hz;
  } else
    freq_hz = rf->freq;

  status = bladerf_set_frequency(dev, BLADERF_MODULE_TX, freq_hz);
  if (status<0) {
      fprintf(stderr, "bladerf_update_tx_freq: Failed to set. %s\n", bladerf_strerror(status));
      return(status);
  }

  status = bladerf_get_frequency(dev, BLADERF_MODULE_TX, &freq_hz_result);
  if (status<0) {
      fprintf(stderr, "bladerf_update_tx_freq: Failed to get. %s\n", bladerf_strerror(status));
      return(status);
  }

  if (freq_hz!=freq_hz_result) {
    rf->freq = freq_hz_result;
    fprintf(stderr, "bladerf_update_tx_freq: Actual %uul\n", freq_hz_result);
  }

  return(0);
}

int bladerf_update_rx_freq(void *rf_in, uint64_t freq_hz) {
  struct rf_cfg_op *rf = (struct rf_cfg_op *)rf_in;
  struct bladerf *dev = rf->dev;
  int status=-9999;
  uint64_t freq_hz_result;

  if (rf->en != RX_ENABLE){
    fprintf(stderr, "bladerf_update_rx_freq: rf->en is not correct!\n");
    return(status);
  }

  if (freq_hz!=-1) {
    if (rf->freq == freq_hz)
      return(0);
    else
      rf->freq = freq_hz;
  } else
    freq_hz = rf->freq;

  status = bladerf_set_frequency(dev, BLADERF_MODULE_RX, freq_hz);
  if (status<0) {
      fprintf(stderr, "bladerf_update_rx_freq: Failed to set. %s\n", bladerf_strerror(status));
      return(status);
  }

  status = bladerf_get_frequency(dev, BLADERF_MODULE_RX, &freq_hz_result);
  if (status<0) {
      fprintf(stderr, "bladerf_update_rx_freq: Failed to get. %s\n", bladerf_strerror(status));
      return(status);
  }

  if (freq_hz!=freq_hz_result) {
    rf->freq = freq_hz_result;
    fprintf(stderr, "bladerf_update_rx_freq: Actual %uul\n", freq_hz_result);
  }

  return(0);
}

int bladerf_update_tx_gain(void *rf_in, int gain_in) {
  struct rf_cfg_op *rf = (struct rf_cfg_op *)rf_in;
  struct bladerf *dev = rf->dev;
  int status=-9999, gain_result;

  if (rf->en != TX_ENABLE){
    fprintf(stderr, "bladerf_update_tx_gain: rf->en is not correct!\n");
    return(status);
  }

  if (gain_in!=-1) {
    if (rf->gain == gain_in)
      return(0);
    else
      rf->gain = gain_in;
  } else
    gain_in = rf->gain;

  status = bladerf_set_gain(dev, BLADERF_MODULE_TX, gain_in);
  if (status<0) {
      fprintf(stderr, "bladerf_update_tx_gain: Failed to set. %s\n", bladerf_strerror(status));
      return(status);
  }

  return(0);
}

int bladerf_update_rx_gain(void *rf_in, int gain_in) {
  struct rf_cfg_op *rf = (struct rf_cfg_op *)rf_in;
  struct bladerf *dev = rf->dev;
  int status=-9999, gain_result;

  if (rf->en != RX_ENABLE){
    fprintf(stderr, "bladerf_update_rx_gain: rf->en is not correct!\n");
    return(status);
  }

  if (gain_in!=-1) {
    if (rf->gain == gain_in)
      return(0);
    else
      rf->gain = gain_in;
  } else
    gain_in = rf->gain;

  status = bladerf_set_gain(dev, BLADERF_MODULE_RX, gain_in);
  if (status<0) {
      fprintf(stderr, "bladerf_update_rx_gain: Failed to set. %s\n", bladerf_strerror(status));
      return(status);
  }

  return(0);
}

int bladerf_update_tx_rate(void *rf_in, int rate) {
  struct rf_cfg_op *rf = (struct rf_cfg_op *)rf_in;
  struct bladerf *dev = rf->dev;
  int status=-9999;
  uint64_t rate_result;

  if (rf->en != TX_ENABLE){
    fprintf(stderr, "bladerf_update_tx_rate: rf->en is not correct!\n");
    return(status);
  }

  if (rate!=-1) {
    if (rf->rate == rate)
      return(0);
    else
      rf->rate = rate;
  } else
    rate = rf->rate;

  status = bladerf_set_sample_rate(dev, BLADERF_MODULE_TX, rate);
  if (status<0) {
      fprintf(stderr, "bladerf_update_tx_rate: Failed to set. %s\n", bladerf_strerror(status));
      return(status);
  }

  status = bladerf_get_sample_rate(dev, BLADERF_MODULE_TX, &rate_result);
  if (status<0) {
      fprintf(stderr, "bladerf_update_tx_rate: Failed to get. %s\n", bladerf_strerror(status));
      return(status);
  }

  if (rate!=rate_result) {
    rf->rate = rate_result;
    fprintf(stderr, "bladerf_update_tx_rate: Actual %d\n", rate_result);
  }

  return(0);
}

int bladerf_update_rx_rate(void *rf_in, int rate) {
  struct rf_cfg_op *rf = (struct rf_cfg_op *)rf_in;
  struct bladerf *dev = rf->dev;
  int status=-9999;
  uint64_t rate_result;

  if (rf->en != RX_ENABLE){
    fprintf(stderr, "bladerf_update_rx_rate: rf->en is not correct!\n");
    return(status);
  }

  if (rate!=-1) {
    if (rf->rate == rate)
      return(0);
    else
      rf->rate = rate;
  } else
    rate = rf->rate;

  status = bladerf_set_sample_rate(dev, BLADERF_MODULE_RX, rate);
  if (status<0) {
      fprintf(stderr, "bladerf_update_rx_rate: Failed to set. %s\n", bladerf_strerror(status));
      return(status);
  }

  status = bladerf_get_sample_rate(dev, BLADERF_MODULE_RX, &rate_result);
  if (status<0) {
      fprintf(stderr, "bladerf_update_rx_rate: Failed to get. %s\n", bladerf_strerror(status));
      return(status);
  }

  if (rate!=rate_result) {
    rf->rate = rate_result;
    fprintf(stderr, "bladerf_update_rx_rate: Actual %d\n", rate_result);
  }

  return(0);
}

int bladerf_update_tx_bw(void *rf_in, int bw) {
  struct rf_cfg_op *rf = (struct rf_cfg_op *)rf_in;
  struct bladerf *dev = rf->dev;
  int status=-9999;
  uint64_t bw_result;

  if (rf->en != TX_ENABLE){
    fprintf(stderr, "bladerf_update_tx_bw: rf->en is not correct!\n");
    return(status);
  }

  if (bw!=-1) {
    if (rf->bw == bw)
      return(0);
    else
      rf->bw = bw;
  } else
    bw = rf->bw;

  status = bladerf_set_bandwidth(dev, BLADERF_MODULE_TX, bw, &bw_result);
  if (status<0) {
      fprintf(stderr, "bladerf_update_tx_bw: Failed to set. %s\n", bladerf_strerror(status));
      return(status);
  }

  if (bw!=bw_result) {
    rf->bw = bw_result;
    fprintf(stderr, "bladerf_update_tx_bw: Actual %d\n", bw_result);
  }

  return(0);
}

int bladerf_update_rx_bw(void *rf_in, int bw) {
  struct rf_cfg_op *rf = (struct rf_cfg_op *)rf_in;
  struct bladerf *dev = rf->dev;
  int status=-9999;
  uint64_t bw_result;

  if (rf->en != TX_ENABLE){
    fprintf(stderr, "bladerf_update_rx_bw: rf->en is not correct!\n");
    return(status);
  }

  if (bw!=-1) {
    if (rf->bw == bw)
      return(0);
    else
      rf->bw = bw;
  } else
    bw = rf->bw;

  status = bladerf_set_bandwidth(dev, BLADERF_MODULE_RX, bw, &bw_result);
  if (status<0) {
      fprintf(stderr, "bladerf_update_rx_bw: Failed to set. %s\n", bladerf_strerror(status));
      return(status);
  }

  if (bw!=bw_result) {
    rf->bw = bw_result;
    fprintf(stderr, "bladerf_update_rx_bw: Actual %d\n", bw_result);
  }

  return(0);
}

void bladerf_stop_close_board(void *tmp){
  struct trx_cfg_op *trx = (struct trx_cfg_op *)tmp;
  int status=-9999, i;
  struct bladerf *dev = NULL;

  fprintf(stderr, "bladerf_stop_close_board...\n");

  if (trx->rx.en == RX_ENABLE) {
    pthread_join(trx->rx.tid, NULL);
    fprintf(stderr,"bladerf_stop_close_board: pthread_join(trx->rx.tid, NULL)\n");
    if (trx->rx.app_buf)
      free(trx->rx.app_buf);
    if (trx->rx.dev_buf) {
      for (i=0;i<trx->rx.num_dev_buf;i++) {
        int16_t* sub_buf = (int16_t*)((int16_t**)(trx->rx.dev_buf))[i];
        if (sub_buf)
          free(sub_buf);
      }
      free(trx->rx.dev_buf);
    }
    dev = trx->rx.dev;
  }

  if (trx->tx.en == TX_ENABLE) {
    if (trx->tx.app_buf)
      free(trx->tx.app_buf);
    if (trx->tx.dev_buf)
      free(trx->tx.dev_buf);
    dev = trx->tx.dev;
  }

  if (dev==NULL)
    return;

  if (trx->rx.en == RX_ENABLE) {
    bladerf_deinit_stream(trx->rx.streamer);
    printf("bladerf_stop_close_board: bladerf_deinit_stream(trx->rx.streamer)\n");

    status = bladerf_enable_module(dev, BLADERF_MODULE_RX, false);
    if (status<0)
        fprintf(stderr, "bladerf_stop_close_board: Failed to disable module BLADERF_MODULE_RX. %s\n",bladerf_strerror(status));
    else
      fprintf(stdout, "bladerf_stop_close_board: disable module BLADERF_MODULE_RX. %s\n", bladerf_strerror(status));
  }

  if (trx->tx.en == TX_ENABLE) {
    status = bladerf_enable_module(dev, BLADERF_MODULE_TX, false);
    if (status<0) {
        fprintf(stderr, "bladerf_stop_close_board: Failed to disable module BLADERF_MODULE_TX. %s\n", bladerf_strerror(status));
    } else {
      fprintf(stdout, "bladerf_stop_close_board: disable module BLADERF_MODULE_TX. %s\n", bladerf_strerror(status));
    }
  }

  bladerf_close(dev);
  printf("bladerf_stop_close_board: bladerf_close.\n");
}

int bladerf_config_run_board(struct trx_cfg_op *trx) {
  int status=-9999, i, j;
  unsigned int actual;
  struct bladerf *dev = NULL;
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
      trx->tx.freq = BLADERF_DEFAULT_TX_FREQ;
    if (trx->tx.gain==-1)
      trx->tx.gain = BLADERF_DEFAULT_TX_GAIN;
    if (trx->tx.rate==-1)
      trx->tx.rate = BLADERF_DEFAULT_TX_RATE;
    if (trx->tx.bw==-1)
      trx->tx.bw = BLADERF_DEFAULT_TX_BW;
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
      trx->rx.freq = BLADERF_DEFAULT_RX_FREQ;
    if (trx->rx.gain==-1)
      trx->rx.gain = BLADERF_DEFAULT_RX_GAIN;
    if (trx->rx.rate==-1)
      trx->rx.rate = BLADERF_DEFAULT_RX_RATE;
    if (trx->rx.bw==-1)
      trx->rx.bw = BLADERF_DEFAULT_RX_BW;
  }

  status = bladerf_open(&dev, NULL);
  if (status<0) {
      fprintf(stderr, "bladerf_config_run_board: Failed to open device. %s\n", bladerf_strerror(status));
      return EXIT_FAILURE;
  } else 
    fprintf(stdout, "bladerf_config_run_board: open device. %s\n", bladerf_strerror(status));
  
  status = bladerf_is_fpga_configured(dev);
  if (status<0) {
      fprintf(stderr, "bladerf_config_run_board: Failed to determine FPGA state. %s\n", bladerf_strerror(status));
      return EXIT_FAILURE;
  } else if (status == 0) {
      fprintf(stderr, "bladerf_config_run_board: Error: FPGA is not loaded.\n");
      goto fail_out;
  } else  {
    fprintf(stdout, "bladerf_config_run_board: FPGA is loaded.\n");
  }
  
  if (trx->tx.en==TX_ENABLE) {
    if ( (status=bladerf_update_tx_freq(&(trx->tx),-1))<0 )
      goto fail_out;
    if ( (status=bladerf_update_tx_rate(&(trx->tx),-1))<0 )
      goto fail_out;
    if ( (status=bladerf_update_tx_bw(&(trx->tx),-1))<0 )
      goto fail_out;
    if ( (status=bladerf_update_tx_gain(&(trx->tx),-1))<0 )
      goto fail_out;

    trx->tx.dev_buf = malloc(trx->tx.num_sample_dev_buf * 2 * sizeof(int16_t)); // 2 for I and Q
    if(trx->tx.dev_buf==NULL){
      fprintf(stderr, "bladerf_config_run_board: trx->tx.dev_buf==NULL\n");
      goto fail_out;
    }
    status = bladerf_sync_config( dev,
                                  BLADERF_MODULE_TX,
                                  BLADERF_FORMAT_SC16_Q11,
                                  32,
                                  trx->tx.num_sample_dev_buf,
                                  16,
                                  10);

    if (status < 0) {
        fprintf(stderr, "bladerf_config_run_board: Failed to initialize TX sync handle. %s\n", bladerf_strerror(status));
        goto fail_out;
    }

    status = bladerf_enable_module(dev, BLADERF_MODULE_TX, true);
    if (status < 0) {
        fprintf(stderr, "bladerf_config_run_board: Failed to enable module. %s\n", bladerf_strerror(status));
        goto fail_out;
    }

  }

  if (trx->rx.en==RX_ENABLE) {
    if ( (status=bladerf_update_rx_freq(&(trx->rx),-1))<0 )
      goto fail_out;
    if ( (status=bladerf_update_rx_rate(&(trx->rx),-1))<0 )
      goto fail_out;
    if ( (status=bladerf_update_rx_bw(&(trx->rx),-1))<0 )
      goto fail_out;
    if ( (status=bladerf_update_rx_gain(&(trx->rx),-1))<0 )
      goto fail_out;
  
#if 0 // old version do not have this API
  status = bladerf_get_gain(dev, BLADERF_MODULE_RX, &actual);
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
    trx->rx.app_buf = malloc(num_sample_app_buf_total * 2 * sizeof(IQ_TYPE)); // 2 for I and Q
    if(trx->rx.app_buf==NULL){
      fprintf(stderr, "bladerf_config_run_board: trx->rx.app_buf==NULL\n");
      goto fail_out;
    }

    trx->rx.dev_buf = (int16_t **)malloc(trx->rx.num_dev_buf * sizeof(int16_t *));
    if (trx->rx.dev_buf == NULL) {
      status = -9999;
      goto fail_out;
    }

    for (i=0; i<trx->rx.num_dev_buf; i++) {
      ((int16_t **)(trx->rx.dev_buf))[i] = (int16_t *)malloc( trx->rx.num_sample_dev_buf * 2* sizeof(int16_t));
      if (((int16_t **)(trx->rx.dev_buf))[i] == NULL) {
        for (j=i-1; j>=0; j--) {
          free(((int16_t **)(trx->rx.dev_buf))[i]);
        }
        status = -9999;
        goto fail_out;
      }
    }

    /* Initialize the stream */
    status = bladerf_init_stream(
                &(trx->rx.streamer),
                dev,
                bladerf_stream_callback,
                &(trx->rx.dev_buf),
                trx->rx.num_dev_buf,
                BLADERF_FORMAT_SC16_Q11,
                trx->rx.num_sample_dev_buf,
                trx->rx.num_dev_buf,
                &(trx->rx)
              );
    if (status<0) {
        fprintf(stderr, "bladerf_config_run_board: Failed to init rx stream. %s\n", bladerf_strerror(status));
        goto fail_out;
    }

    bladerf_set_stream_timeout(dev, BLADERF_MODULE_RX, 100);

    status = bladerf_enable_module(dev, BLADERF_MODULE_RX, true);
    if (status < 0) {
        fprintf(stderr, "bladerf_config_run_board: Failed to enable module. %s\n", bladerf_strerror(status));
        bladerf_deinit_stream(trx->rx.streamer);
        goto fail_out;
    }

    status = pthread_create(&trx->rx.tid, NULL, bladerf_rx_task_run, NULL);
    if (status < 0) {
        bladerf_deinit_stream(trx->rx.streamer);
        goto fail_out;
    }
  }
  // set result to instance pointed by trx pointer

  trx->board = BLADERF;
  trx->stop_close = bladerf_stop_close_board;
  
  if (trx->tx.en==TX_ENABLE) {
    trx->tx.dev = dev;
    trx->tx.update_freq =  bladerf_update_tx_freq;
    trx->tx.update_gain =  bladerf_update_tx_gain;
    trx->tx.update_rate =  bladerf_update_tx_rate;
    trx->tx.update_bw =    bladerf_update_tx_bw;
    trx->tx.proc_one_buf = bladerf_tx_one_buf;
  }

  if (trx->rx.en==RX_ENABLE) {
    trx->rx.dev = dev;
    trx->rx.update_freq =  bladerf_update_rx_freq;
    trx->rx.update_gain =  bladerf_update_rx_gain;
    trx->rx.update_rate =  bladerf_update_rx_rate;
    trx->rx.update_bw =    bladerf_update_rx_bw;
    trx->rx.proc_one_buf = bladerf_get_rx_sample;
  }

  return(0);

fail_out:
  fprintf(stderr, "bladerf_config_run_board: failed with %s\n", bladerf_strerror(status));
  if (dev!=NULL)
    bladerf_close(dev);

  return(-1);
}

#endif
