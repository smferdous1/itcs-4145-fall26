/* ITCS 4145, pthreads Lecture 1, frame 9.
   The correction: one variable per thread, written once, then left alone. */
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
   int rank[p];                  /* one per thread */
   for (i = 0; i < p; i++) {
      rank[i] = i;               /* written once */
      pthread_create(&thread[i], NULL, hello, &rank[i]);
   }
   for (i = 0; i < p; i++)
      pthread_join(thread[i], NULL);
   return 0;
}
