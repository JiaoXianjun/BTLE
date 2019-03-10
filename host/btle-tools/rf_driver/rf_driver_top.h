#include <stdint.h>

#define HACKRF_MAX_GAIN 62
#define HACKRF_DEFAULT_GAIN 6
#define HACKRF_MAX_LNA_GAIN 40

#define BLADERF_MAX_GAIN 60
#define BLADERF_DEFAULT_GAIN 45

#define USRP_DEFAULT_GAIN 60

enum rf_type {HACKRF=0, BLADERF=1, USRP=2, NOTVALID=3}; 

int rf_tune(void *dev, uint64_t freq_hz);
void stop_close_rf(void *dev);
void probe_run_rf(void **rf_dev, uint64_t freq_hz, char *arg_string, int *gain, enum rf_type* rf_in_use);
