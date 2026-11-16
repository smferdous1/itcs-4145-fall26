/* hello.cu: the first kernel. ITCS 4145, Programming with CUDA, Lecture 2,
 * frame 2 (one block of four threads) and frame 4 (two blocks of four, via
 * the command line: ./hello 2 4).
 * Build: nvcc -arch=sm_70 -o hello hello.cu     Run: ./hello [blocks] [threads]
 */
#include <stdio.h>
#include <stdlib.h>

__global__ void hello(void) {
    printf("Hello world from thread %d of %d\n", threadIdx.x, blockDim.x);
}

__global__ void hello2(void) {
    printf("Hello world from thread %d of block %d\n", threadIdx.x, blockIdx.x);
}

int main(int argc, char **argv) {
    int blocks  = (argc > 1) ? atoi(argv[1]) : 1;
    int threads = (argc > 2) ? atoi(argv[2]) : 4;
    if (blocks == 1)
        hello<<<1, threads>>>();          /* frame 2 */
    else
        hello2<<<blocks, threads>>>();    /* frame 4 */
    cudaDeviceSynchronize();              /* wait for the kernel to finish */
    return 0;
}
