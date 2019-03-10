inline int hackrf_config_run_board(uint64_t freq_hz, int gain, void **rf_dev);
void hackrf_stop_close_board(void* device);
int hackrf_tune(void *device, uint64_t freq_hz);
