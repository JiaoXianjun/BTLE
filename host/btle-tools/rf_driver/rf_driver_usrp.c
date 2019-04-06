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
static uhd_tune_request_t usrp_tune_request;
static uhd_tune_result_t usrp_tune_result;

void *usrp_rx_task_run(void *tmp)
{
  int i;
  size_t num_rx_samps = 0;
  uhd_rx_metadata_error_code_t error_code;
  struct rf_cfg_op *rx = (struct rf_cfg_op *)tmp;
  char *rx_buf = (char*)(rx->app_buf);
  int num_sample_app_buf = rx->num_sample_app_buf;
  int len_buf = 2*num_sample_app_buf;

  fprintf(stderr, "usrp_rx_task_run...\n");
      
  while (!do_exit) {
    uhd_rx_streamer_recv(rx->streamer, (void**)&(rx->dev_buf), rx->num_sample_dev_buf, &(rx->metadata), 3.0, false, &num_rx_samps);
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
          rx->app_buf_offset = (rx->app_buf_offset+2)&( len_buf-1 ); //cyclic buffer
      }
      pthread_mutex_unlock(&(rx->callback_lock));
    }
  }
  fprintf(stderr, "usrp_rx_task_run quit.\n");
  return(NULL);
}

int usrp_get_rx_sample(void *rf, void *buf, int *len) { // each time get back num_sample_app_buf
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

  (*buf) = rxp;

  return(sample_ready_flag);
}

int usrp_tx_one_buf(void *rf, void *buf, int *len){
  struct rf_cfg_op *tx = (struct rf_cfg_op *)rf;
  char *tx_buf = (char*)buf;
  int num_sample_tx_buf = (*len);
  int num_acc_samps = 0, num_samps_sent, status;

  while(1) {
      if (num_acc_samps >= num_sample_tx_buf) break;
      status = uhd_tx_streamer_send(tx->streamer, &tx_buf, tx->num_sample_dev_buf, &(tx->metadata), 0.1, &num_samps_sent);
      num_acc_samps += num_samps_sent;
  }

  return num_acc_samps;
}

void usrp_stop_close_board(void *tmp){
  struct trx_cfg_op *trx = (struct trx_cfg_op *)tmp;
  struct uhd_usrp* dev = NULL;
  fprintf(stderr, "usrp_stop_close_board...\n");
  
  if (trx->rx.en == RX_ENABLE) {
    pthread_join(usrp_rx_task, NULL);
    //pthread_cancel(usrp_rx_task);
    fprintf(stderr,"usrp_stop_close_board: USRP rx thread quit.\n");
    free(trx->rx.app_buf);
    free(trx->rx.dev_buf);
    dev = trx->rx.dev;
  }
  if (trx->tx.en) == TX_ENABLE {
    free(trx->tx.dev_buf); // because app will take care of app buf here
    if (dev == NULL) 
      dev = trx->tx.dev;
  }

  if (dev==NULL)
    return;

  if (trx->rx.en == RX_ENABLE) {
    fprintf(stderr, "usrp_stop_close_board: Cleaning up RX streamer.\n");
    uhd_rx_streamer_free(trx->rx.streamer);

    fprintf(stderr, "usrp_stop_close_board: Cleaning up RX metadata.\n");
    uhd_rx_metadata_free(trx->rx.metadata);

    uhd_usrp_last_error(dev, usrp_error_string, 512);
    fprintf(stderr, "usrp_stop_close_board: USRP RX reported the following error: %s\n", usrp_error_string);
  }

  if (trx->tx.en == TX_ENABLE) {
    //fprintf(stderr, "usrp_stop_close_board: Cleaning up TX streamer.\n");
    //uhd_rx_streamer_free(trx->tx.streamer);

    fprintf(stderr, "usrp_stop_close_board: Cleaning up TX metadata.\n");
    uhd_rx_metadata_free(trx->tx.metadata);

    uhd_usrp_last_error(dev, usrp_error_string, 512);
    fprintf(stderr, "usrp_stop_close_board: USRP TX reported the following error: %s\n", usrp_error_string);
  }
  
  uhd_usrp_free((struct uhd_usrp **)(&dev));
}

