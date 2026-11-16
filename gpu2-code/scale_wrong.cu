/* scale_wrong.cu: a[i] = 2 * a[i] as one block of n threads.
 * ITCS 4145, Programming with CUDA, Lecture 2, frames 6 and 7.
 *   ./scale_wrong nocheck   frame 6: the launch fails silently; a[0] stays 1
 *   ./scale_wrong check     frame 7: CHECK(cudaGetLastError()) reports it
 * n = 2e8 doubles, every element 1.0; expected after the kernel: 2.0.
 * Build: nvcc -arch=sm_70 -o scale_wrong scale_wrong.cu
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define CHECK(e) { cudaError_t r = (e); if (r != cudaSuccess) { \
    fprintf(stderr, "%s:%d: %s\n", __FILE__, __LINE__, cudaGetErrorString(r)); exit(1); } }

__global__ void scale(double *a, long n) {
    long i = threadIdx.x;
    a[i] = 2 * a[i];
}

int main(int argc, char **argv) {
    int check = (argc > 1 && strcmp(argv[1], "check") == 0);
    long n = 200000000L;
    size_t bytes = n * sizeof(double);
    double *a = (double *)malloc(bytes);
    for (long i = 0; i < n; i++) a[i] = 1.0;
    double *d_a;
    CHECK(cudaMalloc(&d_a, bytes));
    CHECK(cudaMemcpy(d_a, a, bytes, cudaMemcpyHostToDevice));

    scale<<<1, n>>>(d_a, n);                    /* one block of n threads: refused */
    if (check) CHECK(cudaGetLastError());       /* frame 7: ask */

    CHECK(cudaMemcpy(a, d_a, bytes, cudaMemcpyDeviceToHost));
    printf("a[0] = %.0f, a[n-1] = %.0f (expected 2)\n", a[0], a[n - 1]);
    CHECK(cudaFree(d_a)); free(a);
    return 0;
}
