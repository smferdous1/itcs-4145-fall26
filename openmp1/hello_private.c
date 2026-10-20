#include <stdio.h>
#include <omp.h>

int main(void) {
  int id, p;                    /* declared before the region ... */
#pragma omp parallel private(id, p)   /* ... but private inside it */
  {
    id = omp_get_thread_num();
    p  = omp_get_num_threads();
    printf("Hello world from thread %d of %d\n", id, p);
  }
  return 0;
}
