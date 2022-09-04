#include <stdio.h>
#include <stdlib.h>

int main () {
  int ret = system("./rf_probe");
  printf("%d\n", WEXITSTATUS(ret)); //valid value range 0~255 (from rf_probe.c)
  return(0);
}