int usrp_update_tx_freq(void *rf_in, uint64_t freq_hz) {
  struct rf_cfg_op *rf = (struct rf_cfg_op *)rf_in;
  struct uhd_usrp *dev = rf->dev;
  int status;

  if (rf->en != TX_ENABLE){
    fprintf(stderr, "usrp_update_tx_freq: rf->en is not correct!\n");
    return(-1);
  }

  if (rf->freq == freq_hz)
    return(0);
  else
    rf->freq = freq_hz;

  usrp_tune_request.target_freq = freq_hz;
    status = uhd_usrp_set_tx_freq(dev, &usrp_tune_request, rf->chan, &usrp_tune_result);
    //status = (status|uhd_usrp_get_tx_freq(dev,rf->chan,&freq_result));
    if (status) {
      uhd_usrp_last_error(dev, usrp_error_string, 512);
      fprintf(stderr, "usrp_update_tx_freq: uhd_usrp_set_tx_freq: %s\n", usrp_error_string);
      return EXIT_FAILURE;
    }

  if (usrp_tune_result.actual_rf_freq!=usrp_tune_request.target_freq) {
    rf->freq = usrp_tune_result.actual_rf_freq;
    fprintf(stderr, "usrp_update_tx_freq: Actual freq %fHz\n", usrp_tune_result.actual_rf_freq);
  }

  return(0);
}

int usrp_update_rx_freq(void *rf_in, uint64_t freq_hz) {
  struct rf_cfg_op *rf = (struct rf_cfg_op *)rf_in;
  struct uhd_usrp *dev = rf->dev;
  int status;

  if (rf->en != RX_ENABLE)){
    fprintf(stderr, "usrp_update_rx_freq: rf->en is not correct!\n");
    return(-1);
  }

  if (rf->freq == freq_hz)
    return(0);
  else
    rf->freq = freq_hz;

  usrp_tune_request.target_freq = freq_hz;

    status = uhd_usrp_set_rx_freq(dev, &usrp_tune_request, rf->chan, &usrp_tune_result);
    //status = (status|uhd_usrp_get_rx_freq(dev,rf->chan,&freq_result));
    if (status) {
      uhd_usrp_last_error(dev, usrp_error_string, 512);
      fprintf(stderr, "usrp_update_rx_freq: uhd_usrp_set_rx_freq: %s\n", usrp_error_string);
      return EXIT_FAILURE;
    }

  if (usrp_tune_result.actual_rf_freq!=usrp_tune_request.target_freq) {
    rf->freq = usrp_tune_result.actual_rf_freq;
    fprintf(stderr, "usrp_update_rx_freq: Actual freq %fHz\n", usrp_tune_result.actual_rf_freq);
  }

  return(0);
}

int usrp_update_tx_gain(void *rf_in, int gain_in) {
  struct rf_cfg_op *rf = (struct rf_cfg_op *)rf_in;
  struct uhd_usrp *dev = rf->dev;
  int status;
  double gain=gain_in, gain_result;

  if (rf->en != TX_ENABLE){
    fprintf(stderr, "usrp_update_tx_gain: rf->en is not correct!\n");
    return(-1);
  }

  if (rf->gain == gain_in)
    return(0);
  else
    rf->gain = gain_in;

    status = uhd_usrp_set_tx_gain(dev, gain, rf->chan, "");
    status = (status|uhd_usrp_get_tx_gain(dev, rf->chan, "", &gain_result));
    if (status) {
      uhd_usrp_last_error(dev, usrp_error_string, 512);
      fprintf(stderr, "usrp_update_tx_gain: uhd_usrp_set_tx_gain: %s\n", usrp_error_string);
      return EXIT_FAILURE;
    }

  if (gain_result!=gain) {
    rf->gain = gain_result;
    fprintf(stderr, "usrp_update_tx_gain: Actual gain %f\n", gain_result);
  }

  return(0);
}

int usrp_update_rx_gain(void *rf_in, int gain_in) {
  struct rf_cfg_op *rf = (struct rf_cfg_op *)rf_in;
  struct uhd_usrp *dev = rf->dev;
  int status;
  double gain=gain_in, gain_result;

  if (rf->en != RX_ENABLE){
    fprintf(stderr, "usrp_update_rx_gain: rf->en is not correct!\n");
    return(-1);
  }

  if (rf->gain == gain_in)
    return(0);
  else
    rf->gain = gain_in;

    status = uhd_usrp_set_rx_gain(dev, gain, rf->chan, "");
    status = (status|uhd_usrp_get_rx_gain(dev, rf->chan, "", &gain_result));
    if (status) {
      uhd_usrp_last_error(dev, usrp_error_string, 512);
      fprintf(stderr, "usrp_update_rx_gain: uhd_usrp_set_rx_gain: %s\n", usrp_error_string);
      return EXIT_FAILURE;
    }

  if (gain_result!=gain) {
    rf->gain = gain_result;
    fprintf(stderr, "usrp_update_rx_gain: Actual gain %f\n", gain_result);
  }

  return(0);
}

