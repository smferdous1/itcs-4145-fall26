/* sum_partial.cu: the sum with a private partial per thread and one
 * atomicAdd per thread (grid-stride loop). ITCS 4145, Programming with
 * CUDA, Lecture 2, frame 11. Launch 640 blocks of 256 = 163840 threads
 * (80 SMs x 2048 resident threads on the Titan V); each thread sums about
 * 1220 elements. Timed with CUDA events, warm-up then best of 5.
 *   ./sum_partial [blocks]   default 640; try 80, 320, 1280 to see the
 *                            launch size does not matter once the card is full
 * Build: nvcc -arch=sm_70 -o sum_partial sum_partial.cu
 */
#include <stdio.h>
#include <stdlib.h>

#define CHECK(e) { cudaError_t r = (e); if (r != cudaSuccess) { \
    fprintf(stderr, "%s:%d: %s\n", __FILE__, __LINE__, cudaGetErrorString(r)); exit(1); } }

__global__ void sum_partial(double *a, long n, double *sum) {
    long i = blockIdx.x * (long)blockDim.x + threadIdx.x;
    long stride = (long)gridDim.x * blockDim.x;
    double s = 0.0;                           /* private: a register */
    for (; i < n; i += stride) s += a[i];
    atomicAdd(sum, s);                        /* once per thread */
}

int main(int argc, char **argv) {
    int blocks = (argc > 1) ? atoi(argv[1]) : 640;
    long n = 200000000L;
    size_t bytes = n * sizeof(double);
    double *a = (double *)malloc(bytes);
    for (long i = 0; i < n; i++) a[i] = 1.0;
    double *d_a, *d_sum, zero = 0.0, s;
    CHECK(cudaMalloc(&d_a, bytes));
    CHECK(cudaMalloc(&d_sum, sizeof(double)));
    CHECK(cudaMemcpy(d_a, a, bytes, cudaMemcpyHostToDevice));

    cudaEvent_t t0, t1; CHECK(cudaEventCreate(&t0)); CHECK(cudaEventCreate(&t1));
    float best = 1e30f;
    for (int r = 0; r < 6; r++) {                 /* r = 0 is the warm-up */
        CHECK(cudaMemcpy(d_sum, &zero, sizeof(double), cudaMemcpyHostToDevice));
        CHECK(cudaEventRecord(t0));
        sum_partial<<<blocks, 256>>>(d_a, n, d_sum);
        CHECK(cudaGetLastError());
        CHECK(cudaEventRecord(t1));
        CHECK(cudaEventSynchronize(t1));
        float ms; CHECK(cudaEventElapsedTime(&ms, t0, t1));
        if (r > 0 && ms < best) best = ms;
        CHECK(cudaMemcpy(&s, d_sum, sizeof(double), cudaMemcpyDeviceToHost));
        if (r == 0 || r == 5) printf("run %d: sum = %.0f (expected %ld)\n", r, s, n);
    }
    printf("%d blocks of 256 = %d threads: best of 5 %.4f s, %.0f GB/s\n",
           blocks, blocks * 256, best / 1000.0f, bytes / 1e9 / (best / 1000.0f));
    CHECK(cudaFree(d_a)); CHECK(cudaFree(d_sum)); free(a);
    return 0;
}
