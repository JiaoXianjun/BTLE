#include <stdio.h>
#include <stdlib.h>

int main () {
  int ret = system("./rf_probe");
  printf("%d\n", WEXITSTATUS(ret));
  return(0);
}
