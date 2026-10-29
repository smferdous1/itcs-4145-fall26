/* The maximum of n = 2e8 random doubles, a conditional update "store if
   larger", protected three ways:
     critical  : the test and the store inside one critical block, n times
     spec      : test outside; critical block with a re-test only when the
                 element could be the maximum (Traff 2.3.14)
     reduction : reduction(max:m)
   Also "wrong": the unprotected test and store, for the record.
   gcc -O2, parallel phase only, best of five, p on the command line. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <omp.h>

int main(int argc, char **argv) {
  int p = (argc > 1) ? atoi(argv[1]) : 1;
  const char *mode = (argc > 2) ? argv[2] : "reduction";
  long n = 200000000L;
  double *a = malloc(n * sizeof(double));
  srand(12345);
  for (long i = 0; i < n; i++) a[i] = rand() / (double) RAND_MAX;
  double ref = 0.0;
  for (long i = 0; i < n; i++) if (a[i] > ref) ref = a[i];
  omp_set_num_threads(p);

  double best = 1e9, m = 0.0; long entered = 0;
  for (int rep = 0; rep < 5; rep++) {
    m = 0.0; entered = 0;
    double t0 = omp_get_wtime();
    if (strcmp(mode, "critical") == 0) {
#pragma omp parallel for
      for (long i = 0; i < n; i++) {
#pragma omp critical
        if (a[i] > m) m = a[i];
      }
    } else if (strcmp(mode, "spec") == 0) {
#pragma omp parallel for
      for (long i = 0; i < n; i++)
        if (a[i] > m) {                      /* a candidate: rarely */
#pragma omp critical
          { entered++; if (a[i] > m) m = a[i]; }   /* re-test, alone */
        }
    } else if (strcmp(mode, "reduction") == 0) {
#pragma omp parallel for reduction(max:m)
      for (long i = 0; i < n; i++)
        if (a[i] > m) m = a[i];
    } else if (strcmp(mode, "wrong") == 0) {
#pragma omp parallel for
      for (long i = 0; i < n; i++)
        if (a[i] > m) m = a[i];
    } else { fprintf(stderr, "mode?\n"); return 1; }
    double t = omp_get_wtime() - t0;
    if (t < best) best = t;
  }
  printf("%-9s p = %2d  time = %.4f s  max = %.10f  %s", mode, p, best, m,
         m == ref ? "correct" : "WRONG");
  if (strcmp(mode, "spec") == 0) printf("  (critical entered %ld times)", entered);
  printf("\n");
  free(a);
  return 0;
}
