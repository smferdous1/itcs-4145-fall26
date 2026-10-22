/* Which thread runs which iteration? n = 16, p = 4, schedule from OMP_SCHEDULE.
   Each iteration does a little work so that threads really compete. */
#include <stdio.h>
#include <omp.h>

int main(void) {
  int n = 16, who[16];
  omp_set_num_threads(4);
#pragma omp parallel for schedule(runtime)
  for (int i = 0; i < n; i++) {
    volatile double x = 0;
    for (int k = 0; k < 200000; k++) x += k;   /* same work per iteration */
    who[i] = omp_get_thread_num();
  }
  for (int i = 0; i < n; i++) printf("%d ", who[i]);
  printf("\n");
  return 0;
}
