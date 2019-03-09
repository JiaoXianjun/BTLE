#define HACKRF_MAX_GAIN 62
#define HACKRF_DEFAULT_GAIN 6
#define HACKRF_MAX_LNA_GAIN 40

inline int hackrf_config_run_board(uint64_t freq_hz, int gain, void **rf_dev);
void hackrf_stop_close_board(void* device);
int hackrf_tune(void *device, uint64_t freq_hz);
