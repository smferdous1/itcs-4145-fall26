/* Parallel filter (compaction): copy the elements above 0.5 into out[],
   each thread claiming the next free slot with atomic capture.
   Checks the result against the sequential filter: same number of elements,
   same set (compared after sorting), and whether the order is the same. */
#include <stdio.h>
#include <stdlib.h>
#include <omp.h>

static int cmp(const void *x, const void *y) {
  double a = *(const double *) x, b = *(const double *) y;
  return (a > b) - (a < b);
}

int main(int argc, char **argv) {
  int p = (argc > 1) ? atoi(argv[1]) : 4;
  long n = 10000000L;
  double *a = malloc(n * sizeof(double));
  double *out = malloc(n * sizeof(double)), *ref = malloc(n * sizeof(double));
  srand(12345);
  for (long i = 0; i < n; i++) a[i] = rand() / (double) RAND_MAX;
  omp_set_num_threads(p);

  long m = 0;                              /* next free slot in out[] */
#pragma omp parallel for
  for (long i = 0; i < n; i++)
    if (a[i] > 0.5) {
      long k;
#pragma omp atomic capture
      k = m++;                             /* my slot, nobody else's */
      out[k] = a[i];
    }

  long mref = 0;                           /* sequential reference */
  for (long i = 0; i < n; i++) if (a[i] > 0.5) ref[mref++] = a[i];

  long first_diff = -1;
  for (long k = 0; k < m && k < mref; k++) if (out[k] != ref[k]) { first_diff = k; break; }
  qsort(out, m, sizeof(double), cmp); qsort(ref, mref, sizeof(double), cmp);
  int same_set = (m == mref);
  for (long k = 0; same_set && k < m; k++) if (out[k] != ref[k]) same_set = 0;

  printf("p = %2d  kept %ld of %ld (sequential: %ld)  same set: %s  same order: %s",
         p, m, n, mref, same_set ? "yes" : "NO", first_diff < 0 ? "yes" : "no");
  if (first_diff >= 0) printf(" (first difference at slot %ld)", first_diff);
  printf("\n");
  free(a); free(out); free(ref);
  return 0;
}
