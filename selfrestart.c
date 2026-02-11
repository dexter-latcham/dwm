#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <stdio.h>
#include <stdlib.h>

void self_restart(const Arg *arg){
  char *const argv[] = {"/run/current-system/sw/bin/dwm",NULL};
  execv(argv[0],argv);
}
