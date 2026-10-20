/* OpenMP sum, timed as the pthreads sum_time.c was: n = 2e8 doubles filled
   by main, parallel phase only, best of five, p from the command line.
   Build unoptimized (make), as in the pthreads unit. */
#include <stdio.h>
#include <stdlib.h>
#include <omp.h>

int main(int argc, char **argv) {
  int p = (argc > 1) ? atoi(argv[1]) : 1;
  long n = 200000000L;
  double *a = malloc(n * sizeof(double));
  for (long i = 0; i < n; i++) a[i] = 1.0;      /* main touches the array */

  omp_set_num_threads(p);
  double best = 1e9, sum = 0.0;
  for (int rep = 0; rep < 5; rep++) {
    sum = 0.0;
    double t0 = omp_get_wtime();
#pragma omp parallel for reduction(+:sum)
    for (long i = 0; i < n; i++)
      sum += a[i];
    double t = omp_get_wtime() - t0;
    if (t < best) best = t;
  }
  printf("p = %2d  time = %.4f s  sum = %.0f\n", p, best, sum);
  free(a);
  return 0;
}
