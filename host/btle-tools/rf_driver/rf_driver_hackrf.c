#include "rf_driver_cfg.h"
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

#ifdef HAS_HACKRF
#include <hackrf.h>
#include "rf_driver_hackrf.h"
#include "../common_misc.h"

extern pthread_mutex_t callback_lock;
extern volatile IQ_TYPE rx_buf[LEN_BUF + LEN_BUF_MAX_NUM_PHY_SAMPLE];
extern volatile int rx_buf_offset; // remember to initialize it!
extern volatile bool do_exit;

extern void sigint_callback_handler(int signum);

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

int hackrf_init_board() {
	int result = hackrf_init();
	if( result != HACKRF_SUCCESS ) {
		fprintf(stderr,"hackrf_init_board: hackrf_init() failed: %s (%d)\n", hackrf_error_name(result), result);
		//print_usage();
		return(EXIT_FAILURE);
	}

  #ifdef _MSC_VER
    SetConsoleCtrlHandler( (PHANDLER_ROUTINE) sighandler, TRUE );
  #else
    if (signal(SIGINT, sigint_callback_handler)==SIG_ERR ||
        signal(SIGILL, sigint_callback_handler)==SIG_ERR ||
        signal(SIGFPE, sigint_callback_handler)==SIG_ERR ||
        signal(SIGSEGV,sigint_callback_handler)==SIG_ERR ||
        signal(SIGTERM,sigint_callback_handler)==SIG_ERR ||
        signal(SIGABRT,sigint_callback_handler)==SIG_ERR) {
          fprintf(stderr, "hackrf_init_board: Failed to set up signal handler\n");
          return EXIT_FAILURE;
        }
  #endif

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

void hackrf_exit_board(hackrf_device *device) {
	if(device != NULL)
	{
		hackrf_exit();
		printf("hackrf_exit() done\n");
	}
}

inline int hackrf_close_board(hackrf_device *device) {
  int result;

	if(device != NULL)
	{
    result = hackrf_stop_rx(device);
    if( result != HACKRF_SUCCESS ) {
      printf("close_board: hackrf_stop_rx() failed: %s (%d)\n", hackrf_error_name(result), result);
      return(-1);
    }

		result = hackrf_close(device);
		if( result != HACKRF_SUCCESS )
		{
			printf("close_board: hackrf_close() failed: %s (%d)\n", hackrf_error_name(result), result);
			return(-1);
		}

    return(0);
	} else {
	  return(-1);
	}
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

inline int hackrf_config_run_board(uint64_t freq_hz, int gain, void **rf_dev) {
  hackrf_device *dev = NULL;
  
  (*rf_dev) = NULL;
  
  if (hackrf_init_board() != 0) {
    return(-1);
  }
  
  if ( hackrf_open_board(freq_hz, gain, &dev) != 0 ) {
 //   (*rf_dev) = dev;
    return(-1);
  }

//  (*rf_dev) = dev;
  if ( hackrf_run_board(dev) != 0 ) {
    return(-1);
  }
  
  (*rf_dev) = dev;
  return(0);
}

void hackrf_stop_close_board(void* device){
  //printf("afdafdsa%d\n",device);
  if (device==NULL)
    return;
  //printf("afdafdsa%d\n",device);
  //exit(1);
  if (hackrf_close_board((hackrf_device* )device)!=0){
    return;
  }
  hackrf_exit_board((hackrf_device* )device);
}

#endif
//----------------------------------RF specific operation----------------------------------
