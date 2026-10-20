#include <stdio.h>
#include <stdlib.h>
#include <omp.h>

int main(void) {
  int n = 100000000;
  double *a = malloc(n * sizeof(double));
  for (int i = 0; i < n; i++) a[i] = 1.0;

  double sum = 0.0;             /* shared, but reduced: see the clause */
#pragma omp parallel for reduction(+:sum)
  for (int i = 0; i < n; i++)
    sum += a[i];

  printf("sum = %.0f (expected %d)\n", sum, n);
  free(a);
  return 0;
}
