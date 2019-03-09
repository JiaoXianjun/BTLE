#include <stdint.h>

#define SAMPLE_PER_SYMBOL 4 // 4M sampling rate

#define LEN_BUF_IN_SAMPLE (4*4096) //4096 samples = ~1ms for 4Msps; ATTENTION each rx callback get hackrf.c:lib_device->buffer_size samples!!!
#define LEN_BUF (LEN_BUF_IN_SAMPLE*2)

typedef int8_t IQ_TYPE;