int usrp_update_tx_rate(void *rf_in, int rate_in) {
  struct rf_cfg_op *rf = (struct rf_cfg_op *)rf_in;
  struct uhd_usrp *dev = rf->dev;
  int status;
  double rate=rate_in, rate_result;

  if ( rf->en != TX_ENABLE ){
    fprintf(stderr, "usrp_update_tx_rate: rf->en is not correct!\n");
    return(-1);
  }

  if (rf->rate == rate_in)
    return(0);
  else
    rf->rate = rate_in;

    status = uhd_usrp_set_tx_rate(dev, rate, rf->chan);
    status = (status|uhd_usrp_get_tx_rate(dev, rf->chan, &rate_result));
    if (status) {
      uhd_usrp_last_error(dev, usrp_error_string, 512);
      fprintf(stderr, "usrp_update_tx_rate: uhd_usrp_set_tx_rate: %s\n", usrp_error_string);
      return EXIT_FAILURE;
    }

  if (rate_result!=rate) {
    rf->rate = rate_result;
    fprintf(stderr, "usrp_update_tx_rate: Actual rate %f\n", rate_result);
  }

  return(0);
}

int usrp_update_rx_rate(void *rf_in, int rate_in) {
  struct rf_cfg_op *rf = (struct rf_cfg_op *)rf_in;
  struct uhd_usrp *dev = rf->dev;
  int status;
  double rate=rate_in, rate_result;

  if (rf->en != RX_ENABLE){
    fprintf(stderr, "usrp_update_rx_rate: rf->en is not correct!\n");
    return(-1);
  }

  if (rf->rate == rate_in)
    return(0);
  else
    rf->rate = rate_in;

    status = uhd_usrp_set_rx_rate(dev, rate, rf->chan);
    status = (status|uhd_usrp_get_rx_rate(dev, rf->chan, &rate_result));
    if (status) {
      uhd_usrp_last_error(dev, usrp_error_string, 512);
      fprintf(stderr, "usrp_update_rx_rate: uhd_usrp_set_rx_rate: %s\n", usrp_error_string);
      return EXIT_FAILURE;
    }

  if (rate_result!=rate) {
    rf->rate = rate_result;
    fprintf(stderr, "usrp_update_rx_rate: Actual rate %f\n", rate_result);
  }

  return(0);
}

int usrp_update_tx_bw(void *rf_in, int bw_in) {
  struct rf_cfg_op *rf = (struct rf_cfg_op *)rf_in;
  struct uhd_usrp *dev = rf->dev;
  int status;
  double bw=bw_in, bw_result;

  if ( rf->en != TX_ENABLE ){
    fprintf(stderr, "usrp_update_tx_bw: rf->en is not correct!\n");
    return(-1);
  }

  if (rf->bw == bw_in)
    return(0);
  else
    rf->bw = bw_in;


    status = uhd_usrp_set_tx_bandwidth(dev, bw, rf->chan);
    status = (status|uhd_usrp_get_tx_bandwidth(dev, rf->chan, &bw_result));
    if (status) {
      uhd_usrp_last_error(dev, usrp_error_string, 512);
      fprintf(stderr, "usrp_update_tx_bw: uhd_usrp_set_tx_bandwidth: %s\n", usrp_error_string);
      return EXIT_FAILURE;
    }

  if (bw_result!=bw) {
    rf->bw = bw_result;
    fprintf(stderr, "usrp_update_tx_bw: Actual bw %f\n", bw_result);
  }

  return(0);
}

int usrp_update_rx_bw(void *rf_in, int bw_in) {
  struct rf_cfg_op *rf = (struct rf_cfg_op *)rf_in;
  struct uhd_usrp *dev = rf->dev;
  int status;
  double bw=bw_in, bw_result;

  if ( rf->en != RX_ENABLE ){
    fprintf(stderr, "usrp_update_rx_bw: rf->en is not correct!\n");
    return(-1);
  }

  if (rf->bw == bw_in)
    return(0);
  else
    rf->bw = bw_in;

    status = uhd_usrp_set_rx_bandwidth(dev, bw, rf->chan);
    status = (status|uhd_usrp_get_rx_bandwidth(dev, rf->chan, &bw_result));
    if (status) {
      uhd_usrp_last_error(dev, usrp_error_string, 512);
      fprintf(stderr, "usrp_update_rx_bw: uhd_usrp_set_rx_bandwidth: %s\n", usrp_error_string);
      return EXIT_FAILURE;
    }

  if (bw_result!=bw) {
    rf->bw = bw_result;
    fprintf(stderr, "usrp_update_rx_bw: Actual bw %f\n", bw_result);
  }

  return(0);
}

