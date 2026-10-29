/* Count the elements above 0.5 in n = 1e8 random doubles (about n/2
   increments of one shared counter), as in pthreads Lecture 3:
     critical  : critical block around count++
     atomic    : atomic update around count++
     reduction : reduction(+:count)
   gcc -O2, parallel phase only, best of five, p on the command line. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <omp.h>

int main(int argc, char **argv) {
  int p = (argc > 1) ? atoi(argv[1]) : 1;
  const char *mode = (argc > 2) ? argv[2] : "reduction";
  long n = 100000000L;
  double *a = malloc(n * sizeof(double));
  srand(12345);
  for (long i = 0; i < n; i++) a[i] = rand() / (double) RAND_MAX;
  omp_set_num_threads(p);

  double best = 1e9; long count = 0;
  for (int rep = 0; rep < 5; rep++) {
    count = 0;
    double t0 = omp_get_wtime();
    if (strcmp(mode, "critical") == 0) {
#pragma omp parallel for
      for (long i = 0; i < n; i++)
        if (a[i] > 0.5) {
#pragma omp critical
          count++;
        }
    } else if (strcmp(mode, "atomic") == 0) {
#pragma omp parallel for
      for (long i = 0; i < n; i++)
        if (a[i] > 0.5) {
#pragma omp atomic
          count++;
        }
    } else if (strcmp(mode, "reduction") == 0) {
#pragma omp parallel for reduction(+:count)
      for (long i = 0; i < n; i++)
        if (a[i] > 0.5) count++;
    } else { fprintf(stderr, "mode?\n"); return 1; }
    double t = omp_get_wtime() - t0;
    if (t < best) best = t;
  }
  printf("%-9s p = %2d  time = %.4f s  count = %ld\n", mode, p, best, count);
  free(a);
  return 0;
}
