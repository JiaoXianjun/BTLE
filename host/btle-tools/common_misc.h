#include <stdint.h>

#define SAMPLE_PER_SYMBOL 4 // 4M sampling rate

#define LEN_BUF_IN_SAMPLE (4*4096) //4096 samples = ~1ms for 4Msps; ATTENTION each rx callback get hackrf.c:lib_device->buffer_size samples!!!
#define LEN_BUF (LEN_BUF_IN_SAMPLE*2)

#define MAX_NUM_CHAR_CMD (256)

#define MAX_NUM_PACKET (1024)

#define NUM_BLADERF_BUF_SAMPLE_TX 4096

#define HACKRF_ONBOARD_BUF_SIZE_TX (32768) // in usb_bulk_buffer.h
#define HACKRF_USB_BUF_SIZE_TX (4096) // in hackrf.c lib_device->buffer_size

#ifndef bool
typedef int bool;
#define true 1
#define false 0
#endif

typedef int8_t IQ_TYPE;

inline int TimevalDiff(const struct timeval *a, const struct timeval *b);

char* toupper_str(char *input_str, char *output_str);

void octet_hex_to_bit(char *hex, char *bit);

void int_to_bit(int n, uint8_t *bit);

void uint32_to_bit_array(uint32_t uint32_in, uint8_t *bit);

void byte_array_to_bit_array(uint8_t *byte_in, int num_byte, uint8_t *bit);

int convert_hex_to_bit(char *hex, char *bit);

void disp_bit(char *bit, int num_bit);

void disp_bit_in_hex(char *bit, int num_bit);

void disp_hex(uint8_t *hex, int num_hex);

void disp_hex_in_bit(uint8_t *hex, int num_hex);

void save_phy_sample(IQ_TYPE *IQ_sample, int num_IQ_sample, char *filename);

void load_phy_sample(IQ_TYPE *IQ_sample, int num_IQ_sample, char *filename);

void save_phy_sample_for_matlab(IQ_TYPE *IQ_sample, int num_IQ_sample, char *filename);
