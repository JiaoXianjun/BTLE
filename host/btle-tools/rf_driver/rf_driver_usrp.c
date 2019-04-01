#include "rf_driver_cfg.h"

#ifdef HAS_UHD
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

#include <uhd.h>
#include "rf_driver_usrp.h"
#include "../common_misc.h"

extern volatile bool do_exit;
extern void sigint_callback_handler(int signum);

static char usrp_error_string[512];

void *usrp_rx_task_run(void *tmp)
{
  int i;
  size_t num_rx_samps = 0;
  uhd_rx_metadata_error_code_t error_code;
  struct rf_cfg_op *rx = (struct rf_cfg_op *)tmp;
  char *rx_buf = (char*)(rx->app_buf);
  
  fprintf(stderr, "usrp_rx_task_run...\n");
      
  while (!do_exit) {
    uhd_rx_streamer_recv(rx->streamer, (void**)&(rx->dev_buf), rx->num_sample_dev_buf, rx->metadata, 3.0, false, &num_rx_samps);
    //fprintf(stderr, "usrp_rx_task_run: %d %d %d\n", num_rx_samps, LEN_BUF, rx_buf_offset);
    if (uhd_rx_metadata_error_code(*(rx->metadata), &error_code) ) {
      fprintf(stderr, "usrp_rx_task_run: uhd_rx_metadata_error_code return error. Aborting.\n");
      return(NULL);
    }

    if(error_code != UHD_RX_METADATA_ERROR_CODE_NONE){
        fprintf(stderr, "usrp_rx_task_run: Error code 0x%x was returned during streaming. Aborting.\n", error_code);
        return(NULL);
    }

    if (num_rx_samps>0) {
      pthread_mutex_lock(&(rx->callback_lock));
      // Handle data
      int16_t *usrp_rx_buff = (int16_t*)(rx->dev_buf);
      for(i = 0; i < (2*num_rx_samps) ; i=i+2 ) {
          rx_buf[rx->app_buf_offset] =   ( ( (*(usrp_rx_buff+i)  )>>8)&0xFF );
          rx_buf[rx->app_buf_offset+1] = ( ( (*(usrp_rx_buff+i+1))>>8)&0xFF );
          rx->app_buf_offset = (rx->app_buf_offset+2)&( LEN_BUF-1 ); //cyclic buffer
      }
      pthread_mutex_unlock(&(rx->callback_lock));
    }
  }
  fprintf(stderr, "usrp_rx_task_run quit.\n");
  return(NULL);
}

