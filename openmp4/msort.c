/* Merge sort with two child tasks per call, taskwait, sequential merge;
   recursion below the cut-off is sequential. Arguments: n, cut-off, p. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <omp.h>

static long cutoff = 1 << 14;

static void merge(int *a, int *tmp, long lo, long mid, long hi) {
  long i = lo, j = mid, k = lo;
  while (i < mid && j < hi) tmp[k++] = (a[i] <= a[j]) ? a[i++] : a[j++];
  while (i < mid) tmp[k++] = a[i++];
  while (j < hi)  tmp[k++] = a[j++];
  memcpy(a + lo, tmp + lo, (hi - lo) * sizeof(int));
}

static int cmp(const void *x, const void *y) { return (*(const int *)x > *(const int *)y) - (*(const int *)x < *(const int *)y); }

static void msort(int *a, int *tmp, long lo, long hi) {
  if (hi - lo <= cutoff) { qsort(a + lo, hi - lo, sizeof(int), cmp); return; }
  long mid = lo + (hi - lo) / 2;
#pragma omp task
  msort(a, tmp, lo, mid);
#pragma omp task
  msort(a, tmp, mid, hi);
#pragma omp taskwait
  merge(a, tmp, lo, mid, hi);      /* sequential: O(n) on the top level */
}

int main(int argc, char **argv) {
  long n = (argc > 1) ? atol(argv[1]) : 100000000L;
  cutoff = (argc > 2) ? atol(argv[2]) : cutoff;
  int p = (argc > 3) ? atoi(argv[3]) : 1;
  omp_set_num_threads(p);
  int *a = malloc(n * sizeof(int)), *tmp = malloc(n * sizeof(int));
  srand(12345);
  for (long i = 0; i < n; i++) a[i] = rand();
  double t0 = omp_get_wtime();
#pragma omp parallel
#pragma omp single
  msort(a, tmp, 0, n);
  double t = omp_get_wtime() - t0;
  long bad = 0;
  for (long i = 1; i < n; i++) if (a[i-1] > a[i]) bad++;
  printf("n = %ld  cutoff = %ld  p = %2d  time = %.3f s  %s\n", n, cutoff, p, t, bad ? "NOT SORTED" : "sorted");
  free(a); free(tmp);
  return 0;
}
