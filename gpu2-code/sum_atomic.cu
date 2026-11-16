/* sum_atomic.cu: the sum with atomicAdd from every thread.
 * ITCS 4145, Programming with CUDA, Lecture 2, frame 10. Frame 9's program
 * with one line changed. Correct; timed with CUDA events, warm-up then best
 * of 5 (the kernel only; the array is already on the device).
 * Build: nvcc -arch=sm_70 -o sum_atomic sum_atomic.cu
 */
#include <stdio.h>
#include <stdlib.h>

#define CHECK(e) { cudaError_t r = (e); if (r != cudaSuccess) { \
    fprintf(stderr, "%s:%d: %s\n", __FILE__, __LINE__, cudaGetErrorString(r)); exit(1); } }

__global__ void sum_atomic(double *a, long n, double *sum) {
    long i = blockIdx.x * (long)blockDim.x + threadIdx.x;
    if (i < n) atomicAdd(sum, a[i]);  /* the one change */
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
    long blocks = (n + 255) / 256;

    cudaEvent_t t0, t1; CHECK(cudaEventCreate(&t0)); CHECK(cudaEventCreate(&t1));
    float best = 1e30f;
    for (int r = 0; r < 6; r++) {                 /* r = 0 is the warm-up */
        CHECK(cudaMemcpy(d_sum, &zero, sizeof(double), cudaMemcpyHostToDevice));
        CHECK(cudaEventRecord(t0));
        sum_atomic<<<blocks, 256>>>(d_a, n, d_sum);
        CHECK(cudaGetLastError());
        CHECK(cudaEventRecord(t1));
        CHECK(cudaEventSynchronize(t1));
        float ms; CHECK(cudaEventElapsedTime(&ms, t0, t1));
        if (r > 0 && ms < best) best = ms;
        CHECK(cudaMemcpy(&s, d_sum, sizeof(double), cudaMemcpyDeviceToHost));
        printf("run %d: sum = %.0f (expected %ld), %.4f s\n", r, s, n, ms / 1000.0f);
    }
    printf("best of 5: %.4f s\n", best / 1000.0f);
    CHECK(cudaFree(d_a)); CHECK(cudaFree(d_sum)); free(a);
    return 0;
}
