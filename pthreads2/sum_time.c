/* ITCS 4145, pthreads Lecture 2, frames 7 and 8: timing harness.
   Usage: ./sum_time <threads> <mode> [n]
     mode = local   each thread accumulates in a local variable and writes
                    its slot once (the frame 6 program)
     mode = slot    each thread adds directly into partial[rank] on every
                    iteration: all slots share one cache line (false sharing)
     mode = padded  as slot, but each thread's slot is on its own 64-byte
                    line: partial[rank * 8]
   Only the parallel phase (create ... join) is timed. The sum is checked.
   Output, one line: mode threads n seconds sum */
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define PAD 8                         /* 8 doubles = one 64-byte line */

typedef struct {
   int     rank, size, n;
   double *a;
   double *partial;
   int     stride;                    /* 1 for slot, PAD for padded */
} realargs;

static double now(void) {
   struct timespec t; clock_gettime(CLOCK_MONOTONIC, &t);
   return t.tv_sec + 1e-9 * t.tv_nsec;
}

void *sum_local(void *arguments) {
   realargs *args = (realargs *) arguments;
   int nn = args->n / args->size, s = nn * args->rank;
   if (args->rank == args->size - 1) nn = args->n - s;
   double local = 0.0;
   for (int i = s; i < s + nn; i++) local += args->a[i];
   args->partial[args->rank * args->stride] = local;
   return NULL;
}

void *sum_slot(void *arguments) {
   realargs *args = (realargs *) arguments;
   int nn = args->n / args->size, s = nn * args->rank;
   if (args->rank == args->size - 1) nn = args->n - s;
   double *mine = &args->partial[args->rank * args->stride];
   *mine = 0.0;
   for (int i = s; i < s + nn; i++) *mine += args->a[i];   /* store every iteration */
   return NULL;
}

int main(int argc, char *argv[]) {
   if (argc < 3) { fprintf(stderr, "usage: %s threads local|slot|padded [n]\n", argv[0]); return 1; }
   int   p = atoi(argv[1]);
   char *mode = argv[2];
   int   n = (argc > 3) ? atoi(argv[3]) : 200000000;      /* 2e8 doubles = 1.6 GB */
   int   stride = (strcmp(mode, "padded") == 0) ? PAD : 1;
   void *(*work)(void *) = (strcmp(mode, "local") == 0) ? sum_local : sum_slot;

   double *a = malloc((size_t) n * sizeof(double));
   for (int i = 0; i < n; i++) a[i] = 1.0;
   double *partial = aligned_alloc(64, (size_t) p * PAD * sizeof(double));

   pthread_t thread[p];
   realargs  threadargs[p];
   double best = 1e9, sum = 0.0;
   for (int rep = 0; rep < 5; rep++) {                      /* best of 5 */
      double t0 = now();
      for (int i = 0; i < p; i++) {
         threadargs[i] = (realargs) { i, p, n, a, partial, stride };
         pthread_create(&thread[i], NULL, work, &threadargs[i]);
      }
      for (int i = 0; i < p; i++) pthread_join(thread[i], NULL);
      double t1 = now();
      sum = 0.0;
      for (int i = 0; i < p; i++) sum += partial[i * stride];
      if (t1 - t0 < best) best = t1 - t0;
   }
   printf("%-7s %3d %10d %9.4f %s\n", mode, p, n, best,
          (sum == (double) n) ? "ok" : "WRONG");
   free(a); free(partial);
   return 0;
}
