/* One thread allocates and initializes a shared buffer inside the region;
   all threads then use it. Three ways to say "one thread":
     master          : thread 0 does it, no barrier: the others may use the
                       buffer before it exists (wrong)
     master+barrier  : thread 0 does it, explicit barrier after (correct)
     single          : whichever thread arrives first does it, implicit
                       barrier after (correct)
   Each thread checks that the buffer pointer it sees is set and that its
   own slot holds the expected value; the program reports the failures. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <omp.h>

int main(int argc, char **argv) {
  int p = (argc > 1) ? atoi(argv[1]) : 8;
  const char *mode = (argc > 2) ? argv[2] : "single";
  omp_set_num_threads(p);
  int fails = 0, runs = 1000;

  for (int rep = 0; rep < runs; rep++) {
    double *buf = NULL;
#pragma omp parallel shared(buf) reduction(+:fails)
    {
      int id = omp_get_thread_num(), n = omp_get_num_threads();
      if (strcmp(mode, "single") == 0) {
#pragma omp single
        { buf = malloc(n * sizeof(double)); for (int k = 0; k < n; k++) buf[k] = k; }
        /* implicit barrier here */
      } else {
#pragma omp master
        { buf = malloc(n * sizeof(double)); for (int k = 0; k < n; k++) buf[k] = k; }
        if (strcmp(mode, "master+barrier") == 0) {
#pragma omp barrier
        }
      }
      double *mine = buf;                 /* what this thread sees now */
      if (mine == NULL || mine[id] != id) fails++;
    }
    free(buf);
  }
  printf("%-15s p = %2d  %d runs: %d thread checks failed\n", mode, p, runs, fails);
  return 0;
}
