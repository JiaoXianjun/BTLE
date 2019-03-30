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
#include "rf_driver_bladerf.h"
#include "../common_misc.h"

extern pthread_mutex_t callback_lock;
extern volatile IQ_TYPE rx_buf[];
extern volatile int rx_buf_offset; // remember to initialize it!
extern volatile bool do_exit;
extern void sigint_callback_handler(int signum);

struct bladerf_stream *bladerf_rx_stream;
pthread_t bladerf_rx_task;
struct bladerf_data bladerf_rx_data;

volatile int16_t bladerf_tx_buf[NUM_BLADERF_BUF_SAMPLE_TX*2];

void *bladerf_stream_callback(struct bladerf *dev, struct bladerf_stream *stream,
                      struct bladerf_metadata *metadata, void *samples,
                      size_t num_samples, void *user_data)
{
    struct bladerf_data *my_data = (struct bladerf_data *)user_data;

    //count++ ;

    //if( (count&0xffff) == 0 ) {
    //    fprintf( stderr, "Called 0x%8.8x times\n", count ) ;
    //}

    /* Save off the samples to disk if we are in RX */
    //if( my_data->module == BLADERF_MODULE_RX ) {
        size_t i;
        int16_t *sample = (int16_t *)samples ;
        if (num_samples>0) {
          pthread_mutex_lock(&callback_lock);
          for(i = 0; i < num_samples ; i++ ) {
              //*(sample) &= 0xfff ;
              //if( (*sample)&0x800 ) *(sample) |= 0xf000 ;
              //*(sample+1) &= 0xfff ;
              //if( *(sample+1)&0x800 ) *(sample+1) |= 0xf000 ;
              //fprintf( my_data->fout, "%d, %d\n", *sample, *(sample+1) );
              rx_buf[rx_buf_offset] = (((*sample)>>4)&0xFF);
              rx_buf[rx_buf_offset+1] = (((*(sample+1))>>4)&0xFF);
              rx_buf_offset = (rx_buf_offset+2)&( LEN_BUF-1 ); //cyclic buffer

              sample += 2 ;
          }
          pthread_mutex_unlock(&callback_lock);
        }
        //my_data->samples_left -= num_samples ;
        //if( my_data->samples_left <= 0 ) {
        //    do_exit = true ;
        //}
    //}

    if (do_exit) {
        return NULL;
    } else {
        void *rv = my_data->buffers[my_data->idx];
        my_data->idx = (my_data->idx + 1) % my_data->num_buffers;
        return rv ;
    }
}

int bladerf_tune_rx(void *dev, uint64_t freq_hz) {
  int status;
  status = bladerf_set_frequency((struct bladerf *)dev, BLADERF_MODULE_RX, freq_hz);
  if (status != 0) {
      fprintf(stderr, "bladerf_tune_rx: Failed to set frequency: %s\n",
              bladerf_strerror(status));
      bladerf_close((struct bladerf *)dev);
      return EXIT_FAILURE;
  }
  return(0);
}

int bladerf_tune_tx(void *dev, uint64_t freq_hz) {
  int status;
  status = bladerf_set_frequency((struct bladerf *)dev, BLADERF_MODULE_TX, freq_hz);
  if (status != 0) {
      fprintf(stderr, "bladerf_tune_tx: Failed to set frequency: %s\n",
              bladerf_strerror(status));
      bladerf_close((struct bladerf *)dev);
      return EXIT_FAILURE;
  }
  return(0);
}

void *bladerf_rx_task_run(void *tmp)
{
  int status;

  /* Start stream and stay there until we kill the stream */
  status = bladerf_stream(bladerf_rx_stream, BLADERF_MODULE_RX);
  if (status < 0) {
    fprintf(stderr, "RX stream failure: %s\r\n", bladerf_strerror(status));
  }
  return NULL;
}

