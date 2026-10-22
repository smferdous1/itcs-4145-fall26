#include <stdio.h>
#include <stdlib.h>
#include <omp.h>

int main(void) {
  int n = 10000000;
  double *a = malloc(n * sizeof(double));
  double *b = malloc(n * sizeof(double));
  for (int i = 0; i < n; i++) a[i] = i;

  double t;                     /* temporary, declared before the loop */
#pragma omp parallel for
  for (int i = 0; i < n; i++) {
    t = a[i] * a[i];
    b[i] = t + 1.0;
  }

  long wrong = 0;
  for (int i = 0; i < n; i++)
    if (b[i] != a[i] * a[i] + 1.0) wrong++;
  printf("wrong elements: %ld of %d\n", wrong, n);
  free(a); free(b);
  return 0;
}
