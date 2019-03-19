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

extern pthread_mutex_t callback_lock;
extern volatile IQ_TYPE rx_buf[];
extern volatile int rx_buf_offset; // remember to initialize it!
extern volatile bool do_exit;

uhd_rx_streamer_handle usrp_rx_streamer;
uhd_rx_metadata_handle usrp_md;
uhd_tune_request_t usrp_tune_request;
uhd_tune_result_t  usrp_tune_result;
int16_t *usrp_buff = NULL;
pthread_t usrp_rx_task;
size_t usrp_samps_per_buff;
char usrp_error_string[512];

extern void sigint_callback_handler(int signum);

void *usrp_rx_task_run(void *tmp)
{
  int i;
  size_t num_rx_samps = 0;
  uhd_rx_metadata_error_code_t error_code;
  
  fprintf(stderr, "usrp_rx_task_run...\n");
      
  while (!do_exit) {
    uhd_rx_streamer_recv(usrp_rx_streamer, (void**)&usrp_buff, usrp_samps_per_buff, &usrp_md, 3.0, false, &num_rx_samps);
    //fprintf(stderr, "usrp_rx_task_run: %d %d %d\n", num_rx_samps, LEN_BUF, rx_buf_offset);
    if (uhd_rx_metadata_error_code(usrp_md, &error_code) ) {
      fprintf(stderr, "usrp_rx_task_run: uhd_rx_metadata_error_code return error. Aborting.\n");
      return(NULL);
    }

    if(error_code != UHD_RX_METADATA_ERROR_CODE_NONE){
        fprintf(stderr, "usrp_rx_task_run: Error code 0x%x was returned during streaming. Aborting.\n", error_code);
        return(NULL);
    }

    if (num_rx_samps>0) {
      pthread_mutex_lock(&callback_lock);
      // Handle data
      for(i = 0; i < (2*num_rx_samps) ; i=i+2 ) {
          rx_buf[rx_buf_offset] =   ( ( (*(usrp_buff+i)  )>>8)&0xFF );
          rx_buf[rx_buf_offset+1] = ( ( (*(usrp_buff+i+1))>>8)&0xFF );
          rx_buf_offset = (rx_buf_offset+2)&( LEN_BUF-1 ); //cyclic buffer
      }
      pthread_mutex_unlock(&callback_lock);
    }
  }
  fprintf(stderr, "usrp_rx_task_run quit.\n");
  return(NULL);
}

void usrp_stop_close_board(void *dev, bool trx_flag){
  fprintf(stderr, "usrp_stop_close_board...\n");
  
  pthread_join(usrp_rx_task, NULL);
  //pthread_cancel(usrp_rx_task);
  fprintf(stderr,"usrp_stop_close_board: USRP rx thread quit.\n");

  free(usrp_buff);

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

inline int usrp_config_run_board(uint64_t freq_hz, char *device_args, int gain_input, void **rf_dev, bool trx_flag) {
  uhd_usrp_handle usrp = NULL;
  size_t channel = 0;
  double rate = (double)SAMPLE_PER_SYMBOL*(double)1000000ul;
  double gain = (double)gain_input;
  double freq = (double)freq_hz;
  double bw = rate/2;
  uhd_error status;
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

  (*rf_dev) = NULL;
  // init other necessary structs
  usrp_tune_request.target_freq = freq;
  usrp_tune_request.rf_freq_policy = UHD_TUNE_REQUEST_POLICY_AUTO;
  usrp_tune_request.dsp_freq_policy = UHD_TUNE_REQUEST_POLICY_AUTO;

  fprintf(stderr, "usrp_config_run_board: Creating USRP with args \"%s\"...\n", device_args);

  // Create USRP
  if ( (status = uhd_usrp_make(&usrp, device_args)) )
    goto fail_out;

  //exit(1);
  // Create RX streamer
  if ( (status = uhd_rx_streamer_make(&usrp_rx_streamer)) ) 
    goto fail_out;

  // Create RX metadata
  if ( (status = uhd_rx_metadata_make(&usrp_md)) )
     goto fail_out;

  // Set rate
  fprintf(stderr, "usrp_config_run_board: Setting RX Rate: %f...\n", rate);
  if ( (status = uhd_usrp_set_rx_rate(usrp, rate, channel)) )
    goto fail_out;

  // See what rate actually is
  if ( (status = uhd_usrp_get_rx_rate(usrp, channel, &rate)) )
    goto fail_out;
  fprintf(stderr, "usrp_config_run_board: Actual RX Rate: %f...\n", rate);

  // Set gain
  fprintf(stderr, "usrp_config_run_board: Setting RX Gain: %f dB...\n", gain);
  if ( (status = uhd_usrp_set_rx_gain(usrp, gain, channel, "")) )
    goto fail_out;

  // See what gain actually is
  if ( (status = uhd_usrp_get_rx_gain(usrp, channel, "", &gain)) )
    goto fail_out;

  fprintf(stderr, "usrp_config_run_board: Actual RX Gain: %f...\n", gain);

  // Set frequency
  fprintf(stderr, "usrp_config_run_board: Setting RX frequency: %f MHz...\n", freq/1e6);
  if ( (status = uhd_usrp_set_rx_freq(usrp, &usrp_tune_request, channel, &usrp_tune_result)) )
    goto fail_out;


  // See what frequency actually is
  if ( (status = uhd_usrp_get_rx_freq(usrp, channel, &freq)) )
    goto fail_out;

  fprintf(stderr, "usrp_config_run_board: Actual RX frequency: %f MHz...\n", freq / 1e6);

  // Set bw
  fprintf(stderr, "usrp_config_run_board: Setting RX bandwidth: %f MHz...\n", bw/1e6);
  if ( (status = uhd_usrp_set_rx_bandwidth(usrp, bw, channel)) )
    goto fail_out;

  // See what bw actually is
  if ( (status = uhd_usrp_get_rx_bandwidth(usrp, channel, &bw)) )
    goto fail_out;

  fprintf(stderr, "usrp_config_run_board: Actual RX bandwidth: %f MHz...\n", bw / 1e6);

  // Set up streamer
  if ( (status = uhd_usrp_get_rx_stream(usrp, &stream_args, usrp_rx_streamer)) )
    goto fail_out;

  // Set up buffer
  if ( (status = uhd_rx_streamer_max_num_samps(usrp_rx_streamer, &usrp_samps_per_buff)) )
    goto fail_out;

  fprintf(stderr, "usrp_config_run_board: Buffer size in samples: %zu\n", usrp_samps_per_buff);
  usrp_buff = malloc(usrp_samps_per_buff * 2 * sizeof(int16_t));

  // Issue stream command
  fprintf(stderr, "usrp_config_run_board: Issuing stream command.\n");
  if ( (status = uhd_rx_streamer_issue_stream_cmd(usrp_rx_streamer, &stream_cmd)) )
    goto fail_out;

  if ( pthread_create(&usrp_rx_task, NULL, usrp_rx_task_run, NULL) )
      return EXIT_FAILURE;

  (*rf_dev) = usrp;
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