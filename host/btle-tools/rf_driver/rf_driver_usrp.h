
inline int usrp_config_run_board(uint64_t freq_hz, int gain, int sampl_rate, int bw, int trx_flag, void **rf_dev);
void usrp_stop_close_board(void *dev, int trx_flag);
int usrp_tune_rx(void *dev, uint64_t freq_hz);
int usrp_tune_tx(void *dev, uint64_t freq_hz);
