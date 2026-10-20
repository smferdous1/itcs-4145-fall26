#include <stdio.h>
#include <omp.h>

int main(void) {
#pragma omp parallel
  {
    int id = omp_get_thread_num();
    int p  = omp_get_num_threads();
    printf("Hello world from thread %d of %d\n", id, p);
  }
  return 0;
}
