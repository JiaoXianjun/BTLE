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


void save_phy_sample(char *IQ_sample, int num_IQ_sample, char *filename)
{
  int i;

  FILE *fp = fopen(filename, "w");
  if (fp == NULL) {
    printf("save_phy_sample: fopen failed!\n");
    return;
  }

  for(i=0; i<num_IQ_sample; i++) {
    if (i%24 == 0) {
      fprintf(fp, "\n");
    }
    fprintf(fp, "%d, ", IQ_sample[i]);
  }
  fprintf(fp, "\n");

  fclose(fp);
}

void save_phy_sample_for_matlab(char *IQ_sample, int num_IQ_sample, char *filename)
{
  int i;

  FILE *fp = fopen(filename, "w");
  if (fp == NULL) {
    printf("save_phy_sample_for_matlab: fopen failed!\n");
    return;
  }

  for(i=0; i<num_IQ_sample; i++) {
    if (i%24 == 0) {
      fprintf(fp, "...\n");
    }
    fprintf(fp, "%d ", IQ_sample[i]);
  }
  fprintf(fp, "\n");

  fclose(fp);
}

int read_items_from_file(int *num_items, char **items_buf, int num_row, char *filename){

  FILE *fp = fopen(filename, "r");

  char file_line[MAX_NUM_CHAR_CMD*2];

  if (fp == NULL) {
    printf("fopen failed!\n");
    return(-1);
  }

  int num_lines = 0;
  char *p = (char *)12345;

  while( 1 ) {
    memset(file_line, 0, MAX_NUM_CHAR_CMD*2);
    p = fgets(file_line,  (MAX_NUM_CHAR_CMD*2), fp );

    if ( file_line[(MAX_NUM_CHAR_CMD*2)-1] != 0 ) {
      printf("A line is too long!\n");
      fclose(fp);
      return(-1);
    }

    if ( p==NULL ) {
      break;
    }

    if (file_line[0] != '#') {
      if ( (file_line[0] >= 48 && file_line[0] <= 57) || file_line[0] ==114 || file_line[0] == 82 ) { // valid line
        if (strlen(file_line) >= MAX_NUM_CHAR_CMD) {
          printf("A line is too long!\n");
          fclose(fp);
          return(-1);
        } else {

          if (num_lines == (num_row-1) ) {
            printf("Too many lines!\n");
            fclose(fp);
            return(-1);
          }

          strcpy(items_buf[num_lines + 1], file_line);
          num_lines++;
        }
      }
    }

    if (feof(fp)) {
      break;
    }
  }

  fclose(fp);

  (*num_items) = num_lines + 1;

  return(0);
}

char ** malloc_2d(int num_row, int num_col) {
  int i, j;

  char **items = (char **)malloc(num_row * sizeof(char *));

  if (items == NULL) {
    return(NULL);
  }

  for (i=0; i<num_row; i++) {
    items[i] = (char *)malloc( num_col * sizeof(char));

    if (items[i] == NULL) {
      for (j=i-1; j>=0; j--) {
        free(items[i]);
      }
      return(NULL);
    }
  }

  return(items);
}