inline int bladerf_config_run_board(struct trx_cfg_op *trx) {
  int status;
  unsigned int actual;
  struct bladerf *dev = NULL;

  trx->dev = NULL;

  if (trx->rx.en) {
    bladerf_rx_data.idx = 0;
    bladerf_rx_data.num_buffers = 2;
    bladerf_rx_data.samples_per_buffer = (LEN_BUF/2);
  }

  status = bladerf_open(&dev, NULL);
  if (status < 0) {
      fprintf(stderr, "bladerf_config_run_board: Failed to open device: %s\n", bladerf_strerror(status));
      return EXIT_FAILURE;
  } else  {
    fprintf(stdout, "bladerf_config_run_board: open device: %s\n", bladerf_strerror(status));
  }
  
  status = bladerf_is_fpga_configured(dev);
  if (status < 0) {
      fprintf(stderr, "bladerf_config_run_board: Failed to determine FPGA state: %s\n", bladerf_strerror(status));
      return EXIT_FAILURE;
  } else if (status == 0) {
      fprintf(stderr, "bladerf_config_run_board: Error: FPGA is not loaded.\n");
      bladerf_close(dev);
      return EXIT_FAILURE;
  } else  {
    fprintf(stdout, "bladerf_config_run_board: FPGA is loaded.\n");
  }
  
  if (trx->tx.en) {
    status = bladerf_set_frequency(dev, BLADERF_MODULE_TX, trx->tx.freq);
    if (status != 0) {
        fprintf(stderr, "bladerf_config_run_board: Failed to set tx frequency: %s\n", bladerf_strerror(status));
        bladerf_close(dev);
        return EXIT_FAILURE;
    } else {
        fprintf(stdout, "bladerf_config_run_board: set tx frequency: %luHz %s\n", trx->tx.freq, bladerf_strerror(status));
    }
  }

  if (trx->rx.en) {
    status = bladerf_set_frequency(dev, BLADERF_MODULE_RX, trx->rx.freq);
    if (status != 0) {
        fprintf(stderr, "bladerf_config_run_board: Failed to set rx frequency: %s\n", bladerf_strerror(status));
        bladerf_close(dev);
        return EXIT_FAILURE;
    } else {
        fprintf(stdout, "bladerf_config_run_board: set rx frequency: %luHz %s\n", trx->rx.freq, bladerf_strerror(status));
    }
  }

  if (trx->tx.en){
    status = bladerf_set_sample_rate(dev, BLADERF_MODULE_TX, trx->tx.rate, &actual);
    if (status != 0) {
        fprintf(stderr, "bladerf_config_run_board: Failed to set tx sample rate: %s\n", bladerf_strerror(status));
        bladerf_close(dev);
        return EXIT_FAILURE;
    } else {
      fprintf(stdout, "bladerf_config_run_board: set tx sample rate: %dHz %s\n", actual, bladerf_strerror(status));
    }
  }

  if (trx->rx.en){
    status = bladerf_set_sample_rate(dev, BLADERF_MODULE_RX, trx->rx.rate, &actual);
    if (status != 0) {
        fprintf(stderr, "bladerf_config_run_board: Failed to set rx sample rate: %s\n", bladerf_strerror(status));
        bladerf_close(dev);
        return EXIT_FAILURE;
    } else {
      fprintf(stdout, "bladerf_config_run_board: set rx sample rate: %dHz %s\n", actual, bladerf_strerror(status));
    }
  }

  if (trx->tx.en) {
    status = bladerf_set_bandwidth(dev, BLADERF_MODULE_TX, trx->tx.bw, &actual);
    if (status != 0) {
        fprintf(stderr, "bladerf_config_run_board: Failed to set tx bandwidth: %s\n", bladerf_strerror(status));
        bladerf_close(dev);
        return EXIT_FAILURE;
    } else {
      fprintf(stdout, "bladerf_config_run_board: tx bladerf_set_bandwidth: %d %s\n", actual, bladerf_strerror(status));
    }
  }

  if (trx->rx.en) {
    status = bladerf_set_bandwidth(dev, BLADERF_MODULE_RX, trx->rx.bw, &actual);
    if (status != 0) {
        fprintf(stderr, "bladerf_config_run_board: Failed to set rx bandwidth: %s\n", bladerf_strerror(status));
        bladerf_close(dev);
        return EXIT_FAILURE;
    } else {
      fprintf(stdout, "bladerf_config_run_board: rx bladerf_set_bandwidth: %d %s\n", actual, bladerf_strerror(status));
    }
  }

  if (trx->tx.en) {
    status = bladerf_set_gain(dev, BLADERF_MODULE_RX, trx->tx.gain);
    if (status != 0) {
        fprintf(stderr, "bladerf_config_run_board: Failed to set tx gain: %s\n", bladerf_strerror(status));
        bladerf_close(dev);
        return EXIT_FAILURE;
    } else {
      fprintf(stdout, "bladerf_config_run_board: tx bladerf_set_gain: %d %s\n", trx->tx.gain, bladerf_strerror(status));
    }
  }

  if (trx->rx.en) {
    status = bladerf_set_gain(dev, BLADERF_MODULE_RX, trx->rx.gain);
    if (status != 0) {
        fprintf(stderr, "bladerf_config_run_board: Failed to set rx gain: %s\n", bladerf_strerror(status));
        bladerf_close(dev);
        return EXIT_FAILURE;
    } else {
      fprintf(stdout, "bladerf_config_run_board: rx bladerf_set_gain: %d %s\n", trx->rx.gain, bladerf_strerror(status));
    }
  }

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

  /* Initialize the stream */
  status = bladerf_init_stream(
              &bladerf_rx_stream,
              dev,
              bladerf_stream_callback,
              &bladerf_rx_data.buffers,
              bladerf_rx_data.num_buffers,
              BLADERF_FORMAT_SC16_Q11,
              bladerf_rx_data.samples_per_buffer,
              bladerf_rx_data.num_buffers,
              &bladerf_rx_data
            );

  if (status != 0) {
      fprintf(stderr, "bladerf_config_run_board: Failed to init rx stream: %s\n", bladerf_strerror(status));
      bladerf_close(dev);
      return EXIT_FAILURE;
  } else {
    fprintf(stdout, "bladerf_config_run_board: init rx stream: %s\n", bladerf_strerror(status));
  }

  bladerf_set_stream_timeout(dev, BLADERF_MODULE_RX, 100);

  status = bladerf_enable_module(dev, BLADERF_MODULE_RX, true);
  if (status < 0) {
      fprintf(stderr, "bladerf_config_run_board: Failed to enable module: %s\n", bladerf_strerror(status));
      bladerf_deinit_stream(bladerf_rx_stream);
      bladerf_close(dev);
      return EXIT_FAILURE;
  } else {
    fprintf(stdout, "bladerf_config_run_board: enable module true: %s\n", bladerf_strerror(status));
  }

  status = pthread_create(&bladerf_rx_task, NULL, bladerf_rx_task_run, NULL);
  if (status < 0) {
      return EXIT_FAILURE;
  }

  (*rf_dev) = dev;
  return(0);
}

