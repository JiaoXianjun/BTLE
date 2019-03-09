
#define BLADERF_MAX_GAIN 60
#define BLADERF_DEFAULT_GAIN 45

struct bladerf_data
{
    void                **buffers;      /* Transmit buffers */
    size_t              num_buffers;    /* Number of buffers */
    size_t              samples_per_buffer; /* Number of samples per buffer */
    unsigned int        idx;            /* The next one that needs to go out */
};

inline int bladerf_config_run_board(uint64_t freq_hz, int gain, void **rf_dev);
void bladerf_stop_close_board(void *dev);
int bladerf_tune(void *dev, uint64_t freq_hz);
