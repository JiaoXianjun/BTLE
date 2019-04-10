#define NUM_BLADERF_BUF_SAMPLE_TX (4096)

int bladerf_config_run_board(struct trx_cfg_op *trx);
void bladerf_stop_close_board(void *tmp);
