
inline int usrp_config_run_board(uint64_t freq_hz, char *device_args, int gain_input, void **rf_dev);
void usrp_stop_close_board(void *dev);
int usrp_tune_rx(void *dev, uint64_t freq_hz);
int usrp_tune_tx(void *dev, uint64_t freq_hz);
