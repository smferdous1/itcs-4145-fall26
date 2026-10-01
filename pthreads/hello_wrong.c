/* ITCS 4145, pthreads Lecture 1, frame 8.
   A first attempt: give each thread its number by passing &i.
   WRONG: all threads receive the same address, main's loop counter. */
#include <pthread.h>
#include <stdio.h>

void *hello(void *arg) {
   int *rank = (int *) arg;     /* the promise */
   printf("Hello world from thread %d\n", *rank);
   return NULL;
}

int main(void) {
   int p = 8, i;
   pthread_t thread[p];
   for (i = 0; i < p; i++)
      pthread_create(&thread[i], NULL, hello, &i);
   for (i = 0; i < p; i++)
      pthread_join(thread[i], NULL);
   return 0;
}
