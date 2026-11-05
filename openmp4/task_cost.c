/* Cost of one task: create and run m empty tasks from one thread, p threads. */
#include <stdio.h>
#include <stdlib.h>
#include <omp.h>

int main(int argc, char **argv) {
  long m = (argc > 1) ? atol(argv[1]) : 1000000L;
  int p = (argc > 2) ? atoi(argv[2]) : 1;
  omp_set_num_threads(p);
  volatile long sink = 0;
  double t0 = omp_get_wtime();
#pragma omp parallel
#pragma omp single
  for (long i = 0; i < m; i++) {
#pragma omp task
    sink += 0;                       /* an empty task */
  }
  double t = omp_get_wtime() - t0;
  printf("%ld tasks, p = %2d: %.3f s, %.2f us per task\n", m, p, t, t / m * 1e6);
  return 0;
}
