#include <stdint.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
// #include <time.h>
#include <ctype.h>
// #include <math.h>
// #include <getopt.h>

#include "common_misc.h"

inline int TimevalDiff(const struct timeval *a, const struct timeval *b)
{
   return( (a->tv_sec - b->tv_sec)*1000000 + (a->tv_usec - b->tv_usec) );
}

char* toupper_str(char *input_str, char *output_str) {
  int len_str = strlen(input_str);
  int i;

  for (i=0; i<=len_str; i++) {
    output_str[i] = toupper( input_str[i] );
  }

  return(output_str);
}

void octet_hex_to_bit(char *hex, char *bit) {
  char tmp_hex[3];

  tmp_hex[0] = hex[0];
  tmp_hex[1] = hex[1];
  tmp_hex[2] = 0;

  int n = strtol(tmp_hex, NULL, 16);

  bit[0] = 0x01&(n>>0);
  bit[1] = 0x01&(n>>1);
  bit[2] = 0x01&(n>>2);
  bit[3] = 0x01&(n>>3);
  bit[4] = 0x01&(n>>4);
  bit[5] = 0x01&(n>>5);
  bit[6] = 0x01&(n>>6);
  bit[7] = 0x01&(n>>7);
}

void int_to_bit(int n, uint8_t *bit) {
  bit[0] = 0x01&(n>>0);
  bit[1] = 0x01&(n>>1);
  bit[2] = 0x01&(n>>2);
  bit[3] = 0x01&(n>>3);
  bit[4] = 0x01&(n>>4);
  bit[5] = 0x01&(n>>5);
  bit[6] = 0x01&(n>>6);
  bit[7] = 0x01&(n>>7);
}

void uint32_to_bit_array(uint32_t uint32_in, uint8_t *bit) {
  int i;
  uint32_t uint32_tmp = uint32_in;
  for(i=0; i<32; i++) {
    bit[i] = 0x01&uint32_tmp;
    uint32_tmp = (uint32_tmp>>1);
  }
}

void byte_array_to_bit_array(uint8_t *byte_in, int num_byte, uint8_t *bit) {
  int i, j;
  j=0;
  for(i=0; i<num_byte*8; i=i+8) {
    int_to_bit(byte_in[j], bit+i);
    j++;
  }
}

int convert_hex_to_bit(char *hex, char *bit){
  int num_hex = strlen(hex);
  while(hex[num_hex-1]<=32 || hex[num_hex-1]>=127) {
    num_hex--;
  }

  if (num_hex%2 != 0) {
    printf("convert_hex_to_bit: Half octet is encountered! num_hex %d\n", num_hex);
    printf("%s\n", hex);
    return(-1);
  }

  int num_bit = num_hex*4;

  int i, j;
  for (i=0; i<num_hex; i=i+2) {
    j = i*4;
    octet_hex_to_bit(hex+i, bit+j);
  }

  return(num_bit);
}

void disp_bit(char *bit, int num_bit)
{
  int i, bit_val;
  for(i=0; i<num_bit; i++) {
    bit_val = bit[i];
    if (i%8 == 0 && i != 0) {
      printf(" ");
    } else if (i%4 == 0 && i != 0) {
      printf("-");
    }
    printf("%d", bit_val);
  }
  printf("\n");
}

void disp_bit_in_hex(char *bit, int num_bit)
{
  int i, a;
  for(i=0; i<num_bit; i=i+8) {
    a = bit[i] + bit[i+1]*2 + bit[i+2]*4 + bit[i+3]*8 + bit[i+4]*16 + bit[i+5]*32 + bit[i+6]*64 + bit[i+7]*128;
    //a = bit[i+7] + bit[i+6]*2 + bit[i+5]*4 + bit[i+4]*8 + bit[i+3]*16 + bit[i+2]*32 + bit[i+1]*64 + bit[i]*128;
    printf("%02x", a);
  }
  printf("\n");
}

void disp_hex(uint8_t *hex, int num_hex)
{
  int i;
  for(i=0; i<num_hex; i++)
  {
     printf("%02x", hex[i]);
  }
  printf("\n");
}

void disp_hex_in_bit(uint8_t *hex, int num_hex)
{
  int i, j, bit_val;

  for(j=0; j<num_hex; j++) {

    for(i=0; i<8; i++) {
      bit_val = (hex[j]>>i)&0x01;
      if (i==4) {
        printf("-");
      }
      printf("%d", bit_val);
    }

    printf(" ");

  }

  printf("\n");
}

void save_phy_sample(IQ_TYPE *IQ_sample, int num_IQ_sample, char *filename)
{
  int i;

  FILE *fp = fopen(filename, "w");
  if (fp == NULL) {
    printf("save_phy_sample: fopen failed!\n");
    return;
  }

  for(i=0; i<num_IQ_sample; i++) {
    if (i%64 == 0) {
      fprintf(fp, "\n");
    }
    fprintf(fp, "%d, ", IQ_sample[i]);
  }
  fprintf(fp, "\n");

  fclose(fp);
}

void load_phy_sample(IQ_TYPE *IQ_sample, int num_IQ_sample, char *filename)
{
  int i, tmp_val;

  FILE *fp = fopen(filename, "r");
  if (fp == NULL) {
    printf("load_phy_sample: fopen failed!\n");
    return;
  }

  i = 0;
  while( ~feof(fp) ) {
    if ( fscanf(fp, "%d,", &tmp_val) ) {
      IQ_sample[i] = tmp_val;
      i++;
    }
    if (num_IQ_sample != -1) {
      if (i==num_IQ_sample) {
        break;
      }
    }
    //printf("%d\n", i);
  }
  printf("%d I/Q are read.\n", i);

  fclose(fp);
}

void save_phy_sample_for_matlab(IQ_TYPE *IQ_sample, int num_IQ_sample, char *filename)
{
  int i;

  FILE *fp = fopen(filename, "w");
  if (fp == NULL) {
    printf("save_phy_sample_for_matlab: fopen failed!\n");
    return;
  }

  for(i=0; i<num_IQ_sample; i++) {
    if (i%64 == 0) {
      fprintf(fp, "...\n");
    }
    fprintf(fp, "%d ", IQ_sample[i]);
  }
  fprintf(fp, "\n");

  fclose(fp);
}
//----------------------------------MISC MISC MISC----------------------------------
