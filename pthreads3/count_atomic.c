/* ITCS 4145, pthreads Lecture 3, frame 7: one shared counter, three ways.
   Each thread counts the elements of its block that exceed 0.5 and adds the
   result to ONE shared counter, one increment per qualifying element.
   Usage: ./count_atomic <threads> <mode> [n]
     mode = mutex    lock, count++, unlock           (frame 4 style)
     mode = atomic   __atomic_fetch_add(&count, 1)  (hardware read-modify-write)
     mode = private  local counter, written to partial[rank], main combines
   Only the parallel phase is timed; best of 3. Output: mode threads n seconds check */
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

typedef struct { int rank, size, n; double *a; long *partial; } realargs;

long count = 0;
pthread_mutex_t lock = PTHREAD_MUTEX_INITIALIZER;

static double now(void) {
   struct timespec t; clock_gettime(CLOCK_MONOTONIC, &t);
   return t.tv_sec + 1e-9 * t.tv_nsec;
}
static void block(realargs *g, int *s, int *nn) {
   *nn = g->n / g->size;  *s = *nn * g->rank;
   if (g->rank == g->size - 1) *nn = g->n - *s;
}

void *count_mutex(void *arguments) {
   realargs *g = (realargs *) arguments; int s, nn; block(g, &s, &nn);
   for (int i = s; i < s + nn; i++)
      if (g->a[i] > 0.5) {
         pthread_mutex_lock(&lock);
         count++;
         pthread_mutex_unlock(&lock);
      }
   return NULL;
}

void *count_atomic(void *arguments) {
   realargs *g = (realargs *) arguments; int s, nn; block(g, &s, &nn);
   for (int i = s; i < s + nn; i++)
      if (g->a[i] > 0.5)
         __atomic_fetch_add(&count, 1, __ATOMIC_RELAXED);   /* one indivisible step */
   return NULL;
}

void *count_private(void *arguments) {
   realargs *g = (realargs *) arguments; int s, nn; block(g, &s, &nn);
   long local = 0;
   for (int i = s; i < s + nn; i++)
      if (g->a[i] > 0.5) local++;
   g->partial[g->rank] = local;
   return NULL;
}

int main(int argc, char *argv[]) {
   if (argc < 3) { fprintf(stderr, "usage: %s threads mutex|atomic|private [n]\n", argv[0]); return 1; }
   int   p = atoi(argv[1]);
   char *mode = argv[2];
   int   n = (argc > 3) ? atoi(argv[3]) : 100000000;
   void *(*work)(void *) = strcmp(mode, "mutex") == 0 ? count_mutex
                         : strcmp(mode, "atomic") == 0 ? count_atomic : count_private;

   double *a = malloc((size_t) n * sizeof(double));
   srand(12345);
   long expected = 0;
   for (int i = 0; i < n; i++) { a[i] = rand() / (double) RAND_MAX; if (a[i] > 0.5) expected++; }

   long partial[p];
   pthread_t thread[p];
   realargs  threadargs[p];
   double best = 1e9; long result = 0;
   for (int rep = 0; rep < 3; rep++) {
      count = 0;
      double t0 = now();
      for (int i = 0; i < p; i++) {
         threadargs[i] = (realargs) { i, p, n, a, partial };
         pthread_create(&thread[i], NULL, work, &threadargs[i]);
      }
      for (int i = 0; i < p; i++) pthread_join(thread[i], NULL);
      if (work == count_private) { count = 0; for (int i = 0; i < p; i++) count += partial[i]; }
      double t1 = now();
      result = count;
      if (t1 - t0 < best) best = t1 - t0;
   }
   printf("%-8s %3d %10d %9.4f %s\n", mode, p, n, best, (result == expected) ? "ok" : "WRONG");
   free(a);
   return 0;
}
