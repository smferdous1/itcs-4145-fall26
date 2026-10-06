#include <pthread.h>
#include <stdio.h>

void *hello(void *arg) {
   int *rank = (int *) arg;
   printf("Hello world from thread %d\n", *rank);
   return NULL;
}

int main(void) {
   int p = 36, i;
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