int usrp_get_rx_sample(void *dev, void *buf, int *len) {
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

void usrp_stop_close_board(void *dev, bool trx_flag){
  fprintf(stderr, "usrp_stop_close_board...\n");
  
  pthread_join(usrp_rx_task, NULL);
  //pthread_cancel(usrp_rx_task);
  fprintf(stderr,"usrp_stop_close_board: USRP rx thread quit.\n");

  free(usrp_rx_buff);
  free(usrp_tx_buff);

  if (dev==NULL)
    return;

  fprintf(stderr, "usrp_stop_close_board: Cleaning up RX streamer.\n");
  uhd_rx_streamer_free(&usrp_rx_streamer);

  fprintf(stderr, "usrp_stop_close_board: Cleaning up RX metadata.\n");
  uhd_rx_metadata_free(&usrp_md);

  uhd_usrp_last_error(dev, usrp_error_string, 512);
  fprintf(stderr, "usrp_stop_close_board: USRP reported the following error: %s\n", usrp_error_string);

  uhd_usrp_free((struct uhd_usrp **)(&dev));
}

int usrp_tune_rx(void *dev, uint64_t freq_hz) {
  int status;

  usrp_tune_request.target_freq = freq_hz;
  status = uhd_usrp_set_rx_freq((uhd_usrp_handle)dev, &usrp_tune_request, 0, &usrp_tune_result);
  if (status) {
    uhd_usrp_last_error((uhd_usrp_handle)dev, usrp_error_string, 512);
    fprintf(stderr, "usrp_tune_rx: USRP reported the following error: %s\n", usrp_error_string);
    usrp_stop_close_board(dev);
    return EXIT_FAILURE;
  }

  return(0);
}

int usrp_tune_tx(void *dev, uint64_t freq_hz) {
  int status;

  usrp_tune_request.target_freq = freq_hz;
  status = uhd_usrp_set_tx_freq((uhd_usrp_handle)dev, &usrp_tune_request, 0, &usrp_tune_result);
  if (status) {
    uhd_usrp_last_error((uhd_usrp_handle)dev, usrp_error_string, 512);
    fprintf(stderr, "usrp_tune_tx: USRP reported the following error: %s\n", usrp_error_string);
    usrp_stop_close_board(dev);
    return EXIT_FAILURE;
  }

  return(0);
}

inline int usrp_config_run_board(struct trx_cfg_op *trx) {
  uhd_usrp_handle usrp = NULL;
  size_t channel = 0;
  uhd_error status;
  double rate, bw, gain;
  uhd_stream_args_t stream_args = {
      .cpu_format = "sc16",
      .otw_format = "sc16",
      .args = "",
      .channel_list = &channel,
      .n_channels = 1
  };

  uhd_stream_cmd_t stream_cmd = {
      .stream_mode = UHD_STREAM_MODE_START_CONTINUOUS,
      .num_samps = LEN_BUF/2,
      .stream_now = true
  };
  
  trx->dev = NULL;

  usrp_tune_request.rf_freq_policy = UHD_TUNE_REQUEST_POLICY_AUTO;
  usrp_tune_request.dsp_freq_policy = UHD_TUNE_REQUEST_POLICY_AUTO;

  fprintf(stderr, "usrp_config_run_board: Creating USRP with args \"%s\"...\n", trx->device_args);

  // Create USRP
  if ( (status = uhd_usrp_make(&usrp, device_args)) )
    goto fail_out;

  if (trx->rx.en) {
    // Create RX streamer
    if ( (status = uhd_rx_streamer_make(&usrp_rx_streamer)) ) 
      goto fail_out;

    // Create RX metadata
    if ( (status = uhd_rx_metadata_make(&usrp_md)) )
      goto fail_out;

    // Set rate
    rate = trx->rx.rate;
    fprintf(stderr, "usrp_config_run_board: Setting RX Rate: %f...\n", rate);
    if ( (status = uhd_usrp_set_rx_rate(usrp, rate, channel)) )
      goto fail_out;
    // See what rate actually is
    if ( (status = uhd_usrp_get_rx_rate(usrp, channel, &rate)) )
      goto fail_out;
    fprintf(stderr, "usrp_config_run_board: Actual RX Rate: %f...\n", rate);
    trx->rx.rate = rate;

    // Set gain
    gain = trx->rx.gain;
    fprintf(stderr, "usrp_config_run_board: Setting RX Gain: %f dB...\n", gain);
    if ( (status = uhd_usrp_set_rx_gain(usrp, gain, channel, "")) )
      goto fail_out;
    // See what gain actually is
    if ( (status = uhd_usrp_get_rx_gain(usrp, channel, "", &gain)) )
      goto fail_out;
    fprintf(stderr, "usrp_config_run_board: Actual RX Gain: %f...\n", gain);
    trx->rx.gain = gain;

    // Set frequency
    usrp_tune_request.target_freq = trx->rx.freq;
    fprintf(stderr, "usrp_config_run_board: Setting RX frequency: %f MHz...\n", usrp_tune_request.target_freq/1e6);
    if ( (status = uhd_usrp_set_rx_freq(usrp, &usrp_tune_request, channel, &usrp_tune_result)) )
      goto fail_out;
    // See what frequency actually is
    if ( (status = uhd_usrp_get_rx_freq(usrp, channel, &(usrp_tune_request.target_freq))) )
      goto fail_out;
    fprintf(stderr, "usrp_config_run_board: Actual RX frequency: %f MHz...\n", usrp_tune_request.target_freq / 1e6);
    trx->rx.freq = usrp_tune_request.target_freq;

    // Set bw
    bw = trx->rx.bw;
    fprintf(stderr, "usrp_config_run_board: Setting RX bandwidth: %f MHz...\n", bw/1e6);
    if ( (status = uhd_usrp_set_rx_bandwidth(usrp, bw, channel)) )
      goto fail_out;
    // See what bw actually is
    if ( (status = uhd_usrp_get_rx_bandwidth(usrp, channel, &bw)) )
      goto fail_out;
    fprintf(stderr, "usrp_config_run_board: Actual RX bandwidth: %f MHz...\n", bw / 1e6);
    trx->rx.bw = bw;

    // Set up streamer
    if ( (status = uhd_usrp_get_rx_stream(usrp, &stream_args, usrp_rx_streamer)) )
      goto fail_out;

    // Set up buffer
    if ( (status = uhd_rx_streamer_max_num_samps(usrp_rx_streamer, &(trx->rx.num_sample_dev_buf))) )
      goto fail_out;

    fprintf(stderr, "usrp_config_run_board: RX Buffer size in samples: %zu\n", trx->rx.num_sample_dev_buf);
    usrp_rx_buff = malloc(trx->rx.num_sample_dev_buf * 2 * sizeof(int16_t));

    // Issue stream command
    fprintf(stderr, "usrp_config_run_board: Issuing rx stream command.\n");
    if ( (status = uhd_rx_streamer_issue_stream_cmd(usrp_rx_streamer, &stream_cmd)) )
      goto fail_out;

    if ( pthread_create(&(trx->rx.tid), NULL, usrp_rx_task_run, &(trx->rx) ) )
        return EXIT_FAILURE;
  }

  if (trx->tx.en) {
    // Create tx streamer
    if ( (status = uhd_tx_streamer_make(&usrp_tx_streamer)) ) 
      goto fail_out;

    // Create tx metadata
    if ( (status = uhd_tx_metadata_make(&usrp_tx_md,false,0,0.1,true,true)) )
      goto fail_out;

    // Set rate
    rate = trx->tx.rate;
    fprintf(stderr, "usrp_config_run_board: Setting tx Rate: %f...\n", trx->tx.rate);
    if ( (status = uhd_usrp_set_tx_rate(usrp, rate, channel)) )
      goto fail_out;
    // See what rate actually is
    if ( (status = uhd_usrp_get_tx_rate(usrp, channel, &rate)))
      goto fail_out;
    fprintf(stderr, "usrp_config_run_board: Actual tx Rate: %f...\n", rate);
    trx->tx.rate = rate;

    // Set gain
    gain = trx->tx.gain;
    fprintf(stderr, "usrp_config_run_board: Setting tx Gain: %f dB...\n", gain);
    if ( (status = uhd_usrp_set_tx_gain(usrp, gain, channel, "")) )
      goto fail_out;
    // See what gain actually is
    if ( (status = uhd_usrp_get_tx_gain(usrp, channel, "", &gain)))
      goto fail_out;
    fprintf(stderr, "usrp_config_run_board: Actual tx Gain: %f...\n", gain);
    trx->tx.gain = gain;

    // Set frequency
    usrp_tune_request.target_freq = trx->tx.freq;
    fprintf(stderr, "usrp_config_run_board: Setting tx frequency: %f MHz...\n", usrp_tune_request.target_freq/1e6);
    if ( (status = uhd_usrp_set_tx_freq(usrp, &usrp_tune_request, channel, &usrp_tune_result)) )
      goto fail_out;
    // See what frequency actually is
    if ( (status = uhd_usrp_get_tx_freq(usrp, channel, &(usrp_tune_request.target_freq))))
      goto fail_out;
    fprintf(stderr, "usrp_config_run_board: Actual tx frequency: %f MHz...\n", usrp_tune_request.target_freq / 1e6);
    trx->tx.freq = usrp_tune_request.target_freq;

    // Set bw
    bw = trx->tx.bw;
    fprintf(stderr, "usrp_config_run_board: Setting tx bandwidth: %f MHz...\n", bw/1e6);
    if ( (status = uhd_usrp_set_tx_bandwidth(usrp, bw, channel)) )
      goto fail_out;
    // See what bw actually is
    if ( (status = uhd_usrp_get_tx_bandwidth(usrp, channel, &bw)) )
      goto fail_out;
    fprintf(stderr, "usrp_config_run_board: Actual tx bandwidth: %f MHz...\n", bw / 1e6);
    trx->tx.bw = bw;

    // Set up streamer
    if ( (status = uhd_usrp_get_tx_stream(usrp, &stream_args, usrp_tx_streamer)) )
      goto fail_out;

    // Set up buffer
    if ( (status = uhd_tx_streamer_max_num_samps(usrp_tx_streamer, &usrp_tx_samps_per_buff)) )
      goto fail_out;

    fprintf(stderr, "usrp_config_run_board: TX Buffer size in samples: %zu\n", usrp_tx_samps_per_buff);
    usrp_tx_buff = malloc(usrp_tx_samps_per_buff * 2 * sizeof(int16_t));
  }

  trx->dev = usrp;
  trx->hw_type = USRP;

  if (trx->tx.en) {
    if (trx->tx.gain==-1)
      trx->tx.gain = USRP_DEFAULT_TX_GAIN;
    
    trx->tx.update_freq =  usrp_update_tx_freq;
    trx->tx.update_gain =  usrp_update_tx_gain;
    trx->tx.update_rate =  usrp_update_tx_rate;
    trx->tx.update_bw =    usrp_update_tx_bw;
    trx->tx.proc_one_buf = usrp_tx_one_buf;
  }

  if (trx->rx.en) {
    if (trx->rx.gain==-1)
      trx->rx.gain = BLADERF_DEFAULT_RX_GAIN;

    trx->rx.update_freq =  usrp_update_rx_freq;
    trx->rx.update_gain =  usrp_update_rx_gain;
    trx->rx.update_rate =  usrp_update_rx_rate;
    trx->rx.update_bw =    usrp_update_rx_bw;
    trx->rx.proc_one_buf = usrp_get_rx_sample;
  }

  trx->stop_close = usrp_stop_close_board;
  return(0);

fail_out:
  fprintf(stderr, "usrp_config_run_board: status %d\n", status);
  if (usrp!=NULL) {
  uhd_usrp_last_error(usrp, usrp_error_string, 512);
  fprintf(stderr, "usrp_config_run_board: USRP reported the following error: %s\n", usrp_error_string);
  }
  return(1);
}
#endif