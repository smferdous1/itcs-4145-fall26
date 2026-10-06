/* ITCS 4145, pthreads Lecture 2
   First attempt: every thread adds its block into ONE shared variable.
   WRONG: the updates of sum race. */
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>

typedef struct {
   int     rank;
   int     size;
   int     n;
   double *a;
} realargs;

double sum = 0.0;                        /* shared by all threads */

void *sum_block(void *arguments) {
   realargs *args = (realargs *) arguments;
   int nn = args->n / args->size;
   int s  = nn * args->rank;
   if (args->rank == args->size - 1) nn = args->n - s;
   for (int i = s; i < s + nn; i++)
      sum += args->a[i];                 /* all threads write sum */
   return NULL;
}

int main(int argc, char *argv[]) {
   int n = 100000000, p = (argc > 1) ? atoi(argv[1]) : 8;
   double *a = malloc(n * sizeof(double));
   for (int i = 0; i < n; i++) a[i] = 1.0;   /* so the sum should be n */

   pthread_t thread[p];
   realargs  threadargs[p];
   for (int i = 0; i < p; i++) {
      threadargs[i].rank = i;  threadargs[i].size = p;
      threadargs[i].n    = n;  threadargs[i].a    = a;
      pthread_create(&thread[i], NULL, sum_block, &threadargs[i]);
   }
   for (int i = 0; i < p; i++) pthread_join(thread[i], NULL);

   printf("sum = %.0f (expected %d)\n", sum, n);
   free(a);
   return 0;
}