/* Fibonacci with two child tasks and no join: wrong. */
#include <stdio.h>
#include <stdlib.h>
#include <omp.h>

long fib(int n) {
  if (n < 2) return n;
  long x, y;
#pragma omp task shared(x)
  x = fib(n - 1);
#pragma omp task shared(y)
  y = fib(n - 2);
  return x + y;                    /* x and y may not be computed yet */
}

int main(int argc, char **argv) {
  int n = (argc > 1) ? atoi(argv[1]) : 20;
  long r;
#pragma omp parallel
#pragma omp single
  r = fib(n);
  printf("fib(%d) = %ld\n", n, r);
  return 0;
}
