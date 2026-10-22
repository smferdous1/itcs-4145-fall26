/* An unbalanced loop: iteration i does work proportional to i.
   Schedule from OMP_SCHEDULE (schedule(runtime)); p from the command line.
   Prints the loop time and, per thread, the time spent in its iterations. */
#include <stdio.h>
#include <stdlib.h>
#include <omp.h>

int main(int argc, char **argv) {
  int p = (argc > 1) ? atoi(argv[1]) : 1;
  int n = 20000;
  double busy[64] = {0};
  omp_set_num_threads(p);

  double t0 = omp_get_wtime();
#pragma omp parallel
  {
    double mine = 0.0;
#pragma omp for schedule(runtime) nowait
    for (int i = 0; i < n; i++) {
      double s = omp_get_wtime();
      volatile double x = 0.0;
      for (int k = 0; k < 20 * i; k++) x += 1.0;   /* work grows with i */
      mine += omp_get_wtime() - s;
    }
    busy[omp_get_thread_num()] = mine;
  }
  double t = omp_get_wtime() - t0;

  double mx = 0, mn = 1e9;
  for (int k = 0; k < p; k++) { if (busy[k] > mx) mx = busy[k]; if (busy[k] < mn) mn = busy[k]; }
  printf("p = %2d  loop time = %.3f s   busiest thread %.3f s   idlest thread %.3f s\n", p, t, mx, mn);
  if (argc > 2) {                      /* "-v": per-thread busy times */
    for (int k = 0; k < p; k++) printf("  thread %2d: %.3f s\n", k, busy[k]);
  }
  return 0;
}