void bladerf_stop_close_board(void *dev, bool trx_flag){
  int status;

  fprintf(stderr, "bladerf_stop_close_board...\n");
  
  if (trx_flag&1) {
    //pthread_join(bladerf_tx_task, NULL);
    //printf("bladerf_stop_close_board: pthread_join(bladerf_tx_task, NULL)\n");
  }
  
  if (trx_flag&2) {
    pthread_join(bladerf_rx_task, NULL);
    printf("bladerf_stop_close_board: pthread_join(bladerf_rx_task, NULL)\n");
  } 

  if (dev==NULL)
    return;

  if (trx_flag&1) {
    //bladerf_deinit_stream(bladerf_tx_stream);
    //printf("bladerf_stop_close_board: bladerf_deinit_stream(bladerf_tx_stream)\n");

    status = bladerf_enable_module((struct bladerf *)dev, BLADERF_MODULE_TX, false);
    if (status < 0) {
        fprintf(stderr, "bladerf_stop_close_board: Failed to enable module BLADERF_MODULE_TX: %s\n",
                bladerf_strerror(status));
    } else {
      fprintf(stdout, "bladerf_stop_close_board: enable module BLADERF_MODULE_TX false: %s\n", bladerf_strerror(status));
    }
  }

  if (trx_flag&2) {
    bladerf_deinit_stream(bladerf_rx_stream);
    printf("bladerf_stop_close_board: bladerf_deinit_stream(bladerf_rx_stream)\n");

    status = bladerf_enable_module((struct bladerf *)dev, BLADERF_MODULE_RX, false);
    if (status < 0) {
        fprintf(stderr, "bladerf_stop_close_board: Failed to enable module BLADERF_MODULE_RX: %s\n",
                bladerf_strerror(status));
    } else {
      fprintf(stdout, "bladerf_stop_close_board: enable module BLADERF_MODULE_RX false: %s\n", bladerf_strerror(status));
    }
  }

  bladerf_close((struct bladerf *)dev);
  printf("bladerf_stop_close_board: bladerf_close.\n");
}

