/* The reduction sum of Lecture 1, with the array initialized either by main
   alone ("seq") or by all threads in a parallel for ("par", first touch by the
   thread that later reads the element). n = 2e8 doubles, parallel phase
   only, best of five. Run with OMP_PROC_BIND=true OMP_PLACES=cores so that a
   thread stays on the core, and socket, where it touched its part. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <omp.h>

int main(int argc, char **argv) {
  int p = (argc > 1) ? atoi(argv[1]) : 1;
  int par = (argc > 2) && strcmp(argv[2], "par") == 0;
  long n = 200000000L;
  double *a = malloc(n * sizeof(double));
  omp_set_num_threads(p);

  if (par) {
#pragma omp parallel for schedule(static)
    for (long i = 0; i < n; i++) a[i] = 1.0;      /* each thread touches its block */
  } else {
    for (long i = 0; i < n; i++) a[i] = 1.0;      /* main touches everything */
  }

  double best = 1e9, sum = 0.0;
  for (int rep = 0; rep < 5; rep++) {
    sum = 0.0;
    double t0 = omp_get_wtime();
#pragma omp parallel for schedule(static) reduction(+:sum)
    for (long i = 0; i < n; i++) sum += a[i];
    double t = omp_get_wtime() - t0;
    if (t < best) best = t;
  }
  printf("%s  p = %2d  time = %.4f s  %.1f GB/s  sum = %.0f\n",
         par ? "par" : "seq", p, best, n * sizeof(double) / best / 1e9, sum);
  free(a);
  return 0;
}
