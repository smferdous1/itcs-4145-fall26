/* hello_nosync.cu: the hello kernel without cudaDeviceSynchronize.
 * ITCS 4145, Programming with CUDA, Lecture 2, frame 3 (wrong program).
 * Expected: no output, because main returns before the kernel runs.
 * Build: nvcc -arch=sm_70 -o hello_nosync hello_nosync.cu
 */
#include <stdio.h>

__global__ void hello(void) {
    printf("Hello world from thread %d of %d\n", threadIdx.x, blockDim.x);
}

int main(void) {
    hello<<<1, 4>>>();
    /* cudaDeviceSynchronize();  removed */
    return 0;
}