//------------------------------FROM TX----------------------
inline int init_board() {
  int status;
  unsigned int actual;

  if (signal(SIGINT, sigint_callback_handler) == SIG_ERR ||
      signal(SIGTERM, sigint_callback_handler) == SIG_ERR) {
      fprintf(stderr, "Failed to set up signal handler\n");
      return EXIT_FAILURE;
  }

  status = bladerf_open(&dev, NULL);
  if (status < 0) {
      fprintf(stderr, "Failed to open device: %s\n", bladerf_strerror(status));
      return EXIT_FAILURE;
  } else  {
    fprintf(stdout, "open device: %s\n", bladerf_strerror(status));
  }
  
  status = bladerf_is_fpga_configured(dev);
  if (status < 0) {
      fprintf(stderr, "Failed to determine FPGA state: %s\n",
              bladerf_strerror(status));
      return EXIT_FAILURE;
  } else if (status == 0) {
      fprintf(stderr, "Error: FPGA is not loaded.\n");
      bladerf_close(dev);
      return EXIT_FAILURE;
  } else  {
    fprintf(stdout, "FPGA is loaded.\n");
  }
  
  status = bladerf_set_frequency(dev, BLADERF_MODULE_TX, 2402000000ull);
  if (status != 0) {
      fprintf(stderr, "Failed to set frequency: %s\n",
              bladerf_strerror(status));
      bladerf_close(dev);
      return EXIT_FAILURE;
  } else {
      fprintf(stdout, "set frequency: %lluHz %s\n", 2402000000ull,
              bladerf_strerror(status));
  }

  status = bladerf_set_sample_rate(dev, BLADERF_MODULE_TX, SAMPLE_PER_SYMBOL*1000000ul, &actual);
  if (status != 0) {
      fprintf(stderr, "Failed to set sample rate: %s\n",
              bladerf_strerror(status));
      bladerf_close(dev);
      return EXIT_FAILURE;
  } else {
    fprintf(stdout, "set sample rate: %dHz %s\n", actual,
              bladerf_strerror(status));
  }
  
  status = bladerf_set_bandwidth(dev, BLADERF_MODULE_TX, SAMPLE_PER_SYMBOL*1000000ul/2, &actual);
  if (status != 0) {
      fprintf(stderr, "Failed to set bandwidth: %s\n",
              bladerf_strerror(status));
      bladerf_close(dev);
      return EXIT_FAILURE;
  } else {
    fprintf(stdout, "bladerf_set_bandwidth: %d %s\n", actual,
              bladerf_strerror(status));
  }
  
  status = bladerf_set_gain(dev, BLADERF_MODULE_TX, 57);
  if (status != 0) {
      fprintf(stderr, "Failed to set gain: %s\n",
              bladerf_strerror(status));
      bladerf_close(dev);
      return EXIT_FAILURE;
  } else {
    fprintf(stdout, "bladerf_set_gain: %d %s\n", 57,
              bladerf_strerror(status));
  }

  status = bladerf_sync_config(dev,
                                BLADERF_MODULE_TX,
                                BLADERF_FORMAT_SC16_Q11,
                                32,
                                NUM_BLADERF_BUF_SAMPLE_TX,
                                16,
                                10);

  if (status != 0) {
      fprintf(stderr, "Failed to initialize TX sync handle: %s\n",
                bladerf_strerror(status));
      bladerf_close(dev);
      return EXIT_FAILURE;
  } else {
    fprintf(stdout, "bladerf_sync_config: %s\n",
              bladerf_strerror(status));
  }

  status = bladerf_enable_module(dev, BLADERF_MODULE_TX, true);
  if (status < 0) {
      fprintf(stderr, "Failed to enable module: %s\n",
              bladerf_strerror(status));
      bladerf_close(dev);
      return EXIT_FAILURE;
  } else {
    fprintf(stdout, "enable module true: %s\n",
              bladerf_strerror(status));
  }

  return(0);
}

void close_board(){
  int status;

  status = bladerf_enable_module(dev, BLADERF_MODULE_TX, false);
  if (status < 0) {
      fprintf(stderr, "Failed to enable module: %s\n",
              bladerf_strerror(status));
  } else {
    fprintf(stdout, "enable module false: %s\n", bladerf_strerror(status));
  }

  bladerf_close(dev);

  printf("bladeRF closed.\n");
}

void exit_board() {
  return;
}

inline int bladerf_tx_one_buf(void *dev, char *buf, int length) {
  int status, i;

  memset( (void *)bladerf_tx_buf, 0, NUM_BLADERF_BUF_SAMPLE_TX*2*sizeof(bladerf_tx_buf[0]) );

  for (i=(NUM_BLADERF_BUF_SAMPLE_TX*2-length); i<(NUM_BLADERF_BUF_SAMPLE_TX*2); i++) {
    bladerf_tx_buf[i] = ( (int)( buf[i-(NUM_BLADERF_BUF_SAMPLE_TX*2-length)] ) )*16;
  }

  // Transmit samples
  status = bladerf_sync_tx(dev, (void *)bladerf_tx_buf, NUM_BLADERF_BUF_SAMPLE_TX, NULL, 10);
  if (status != 0) {
    printf("bladerf_tx_one_buf: Failed to TX samples 1: %s\n",
             bladerf_strerror(status));
    return(-1);
  }

  return(0);
}

#endif