void release_2d(char **items, int num_row) {
  int i;
  for (i=0; i<num_row; i++){
    free((char *) items[i]);
  }
  free ((char *) items);
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


char* get_next_field(char *str_input, char *p_out, char *seperator, int size_of_p_out) {
  char *tmp_p = strstr(str_input, seperator);

  if (tmp_p == str_input){
    printf("Duplicated seperator %s!\n", seperator);
    return(NULL);
  } else if (tmp_p == NULL) {
    if (strlen(str_input) > (size_of_p_out-1) ) {
      printf("Number of input exceed output buffer!\n");
      return(NULL);
    } else {
      strcpy(p_out, str_input);
      return(str_input);
    }
  }

  if ( (tmp_p-str_input)>(size_of_p_out-1) ) {
    printf("Number of input exceed output buffer!\n");
    return(NULL);
  }

  char *p;
  for (p=str_input; p<tmp_p; p++) {
    p_out[p-str_input] = (*p);
  }
  p_out[p-str_input] = 0;

  return(tmp_p+1);
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

int bit_to_int(char *bit) {
  int n = 0;
  int i;
  for(i=0; i<8; i++) {
    n = ( (n<<1) | bit[7-i] );
  }
  return(n);
}

void int_to_bit(int n, char *bit) {
  bit[0] = 0x01&(n>>0);
  bit[1] = 0x01&(n>>1);
  bit[2] = 0x01&(n>>2);
  bit[3] = 0x01&(n>>3);
  bit[4] = 0x01&(n>>4);
  bit[5] = 0x01&(n>>5);
  bit[6] = 0x01&(n>>6);
  bit[7] = 0x01&(n>>7);
}

int convert_hex_to_bit(char *hex, char *bit){
  int num_hex_orig = strlen(hex);
  //while(hex[num_hex-1]<=32 || hex[num_hex-1]>=127) {
  //  num_hex--;
  //}
  int i, num_hex;
  num_hex = num_hex_orig;
  for(i=0; i<num_hex_orig; i++) {
    if ( !( (hex[i]>=48 && hex[i]<=57) || (hex[i]>=65 && hex[i]<=70) || (hex[i]>=97 && hex[i]<=102) ) ) //not a hex
      num_hex--;
  }

  if (num_hex%2 != 0) {
    printf("convert_hex_to_bit: Half octet is encountered! num_hex %d\n", num_hex);
    printf("%s\n", hex);
    return(-1);
  }

  int num_bit = num_hex*4;

  int j;
  for (i=0; i<num_hex; i=i+2) {
    j = i*4;
    octet_hex_to_bit(hex+i, bit+j);
  }

  return(num_bit);
}

char* get_next_field_value(char *current_p, int *value_return, int *return_flag) {
// return_flag: -1 failed; 0 success; 1 success and this is the last field
  char *next_p = get_next_field(current_p, tmp_str, "-", MAX_NUM_CHAR_CMD);
  if (next_p == NULL) {
    (*return_flag) = -1;
    return(next_p);
  }

  (*value_return) = atol(tmp_str);

  if (next_p == current_p) {
    (*return_flag) = 1;
    return(next_p);
  }

  (*return_flag) = 0;
  return(next_p);
}

char* get_next_field_name(char *current_p, char *name, int *return_flag) {
// return_flag: -1 failed; 0 success; 1 success and this is the last field
  char *next_p = get_next_field(current_p, tmp_str, "-", MAX_NUM_CHAR_CMD);
  if (next_p == NULL) {
    (*return_flag) = -1;
    return(next_p);
  }
  if (strcmp(toupper_str(tmp_str, tmp_str), name) != 0) {
//    printf("%s field is expected!\n", name);
    (*return_flag) = -1;
    return(next_p);
  }

  if (next_p == current_p) {
    (*return_flag) = 1;
    return(next_p);
  }

  (*return_flag) = 0;
  return(next_p);
}

char* get_next_field_char(char *current_p, char *bit_return, int *num_bit_return, int stream_flip, int octet_limit, int *return_flag) {
// return_flag: -1 failed; 0 success; 1 success and this is the last field
// stream_flip: 0: normal order; 1: flip octets order in sequence
  int i;
  char *next_p = get_next_field(current_p, tmp_str, "-", MAX_NUM_CHAR_CMD);
  if (next_p == NULL) {
    (*return_flag) = -1;
    return(next_p);
  }
  int num_hex = strlen(tmp_str);
  while(tmp_str[num_hex-1]<=32 || tmp_str[num_hex-1]>=127) {
    num_hex--;
  }

  if ( num_hex>octet_limit ) {
    printf("Too many octets(char)! Maximum allowed is %d\n", octet_limit);
    (*return_flag) = -1;
    return(next_p);
  }
  if (num_hex <= 1) { // NULL data
    (*return_flag) = 0;
    (*num_bit_return) = 0;
    return(next_p);
  }

  if (stream_flip == 1) {
    for (i=0; i<num_hex; i++) {
      int_to_bit(tmp_str[num_hex-i-1], bit_return + 8*i);
    }
  } else {
    for (i=0; i<num_hex; i++) {
      int_to_bit(tmp_str[i], bit_return + 8*i);
    }
  }

  (*num_bit_return) = 8*num_hex;

  if (next_p == current_p) {
    (*return_flag) = 1;
    return(next_p);
  }

  (*return_flag) = 0;
  return(next_p);
}

char* get_next_field_bit_part_flip(char *current_p, char *bit_return, int *num_bit_return, int stream_flip, int octet_limit, int *return_flag) {
// return_flag: -1 failed; 0 success; 1 success and this is the last field
// stream_flip: 0: normal order; 1: flip octets order in sequence
  int i;
  char *next_p = get_next_field(current_p, tmp_str, "-", MAX_NUM_CHAR_CMD);
  if (next_p == NULL) {
    (*return_flag) = -1;
    return(next_p);
  }
  int num_hex = strlen(tmp_str);
   while(tmp_str[num_hex-1]<=32 || tmp_str[num_hex-1]>=127) {
     num_hex--;
   }

   if (num_hex%2 != 0) {
     printf("get_next_field_bit: Half octet is encountered! num_hex %d\n", num_hex);
     printf("%s\n", tmp_str);
     (*return_flag) = -1;
     return(next_p);
   }

  if ( num_hex>(octet_limit*2) ) {
    printf("Too many octets! Maximum allowed is %d\n", octet_limit);
    (*return_flag) = -1;
    return(next_p);
  }
  if (num_hex <= 1) { // NULL data
    (*return_flag) = 0;
    (*num_bit_return) = 0;
    return(next_p);
  }

  int num_bit_tmp;

  num_hex = 2*stream_flip;
  strcpy(tmp_str1, tmp_str);
  for (i=0; i<num_hex; i=i+2) {
    tmp_str[num_hex-i-2] = tmp_str1[i];
    tmp_str[num_hex-i-1] = tmp_str1[i+1];
  }

  num_bit_tmp = convert_hex_to_bit(tmp_str, bit_return);
  if ( num_bit_tmp == -1 ) {
    (*return_flag) = -1;
    return(next_p);
  }
  (*num_bit_return) = num_bit_tmp;

  if (next_p == current_p) {
    (*return_flag) = 1;
    return(next_p);
  }

  (*return_flag) = 0;
  return(next_p);
}

char* get_next_field_bit(char *current_p, char *bit_return, int *num_bit_return, int stream_flip, int octet_limit, int *return_flag) {
// return_flag: -1 failed; 0 success; 1 success and this is the last field
// stream_flip: 0: normal order; 1: flip octets order in sequence
  int i;
  char *next_p = get_next_field(current_p, tmp_str, "-", MAX_NUM_CHAR_CMD);
  if (next_p == NULL) {
    (*return_flag) = -1;
    return(next_p);
  }
  int num_hex = strlen(tmp_str);
   while(tmp_str[num_hex-1]<=32 || tmp_str[num_hex-1]>=127) {
     num_hex--;
   }

   if (num_hex%2 != 0) {
     printf("get_next_field_bit: Half octet is encountered! num_hex %d\n", num_hex);
     printf("%s\n", tmp_str);
     (*return_flag) = -1;
     return(next_p);
   }

  if ( num_hex>(octet_limit*2) ) {
    printf("Too many octets! Maximum allowed is %d\n", octet_limit);
    (*return_flag) = -1;
    return(next_p);
  }
  if (num_hex <= 1) { // NULL data
    (*return_flag) = 0;
    (*num_bit_return) = 0;
    return(next_p);
  }

  int num_bit_tmp;
  if (stream_flip == 1) {
     strcpy(tmp_str1, tmp_str);
    for (i=0; i<num_hex; i=i+2) {
      tmp_str[num_hex-i-2] = tmp_str1[i];
      tmp_str[num_hex-i-1] = tmp_str1[i+1];
    }
  }
  num_bit_tmp = convert_hex_to_bit(tmp_str, bit_return);
  if ( num_bit_tmp == -1 ) {
    (*return_flag) = -1;
    return(next_p);
  }
  (*num_bit_return) = num_bit_tmp;

  if (next_p == current_p) {
    (*return_flag) = 1;
    return(next_p);
  }

  (*return_flag) = 0;
  return(next_p);
}

char *get_next_field_name_value(char *input_p, char *name, int *val, int *ret_last){
// ret_last: -1 failed; 0 success; 1 success and this is the last field
  int ret;
  char *current_p = input_p;

  char *next_p = get_next_field_name(current_p, name, &ret);
  if (ret != 0) { // failed or the last
    (*ret_last) = -1;
    return(NULL);
  }

  current_p = next_p;
  next_p = get_next_field_value(current_p, val, &ret);
  (*ret_last) = ret;
  if (ret == -1) { // failed
    return(NULL);
  }

  return(next_p);
}

char* get_next_field_hex(char *current_p, char *hex_return, int stream_flip, int octet_limit, int *return_flag) {
// return_flag: -1 failed; 0 success; 1 success and this is the last field
// stream_flip: 0: normal order; 1: flip octets order in sequence
  int i;
  char *next_p = get_next_field(current_p, tmp_str, "-", MAX_NUM_CHAR_CMD);
  if (next_p == NULL) {
    (*return_flag) = -1;
    return(next_p);
  }
  int num_hex = strlen(tmp_str);
  while(tmp_str[num_hex-1]<=32 || tmp_str[num_hex-1]>=127) {
    num_hex--;
  }

  if (num_hex%2 != 0) {
    printf("get_next_field_hex: Half octet is encountered! num_hex %d\n", num_hex);
    printf("%s\n", tmp_str);
    (*return_flag) = -1;
    return(next_p);
  }

  if ( num_hex>(octet_limit*2) ) {
    printf("Too many octets! Maximum allowed is %d\n", octet_limit);
    (*return_flag) = -1;
    return(next_p);
  }

  if (stream_flip == 1) {
    strcpy(tmp_str1, tmp_str);
    for (i=0; i<num_hex; i=i+2) {
      tmp_str[num_hex-i-2] = tmp_str1[i];
      tmp_str[num_hex-i-1] = tmp_str1[i+1];
    }
  }

  strcpy(hex_return, tmp_str);
  hex_return[num_hex] = 0;

  if (next_p == current_p) {
    (*return_flag) = 1;
    return(next_p);
  }

  (*return_flag) = 0;
  return(next_p);
}

char *get_next_field_name_char(char *input_p, char *name, char *out_bit, int *num_bit, int flip_flag, int octet_limit, int *ret_last){
// ret_last: -1 failed; 0 success; 1 success and this is the last field
  int ret;
  char *current_p = input_p;

  char *next_p = get_next_field_name(current_p, name, &ret);
  if (ret != 0) { // failed or the last
    (*ret_last) = -1;
    return(NULL);
  }

  current_p = next_p;
  next_p = get_next_field_char(current_p, out_bit, num_bit, flip_flag, octet_limit, &ret);
  (*ret_last) = ret;
  if (ret == -1) { // failed
    return(NULL);
  }

  return(next_p);
}

char *get_next_field_name_hex(char *input_p, char *name, char *out_hex, int flip_flag, int octet_limit, int *ret_last){
// ret_last: -1 failed; 0 success; 1 success and this is the last field
  int ret;
  char *current_p = input_p;

  char *next_p = get_next_field_name(current_p, name, &ret);
  if (ret != 0) { // failed or the last
    (*ret_last) = -1;
    return(NULL);
  }

  current_p = next_p;
  next_p = get_next_field_hex(current_p, out_hex, flip_flag, octet_limit, &ret);
  (*ret_last) = ret;
  if (ret == -1) { // failed
    return(NULL);
  }

  return(next_p);
}

char *get_next_field_name_bit_part_flip(char *input_p, char *name, char *out_bit, int *num_bit, int flip_flag, int octet_limit, int *ret_last){
// ret_last: -1 failed; 0 success; 1 success and this is the last field
  int ret;
  char *current_p = input_p;

  char *next_p = get_next_field_name(current_p, name, &ret);
  if (ret != 0) { // failed or the last
    (*ret_last) = -1;
    return(NULL);
  }

  current_p = next_p;
  next_p = get_next_field_bit_part_flip(current_p, out_bit, num_bit, flip_flag, octet_limit, &ret);
  (*ret_last) = ret;
  if (ret == -1) { // failed
    return(NULL);
  }

  return(next_p);
}

char *get_next_field_name_bit(char *input_p, char *name, char *out_bit, int *num_bit, int flip_flag, int octet_limit, int *ret_last){
// ret_last: -1 failed; 0 success; 1 success and this is the last field
  int ret;
  char *current_p = input_p;

  char *next_p = get_next_field_name(current_p, name, &ret);
  if (ret != 0) { // failed or the last
    (*ret_last) = -1;
    return(NULL);
  }

  current_p = next_p;
  next_p = get_next_field_bit(current_p, out_bit, num_bit, flip_flag, octet_limit, &ret);
  (*ret_last) = ret;
  if (ret == -1) { // failed
    return(NULL);
  }

  return(next_p);
}

int get_num_repeat(char *input_str, int *repeat_specific){
  int num_repeat;

  if (input_str[0] == 'r' || input_str[0] == 'R') {
    num_repeat = atol(input_str+1);
    (*repeat_specific) = 1;

    if (strlen(input_str)>1) {
      if (num_repeat < -1) {
        num_repeat = 1;
        printf("Detect num_repeat < -1! (-1 means inf). Set to %d\n", num_repeat);
      } else if (num_repeat == 0) {
        num_repeat = 1;
        if ( input_str[1] == '0') {
          printf("Detect num_repeat = 0! (-1 means inf). Set to %d\n", num_repeat);
        } else {
          printf("Detect invalid num_repeat! (-1 means inf). Set to %d\n", num_repeat);
        }
      }
    } else {
      num_repeat = 1;
      printf("num_repeat not specified! (-1 means inf). Set to %d\n", num_repeat);
    }
  } else if (isdigit(input_str[0])) {
    (*repeat_specific) = 0;
    num_repeat = 1;
    printf("num_repeat not specified! (-1 means inf). Set to %d\n", num_repeat);
  } else {
    num_repeat = -2;
    printf("Invalid last parameter! (It should be num_repeat. -1 means inf)\n");
  }

  return(num_repeat);
}

int get_word(char *base, char **target, int max_num_word, int max_len_word)
{
  char *token;
  int i = 0;
  for(token = strtok(base, " "); token != NULL; token = strtok(NULL, " ")) {
    if (strlen(token)>=max_len_word) {
      fprintf(stderr, "get_word: strlen(token)>=max_len_word\n");
      return(-1);
    } else {
      strcpy(target[i],token);
      i++;
      if (i>=max_num_word) {
        fprintf(stderr, "get_word: Warning! reach %d words!\n", i);
      }
    }
  }
  return(0);
}