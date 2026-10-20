#include <stdio.h>
#include <omp.h>

/* thread 0 of the region reports its size */
void report(int r) {
  if (omp_get_thread_num() == 0)
    printf("region %d: %d threads\n",
           r, omp_get_num_threads());
}

int main(void) {
#pragma omp parallel
  report(1);

  omp_set_num_threads(3);
#pragma omp parallel
  report(2);

#pragma omp parallel num_threads(2)
  report(3);
  return 0;
}