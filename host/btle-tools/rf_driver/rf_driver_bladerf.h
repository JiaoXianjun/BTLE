
struct bladerf_data
{
    void                **buffers;      /* Transmit buffers */
    size_t              num_buffers;    /* Number of buffers */
    size_t              samples_per_buffer; /* Number of samples per buffer */
    unsigned int        idx;            /* The next one that needs to go out */
};

inline int bladerf_config_run_board(uint64_t freq_hz, int gain, int sampl_rate, int bw, int trx_flag, void **rf_dev);
void bladerf_stop_close_board(void *dev, int trx_flag);
int bladerf_tune_rx(void *dev, uint64_t freq_hz);
int bladerf_tune_tx(void *dev, uint64_t freq_hz);
