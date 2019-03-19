inline int hackrf_config_run_board(uint64_t freq_hz, int gain, void **rf_dev, bool trx_flag);
void hackrf_stop_close_board(void* device, bool trx_flag);
int hackrf_tune(void *device, uint64_t freq_hz);
