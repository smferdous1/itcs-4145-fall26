/* scale.cu: a[i] = 2 * a[i] on the GPU, a grid of blocks with the guard.
 * ITCS 4145, Programming with CUDA, Lecture 2, frames 7 and 8.
 *   ./scale [n]          frame 7: correctness; counts elements that are not 2
 *   ./scale time         frame 8: kernel alone; kernel and both copies with
 *                        pinned host memory; the same with pageable memory.
 *                        n = 2e8 doubles (1.6 GB), warm-up then best of 5,
 *                        timed with CUDA events.
 * Build: nvcc -arch=sm_70 -o scale scale.cu
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define CHECK(e) { cudaError_t r = (e); if (r != cudaSuccess) { \
    fprintf(stderr, "%s:%d: %s\n", __FILE__, __LINE__, cudaGetErrorString(r)); exit(1); } }

__global__ void scale(double *a, long n) {
    long i = blockIdx.x * (long)blockDim.x + threadIdx.x;
    if (i < n) a[i] = 2 * a[i];      /* the guard */
}

/* mode 0: kernel only; mode 1: copy in, kernel, copy out. Returns seconds, best of 5. */
static float best_of_5(int mode, double *a, double *d_a, long n, size_t bytes, long blocks) {
    cudaEvent_t t0, t1; CHECK(cudaEventCreate(&t0)); CHECK(cudaEventCreate(&t1));
    float best = 1e30f;
    for (int r = 0; r < 6; r++) {                 /* r = 0 is the warm-up */
        CHECK(cudaEventRecord(t0));
        if (mode == 1) CHECK(cudaMemcpy(d_a, a, bytes, cudaMemcpyHostToDevice));
        scale<<<blocks, 256>>>(d_a, n);
        CHECK(cudaGetLastError());
        if (mode == 1) CHECK(cudaMemcpy(a, d_a, bytes, cudaMemcpyDeviceToHost));
        CHECK(cudaEventRecord(t1));
        CHECK(cudaEventSynchronize(t1));
        float ms; CHECK(cudaEventElapsedTime(&ms, t0, t1));
        if (r > 0 && ms < best) best = ms;
    }
    CHECK(cudaEventDestroy(t0)); CHECK(cudaEventDestroy(t1));
    return best / 1000.0f;
}

int main(int argc, char **argv) {
    int timing = (argc > 1 && strcmp(argv[1], "time") == 0);
    long n = (argc > 1 && !timing) ? atol(argv[1]) : 200000000L;
    size_t bytes = n * sizeof(double);
    long blocks = (n + 255) / 256;

    double *a = (double *)malloc(bytes);
    for (long i = 0; i < n; i++) a[i] = 1.0;
    double *d_a;
    CHECK(cudaMalloc(&d_a, bytes));
    CHECK(cudaMemcpy(d_a, a, bytes, cudaMemcpyHostToDevice));

    if (!timing) {                                /* frame 7 */
        scale<<<blocks, 256>>>(d_a, n);
        CHECK(cudaGetLastError());
        CHECK(cudaMemcpy(a, d_a, bytes, cudaMemcpyDeviceToHost));
        long wrong = 0;
        for (long i = 0; i < n; i++) if (a[i] != 2.0) wrong++;
        printf("n = %ld, %ld blocks of 256: a[0] = %.0f, a[n-1] = %.0f, %ld elements not 2\n",
               n, blocks, a[0], a[n - 1], wrong);
    } else {                                      /* frame 8 */
        printf("n = %ld doubles, %.1f GB; 3.2 GB moved by the kernel; best of 5 after a warm-up\n",
               n, bytes / 1e9);
        float t = best_of_5(0, a, d_a, n, bytes, blocks);
        printf("kernel only:                         %.4f s  (%.0f GB/s)\n", t, 2.0 * bytes / 1e9 / t);
        t = best_of_5(1, a, d_a, n, bytes, blocks);
        printf("kernel and both copies, pageable:    %.4f s\n", t);
        double *p; CHECK(cudaMallocHost(&p, bytes));
        memcpy(p, a, bytes);
        t = best_of_5(1, p, d_a, n, bytes, blocks);
        printf("kernel and both copies, pinned:      %.4f s\n", t);
        CHECK(cudaFreeHost(p));
    }
    CHECK(cudaFree(d_a)); free(a);
    return 0;
}
