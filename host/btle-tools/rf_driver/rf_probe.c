#include <stdio.h>
#include "rf_driver_cfg.h"

int main () {
  printf("Hello world!\n");

  #ifdef HAS_HACKRF
  printf("1\n");
  #endif

  #ifdef HAS_BLADERF
  printf("2\n");
  #endif
  
  #ifdef HAS_UHD
  printf("3\n");
  #endif
  
  return(252); // valid value range 0~255 (to be captured by test_rf_probe.c)
}
