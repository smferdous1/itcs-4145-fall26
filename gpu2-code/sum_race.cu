/* sum_race.cu: the sum with one shared accumulator, every thread doing
 * *sum += a[i]. ITCS 4145, Programming with CUDA, Lecture 2, frame 9
 * (wrong program). n = 2e8 ones; expected 200000000; the race loses most.
 * Build: nvcc -arch=sm_70 -o sum_race sum_race.cu
 */
#include <stdio.h>
#include <stdlib.h>

#define CHECK(e) { cudaError_t r = (e); if (r != cudaSuccess) { \
    fprintf(stderr, "%s:%d: %s\n", __FILE__, __LINE__, cudaGetErrorString(r)); exit(1); } }

__global__ void sum_race(double *a, long n, double *sum) {
    long i = blockIdx.x * (long)blockDim.x + threadIdx.x;
    if (i < n) *sum += a[i];          /* load, add, store: a data race */
}

int main(void) {
    long n = 200000000L;
    size_t bytes = n * sizeof(double);
    double *a = (double *)malloc(bytes);
    for (long i = 0; i < n; i++) a[i] = 1.0;
    double *d_a, *d_sum, zero = 0.0, s;
    CHECK(cudaMalloc(&d_a, bytes));
    CHECK(cudaMalloc(&d_sum, sizeof(double)));
    CHECK(cudaMemcpy(d_a, a, bytes, cudaMemcpyHostToDevice));
    CHECK(cudaMemcpy(d_sum, &zero, sizeof(double), cudaMemcpyHostToDevice));

    long blocks = (n + 255) / 256;
    sum_race<<<blocks, 256>>>(d_a, n, d_sum);
    CHECK(cudaGetLastError());
    CHECK(cudaMemcpy(&s, d_sum, sizeof(double), cudaMemcpyDeviceToHost));
    printf("sum = %.0f (expected %ld)\n", s, n);

    CHECK(cudaFree(d_a)); CHECK(cudaFree(d_sum)); free(a);
    return 0;
}
