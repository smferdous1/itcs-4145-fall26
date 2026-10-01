/* Alternative correction: a fresh heap integer per thread. The thread
   frees it; the lifetime rule is satisfied because heap memory stays
   valid until freed. */
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>

void *hello(void *arg) {
   int *rank = (int *) arg;
   printf("Hello world from thread %d\n", *rank);
   free(rank);                   /* this thread owns it */
   return NULL;
}

int main(void) {
   int p = 8, i;
   pthread_t thread[p];
   for (i = 0; i < p; i++) {
      int *r = malloc(sizeof(int));   /* a new int, for this thread only */
      *r = i;
      pthread_create(&thread[i], NULL, hello, r);
   }
   for (i = 0; i < p; i++)
      pthread_join(thread[i], NULL);
   return 0;
}
