#define HACKRF_NUM_PRE_SEND_DATA (256)

int hackrf_config_run_board(uint64_t freq_hz, int gain, int sampl_rate, int bw, int trx_flag, void **rf_dev);
void hackrf_stop_close_board(void* device, int trx_flag);
int hackrf_tune(void *device, uint64_t freq_hz);
