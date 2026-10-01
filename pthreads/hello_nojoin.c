/* ITCS 4145, pthreads Lecture 1, frame 10.
   Experiment: the corrected program with the join loop deleted.
   main returns, the process ends, and most threads never get to print.
   Build as on the slide (gcc -pthread, no -O2). With -O2 the dying process
   sometimes lets threads read rank[] from main's already-destroyed stack
   and print garbage numbers: a second bug from the same missing join. */
#include <pthread.h>
#include <stdio.h>

void *hello(void *arg) {
   int *rank = (int *) arg;
   printf("Hello world from thread %d\n", *rank);
   return NULL;
}

int main(void) {
   int p = 8, i;
   pthread_t thread[p];
   int rank[p];
   for (i = 0; i < p; i++) {
      rank[i] = i;
      pthread_create(&thread[i], NULL, hello, &rank[i]);
   }
   return 0;                     /* main ends here; no join */
}
