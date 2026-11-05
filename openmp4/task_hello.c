/* Ten tasks created by one thread, executed by the team. */
#include <stdio.h>
#include <omp.h>

int main(void) {
#pragma omp parallel
  {
#pragma omp single
    {
      printf("thread %d creates the tasks\n", omp_get_thread_num());
      for (int i = 0; i < 10; i++) {
#pragma omp task
        printf("task %d run by thread %d\n", i, omp_get_thread_num());
      }
      printf("thread %d has created all tasks\n", omp_get_thread_num());
    }                              /* implicit barrier: all tasks done here */
  }
  return 0;
}