inline int usrp_config_run_board(struct trx_cfg_op *trx) {
  struct uhd_usrp *usrp = NULL;
  uhd_error status;
  double rate, bw, gain;
  uhd_stream_args_t stream_args = {
      .cpu_format = "sc16",
      .otw_format = "sc16",
      .args = "",
      .channel_list = NULL,
      .n_channels = 1
  };
  uhd_stream_cmd_t stream_cmd = {
      .stream_mode = UHD_STREAM_MODE_START_CONTINUOUS,
      .num_samps = 0,
      .stream_now = true
  };
  
  trx->dev = NULL;

  usrp_tune_request.rf_freq_policy = UHD_TUNE_REQUEST_POLICY_AUTO;
  usrp_tune_request.dsp_freq_policy = UHD_TUNE_REQUEST_POLICY_AUTO;

  fprintf(stderr, "usrp_config_run_board: Creating USRP with args \"%s\"...\n", trx->args);

  // Create USRP
  if ( (status = uhd_usrp_make(&usrp, trx->args)) )
    goto fail_out;

  if (trx->rx.en ==RX_ENABLE) {
    // Create RX streamer
    if ( (status = uhd_rx_streamer_make(&(trx->rx.streamer))) ) 
      goto fail_out;

    // Create RX metadata
    if ( (status = uhd_rx_metadata_make(&(trx->rx.metadata))) )
      goto fail_out;

    // Set rate
    rate = trx->rx.rate;
    fprintf(stderr, "usrp_config_run_board: Setting RX Rate: %f...\n", rate);
    if ( (status = uhd_usrp_set_rx_rate(usrp, rate, trx->rx.chan)) )
      goto fail_out;
    // See what rate actually is
    if ( (status = uhd_usrp_get_rx_rate(usrp, trx->rx.chan, &rate)) )
      goto fail_out;
    fprintf(stderr, "usrp_config_run_board: Actual RX Rate: %f...\n", rate);
    trx->rx.rate = rate;

    // Set gain
    gain = trx->rx.gain;
    fprintf(stderr, "usrp_config_run_board: Setting RX Gain: %f dB...\n", gain);
    if ( (status = uhd_usrp_set_rx_gain(usrp, gain, trx->rx.chan, "")) )
      goto fail_out;
    // See what gain actually is
    if ( (status = uhd_usrp_get_rx_gain(usrp, trx->rx.chan, "", &gain)) )
      goto fail_out;
    fprintf(stderr, "usrp_config_run_board: Actual RX Gain: %f...\n", gain);
    trx->rx.gain = gain;

    // Set frequency
    usrp_tune_request.target_freq = trx->rx.freq;
    fprintf(stderr, "usrp_config_run_board: Setting RX frequency: %f MHz...\n", usrp_tune_request.target_freq/1e6);
    if ( (status = uhd_usrp_set_rx_freq(usrp, &usrp_tune_request, trx->rx.chan, &usrp_tune_result)) )
      goto fail_out;
    fprintf(stderr, "usrp_config_run_board: Actual RX frequency: %f MHz...\n", usrp_tune_result.actual_rf_freq / 1e6);
    trx->rx.freq = usrp_tune_result.actual_rf_freq;

    // Set bw
    bw = trx->rx.bw;
    fprintf(stderr, "usrp_config_run_board: Setting RX bandwidth: %f MHz...\n", bw/1e6);
    if ( (status = uhd_usrp_set_rx_bandwidth(usrp, bw, trx->rx.chan)) )
      goto fail_out;
    // See what bw actually is
    if ( (status = uhd_usrp_get_rx_bandwidth(usrp, trx->rx.chan, &bw)) )
      goto fail_out;
    fprintf(stderr, "usrp_config_run_board: Actual RX bandwidth: %f MHz...\n", bw / 1e6);
    trx->rx.bw = bw;

    // Set up streamer
    stream_args.channel_list = &(trx->rx.chan);
    if ( (status = uhd_usrp_get_rx_stream(usrp, &stream_args, trx->rx.streamer)) )
      goto fail_out;

    // Set up buffer
    if ( (status = uhd_rx_streamer_max_num_samps(trx->rx.streamer, &(trx->rx.num_sample_dev_buf))) )
      goto fail_out;

    fprintf(stderr, "usrp_config_run_board: RX Buffer size in samples: %zu\n", trx->rx.num_sample_dev_buf);
    trx->rx.dev_buf = malloc(trx->rx.num_sample_dev_buf * 2 * sizeof(int16_t)); // 2 for I and Q

    // Issue stream command
    fprintf(stderr, "usrp_config_run_board: Issuing rx stream command.\n");
    stream_cmd.num_samps = trx->rx.num_sample_dev_buf;
    if ( (status = uhd_rx_streamer_issue_stream_cmd(trx->rx.streamer, &stream_cmd)) )
      goto fail_out;

    if ( pthread_create(&(trx->rx.tid), NULL, usrp_rx_task_run, &(trx->rx) ) )
        return EXIT_FAILURE;
  }

  if (trx->tx.en == TX_ENABLE) {
    // Create tx streamer
    if ( (status = uhd_tx_streamer_make(&(trx->tx.streamer))) ) 
      goto fail_out;

    // Create tx metadata
    if ( (status = uhd_tx_metadata_make(&(trx->tx.metadata),false,0,0.1,true,false)) )
      goto fail_out;

    // Set rate
    rate = trx->tx.rate;
    fprintf(stderr, "usrp_config_run_board: Setting tx Rate: %f...\n", trx->tx.rate);
    if ( (status = uhd_usrp_set_tx_rate(usrp, rate, trx->rx.chan)) )
      goto fail_out;
    // See what rate actually is
    if ( (status = uhd_usrp_get_tx_rate(usrp, trx->rx.chan, &rate)))
      goto fail_out;
    fprintf(stderr, "usrp_config_run_board: Actual tx Rate: %f...\n", rate);
    trx->tx.rate = rate;

    // Set gain
    gain = trx->tx.gain;
    fprintf(stderr, "usrp_config_run_board: Setting tx Gain: %f dB...\n", gain);
    if ( (status = uhd_usrp_set_tx_gain(usrp, gain, trx->rx.chan, "")) )
      goto fail_out;
    // See what gain actually is
    if ( (status = uhd_usrp_get_tx_gain(usrp, trx->rx.chan, "", &gain)))
      goto fail_out;
    fprintf(stderr, "usrp_config_run_board: Actual tx Gain: %f...\n", gain);
    trx->tx.gain = gain;

    // Set frequency
    usrp_tune_request.target_freq = trx->tx.freq;
    fprintf(stderr, "usrp_config_run_board: Setting tx frequency: %f MHz...\n", usrp_tune_request.target_freq/1e6);
    if ( (status = uhd_usrp_set_tx_freq(usrp, &usrp_tune_request, trx->rx.chan, &usrp_tune_result)) )
      goto fail_out;
    fprintf(stderr, "usrp_config_run_board: Actual tx frequency: %f MHz...\n", usrp_tune_result.actual_rf_freq  / 1e6);
    trx->tx.freq = usrp_tune_result.actual_rf_freq;

    // Set bw
    bw = trx->tx.bw;
    fprintf(stderr, "usrp_config_run_board: Setting tx bandwidth: %f MHz...\n", bw/1e6);
    if ( (status = uhd_usrp_set_tx_bandwidth(usrp, bw, trx->rx.chan)) )
      goto fail_out;
    // See what bw actually is
    if ( (status = uhd_usrp_get_tx_bandwidth(usrp, trx->rx.chan, &bw)) )
      goto fail_out;
    fprintf(stderr, "usrp_config_run_board: Actual tx bandwidth: %f MHz...\n", bw / 1e6);
    trx->tx.bw = bw;

    // Set up streamer
    stream_args.channel_list = &(trx->tx.chan);
    if ( (status = uhd_usrp_get_tx_stream(usrp, &stream_args, trx->tx.streamer)) )
      goto fail_out;

    // Set up buffer
    if ( (status = uhd_tx_streamer_max_num_samps(trx->tx.streamer, &(trx->tx.num_sample_dev_buf))) )
      goto fail_out;

    fprintf(stderr, "usrp_config_run_board: TX Buffer size in samples: %zu\n", trx->tx.num_sample_dev_buf);
    trx->tx.dev_buf = malloc(trx->tx.num_sample_dev_buf * 2 * sizeof(int16_t));
  }

  trx->dev = usrp;
  trx->board = USRP;

  if (trx->tx.en==TX_ENABLE) {
    if (trx->tx.gain==-1)
      trx->tx.gain = USRP_DEFAULT_TX_GAIN;
    
    trx->tx.update_freq =  usrp_update_tx_freq;
    trx->tx.update_gain =  usrp_update_tx_gain;
    trx->tx.update_rate =  usrp_update_tx_rate;
    trx->tx.update_bw =    usrp_update_tx_bw;
    trx->tx.proc_one_buf = usrp_tx_one_buf;
  }

  if (trx->rx.en==RX_ENABLE) {
    if (trx->rx.gain==-1)
      trx->rx.gain = USRP_DEFAULT_RX_GAIN;

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
  return(-1);
}
#endif
