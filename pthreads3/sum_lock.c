/* ITCS 4145, pthreads Lecture 3, frames 4 and 5: the sum with a mutex.
   Usage: ./sum_lock <threads> <mode> [n]
     mode = inner    lock around EVERY addition into the shared sum
     mode = outer    accumulate locally, lock ONCE per thread to add the total
     mode = private  Lecture 2 version: partial[rank], main combines (no lock)
   Only the parallel phase (create ... join ... combine) is timed; best of 5.
   Output, one line: mode threads n seconds sum check */
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

typedef struct { int rank, size, n; double *a; double *partial; } realargs;

double sum = 0.0;                                      /* shared */
pthread_mutex_t lock = PTHREAD_MUTEX_INITIALIZER;      /* protects sum */

static double now(void) {
   struct timespec t; clock_gettime(CLOCK_MONOTONIC, &t);
   return t.tv_sec + 1e-9 * t.tv_nsec;
}

static void block(realargs *args, int *s, int *nn) {
   *nn = args->n / args->size;  *s = *nn * args->rank;
   if (args->rank == args->size - 1) *nn = args->n - *s;
}

void *sum_inner(void *arguments) {                     /* frame 4 */
   realargs *args = (realargs *) arguments; int s, nn; block(args, &s, &nn);
   for (int i = s; i < s + nn; i++) {
      pthread_mutex_lock(&lock);
      sum += args->a[i];                               /* critical section */
      pthread_mutex_unlock(&lock);
   }
   return NULL;
}

void *sum_outer(void *arguments) {                     /* frame 5 */
   realargs *args = (realargs *) arguments; int s, nn; block(args, &s, &nn);
   double local = 0.0;
   for (int i = s; i < s + nn; i++) local += args->a[i];
   pthread_mutex_lock(&lock);
   sum += local;                                       /* once per thread */
   pthread_mutex_unlock(&lock);
   return NULL;
}

void *sum_private(void *arguments) {                   /* Lecture 2 */
   realargs *args = (realargs *) arguments; int s, nn; block(args, &s, &nn);
   double local = 0.0;
   for (int i = s; i < s + nn; i++) local += args->a[i];
   args->partial[args->rank] = local;
   return NULL;
}

int main(int argc, char *argv[]) {
   if (argc < 3) { fprintf(stderr, "usage: %s threads inner|outer|private [n]\n", argv[0]); return 1; }
   int   p = atoi(argv[1]);
   char *mode = argv[2];
   int   n = (argc > 3) ? atoi(argv[3]) : 200000000;
   void *(*work)(void *) = strcmp(mode, "inner") == 0 ? sum_inner
                         : strcmp(mode, "outer") == 0 ? sum_outer : sum_private;

   double *a = malloc((size_t) n * sizeof(double));
   for (int i = 0; i < n; i++) a[i] = 1.0;
   double partial[p];
   pthread_t thread[p];
   realargs  threadargs[p];

   double best = 1e9, result = 0.0;
   int reps = (strcmp(mode, "inner") == 0 && p > 1) ? 2 : 5;   /* inner is slow */
   for (int rep = 0; rep < reps; rep++) {
      sum = 0.0;
      double t0 = now();
      for (int i = 0; i < p; i++) {
         threadargs[i] = (realargs) { i, p, n, a, partial };
         pthread_create(&thread[i], NULL, work, &threadargs[i]);
      }
      for (int i = 0; i < p; i++) pthread_join(thread[i], NULL);
      if (work == sum_private) { sum = 0.0; for (int i = 0; i < p; i++) sum += partial[i]; }
      double t1 = now();
      result = sum;
      if (t1 - t0 < best) best = t1 - t0;
   }
   printf("%-8s %3d %10d %9.4f %.0f %s\n", mode, p, n, best, result,
          (result == (double) n) ? "ok" : "WRONG");
   free(a);
   return 0;
}
