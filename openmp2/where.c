/* On which core does each thread run? sched_getcpu() per thread, twice. */
#define _GNU_SOURCE
#include <stdio.h>
#include <sched.h>
#include <omp.h>

int main(void) {
  for (int rep = 0; rep < 2; rep++) {
#pragma omp parallel
    {
      int id = omp_get_thread_num();
      volatile double x = 0;
      for (int k = 0; k < 50000000; k++) x += 1.0;   /* give the scheduler time to move us */
#pragma omp for ordered schedule(static,1)
      for (int t = 0; t < omp_get_num_threads(); t++) {
#pragma omp ordered
        printf("thread %2d on core %2d%s", id, sched_getcpu(), t == omp_get_num_threads()-1 ? "\n" : "   ");
      }
    }
  }
  return 0;
}
