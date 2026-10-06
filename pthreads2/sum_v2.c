/* ITCS 4145, pthreads Lecture 2.
   The correction: each thread accumulates in a local variable and writes
   ONCE to its own slot partial[rank]; main adds the p partials after the
   joins. No two threads write the same variable, so there is no race. */
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>

typedef struct {
   int     rank;
   int     size;
   int     n;
   double *a;
   double *partial;                     /* shared array of p slots */
} realargs;

void *sum_block(void *arguments) {
   realargs *args = (realargs *) arguments;
   int nn = args->n / args->size;
   int s  = nn * args->rank;
   if (args->rank == args->size - 1) nn = args->n - s;
   double local = 0.0;                  /* private to this thread */
   for (int i = s; i < s + nn; i++)
      local += args->a[i];
   args->partial[args->rank] = local;   /* one write, to my own slot */
   return NULL;
}

int main(int argc, char *argv[]) {
   int n = 100000000, p = (argc > 1) ? atoi(argv[1]) : 8;
   double *a = malloc(n * sizeof(double));
   for (int i = 0; i < n; i++) a[i] = 1.0;

   pthread_t thread[p];
   realargs  threadargs[p];
   double    partial[p];
   for (int i = 0; i < p; i++) {
      threadargs[i].rank = i;  threadargs[i].size    = p;
      threadargs[i].n    = n;  threadargs[i].a       = a;
      threadargs[i].partial = partial;
      pthread_create(&thread[i], NULL, sum_block, &threadargs[i]);
   }
   for (int i = 0; i < p; i++) pthread_join(thread[i], NULL);

   double sum = 0.0;                    /* combine: p additions, by main */
   for (int i = 0; i < p; i++) sum += partial[i];

   printf("sum = %.0f (expected %d)\n", sum, n);
   free(a);
   return 0;
}
