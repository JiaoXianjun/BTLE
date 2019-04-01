#include <stdint.h>

#define HACKRF_MAX_GAIN 62
#define HACKRF_DEFAULT_RX_GAIN 6
#define HACKRF_DEFAULT_TX_GAIN 47
#define HACKRF_MAX_LNA_GAIN 40

#define BLADERF_MAX_GAIN 60
#define BLADERF_DEFAULT_RX_GAIN 45
#define BLADERF_DEFAULT_TX_GAIN 57

#define USRP_DEFAULT_RX_GAIN 60
#define USRP_DEFAULT_TX_GAIN 83

enum rf_type {HACKRF=0, BLADERF=1, USRP=2, NOTVALID=3}; 

struct rf_cfg_op {
    bool en;
    uint64_t freq; // center frequency Hz
    int gain; //dB or depends on hardware
    int rate; //sampling rate Hz
    int bw; //bandwidth in Hz
    int num_sample_app_buf;
    int num_sample_app_buf_tail;
    volatile int app_buf_offset;
    int num_sample_dev_buf;
    volatile void *app_buf;
    void *dev_buf;
    void *streamer;
    void *metadata;
    void *dev;
    pthread_mutex_t callback_lock;
    pthread_t tid;
    int (*update_freq)( void *rf, uint64_t freq); // if input is not valid, get it back
    int (*update_gain)( void *rf, int gain); // if input is not valid, get it back
    int (*update_rate)( void *rf, int rate); // if input is not valid, get it back
    int (*update_bw)(   void *rf, int bw); // if input is not valid, get it back
    int (*proc_one_buf)(void *rf, void *buf, int *len); // do tx or rx one buf
};

struct trx_cfg_op {
    struct rf_cfg_op tx;
    struct rf_cfg_op rx;
    char *arg_string;
    enum rf_type hw_type;
    int (*stop_close)(void *trx);
};

void probe_run_rf(struct trx_cfg_op *trx);
