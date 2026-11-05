/* Fibonacci with two child tasks, taskwait, and a cut-off below which the
   recursion is sequential. Arguments: n, cut-off (0 = no cut-off), p. */
#include <stdio.h>
#include <stdlib.h>
#include <omp.h>

static int cutoff = 0;

long fib_seq(int n) { return n < 2 ? n : fib_seq(n - 1) + fib_seq(n - 2); }

long fib(int n) {
  if (n < 2) return n;
  if (cutoff > 0 && n < cutoff) return fib_seq(n);   /* no tasks below the cut-off */
  long x, y;
#pragma omp task shared(x)
  x = fib(n - 1);
#pragma omp task shared(y)
  y = fib(n - 2);
#pragma omp taskwait                                /* both children done */
  return x + y;
}

int main(int argc, char **argv) {
  int n = (argc > 1) ? atoi(argv[1]) : 30;
  cutoff = (argc > 2) ? atoi(argv[2]) : 0;
  int p = (argc > 3) ? atoi(argv[3]) : 1;
  omp_set_num_threads(p);
  long r = 0;
  double t0 = omp_get_wtime();
#pragma omp parallel
#pragma omp single
  r = fib(n);
  double t = omp_get_wtime() - t0;
  printf("fib(%d) = %ld  cutoff = %2d  p = %2d  time = %.4f s\n", n, r, cutoff, p, t);
  return 0;
}
