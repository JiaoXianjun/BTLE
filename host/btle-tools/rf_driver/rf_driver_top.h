#include <stdint.h>

#define HACKRF_MAX_GAIN 62
#define HACKRF_DEFAULT_GAIN 6
#define HACKRF_MAX_LNA_GAIN 40

#define BLADERF_MAX_GAIN 60
#define BLADERF_DEFAULT_GAIN 45

#define USRP_DEFAULT_GAIN 60

enum rf_type {HACKRF=0, BLADERF=1, USRP=2, NOTVALID=3}; 

struct unit_trx_cfg {
    uint64_t freq_hz;
    int gain;
    int sampl_rate;
    int bw;
};

struct transceiver_cfg {
    struct unit_trx_cfg tx;
    struct unit_trx_cfg rx;
    bool tx_en;
    bool rx_en;
};

int rf_tune_rx(void *dev, uint64_t freq_hz);
int rf_tune_tx(void *dev, uint64_t freq_hz);
void stop_close_rf(void *dev, int trx_flag);
void probe_run_rf(char *arg_string, uint64_t freq_hz, int *gain, int sampl_rate, int bw, int trx_flag, void **rf_dev, enum rf_type* rf_in_use);
