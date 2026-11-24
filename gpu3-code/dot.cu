/* dot.cu: the dot product a . b of two arrays of n = 2e8 doubles.
 * ITCS 4145, Programming with CUDA, Lecture 3, frames 2 to 6.
 *   ./dot partial   grid-stride loop, a private partial per thread, one
 *                   atomicAdd per thread (163840 atomics)       frames 2, 5
 *   ./dot cublas    cublasDdot on the same arrays               frame 5
 *   ./dot           both
 * (A shared-memory version was removed Nov 24: the course does not teach
 * shared memory or __syncthreads.)
 * a[i] = 1.0, b[i] = 2.0, so the exact result is 2n = 400000000. Launch
 * <<<640, 256>>>: 80 SMs x 2048 resident threads. Warm-up, then best of 5
 * with CUDA events; GB/s over the 3.2 GB read.
 * Build: nvcc -O2 -arch=sm_70 -o dot dot.cu -lcublas
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <cublas_v2.h>

#define CHECK(e) { cudaError_t err_ = (e); if (err_ != cudaSuccess) { \
    fprintf(stderr, "%s:%d: %s\n", __FILE__, __LINE__, cudaGetErrorString(err_)); exit(1); } }
#define CHECKB(e) { cublasStatus_t st_ = (e); if (st_ != CUBLAS_STATUS_SUCCESS) { \
    fprintf(stderr, "%s:%d: cuBLAS error %d\n", __FILE__, __LINE__, (int)st_); exit(1); } }

/* Frames 2 and 5: Lecture 2's sum with one multiply. */
__global__ void dot_partial(const double *a, const double *b, long n, double *dot) {
    long i = blockIdx.x * (long)blockDim.x + threadIdx.x;
    long stride = (long)gridDim.x * blockDim.x;
    double s = 0.0;
    for (; i < n; i += stride) s += a[i] * b[i];
    atomicAdd(dot, s);
}

int main(int argc, char **argv) {
    const char *mode = (argc > 1) ? argv[1] : "all";
    long n = 200000000L;
    size_t bytes = n * sizeof(double);
    double *a = (double *)malloc(bytes), *b = (double *)malloc(bytes);
    for (long i = 0; i < n; i++) { a[i] = 1.0; b[i] = 2.0; }
    double *d_a, *d_b, *d_dot, zero = 0.0, r = 0.0;
    CHECK(cudaMalloc(&d_a, bytes)); CHECK(cudaMalloc(&d_b, bytes)); CHECK(cudaMalloc(&d_dot, 8));
    CHECK(cudaMemcpy(d_a, a, bytes, cudaMemcpyHostToDevice));
    CHECK(cudaMemcpy(d_b, b, bytes, cudaMemcpyHostToDevice));
    cudaEvent_t t0, t1; CHECK(cudaEventCreate(&t0)); CHECK(cudaEventCreate(&t1));
    printf("n = %ld doubles per array, 3.2 GB read; exact result %ld\n", n, 2 * n);

    for (int m = 0; m < 1; m++) {
        const char *name = "partial";
        if (strcmp(mode, "all") && strcmp(mode, name)) continue;
        float best = 1e30f;
        for (int rep = 0; rep < 6; rep++) {
            CHECK(cudaMemcpy(d_dot, &zero, 8, cudaMemcpyHostToDevice));
            CHECK(cudaEventRecord(t0));
            dot_partial<<<640, 256>>>(d_a, d_b, n, d_dot);
            CHECK(cudaGetLastError());
            CHECK(cudaEventRecord(t1)); CHECK(cudaEventSynchronize(t1));
            float ms; CHECK(cudaEventElapsedTime(&ms, t0, t1));
            if (rep > 0 && ms < best) best = ms;
        }
        CHECK(cudaMemcpy(&r, d_dot, 8, cudaMemcpyDeviceToHost));
        printf("%-8s <<<640, 256>>>, 163840 atomics: dot = %.0f; best of 5 %.4f s, %.0f GB/s\n", name,
               r, best / 1000.0f, bytes * 2 / 1e9 / (best / 1000.0f));
    }

    if (!strcmp(mode, "all") || !strcmp(mode, "cublas")) {
        cublasHandle_t h; CHECKB(cublasCreate(&h));
        float best = 1e30f;
        for (int rep = 0; rep < 6; rep++) {
            CHECK(cudaEventRecord(t0));
            CHECKB(cublasDdot(h, (int)n, d_a, 1, d_b, 1, &r));   /* host pointer mode: returns when done */
            CHECK(cudaEventRecord(t1)); CHECK(cudaEventSynchronize(t1));
            float ms; CHECK(cudaEventElapsedTime(&ms, t0, t1));
            if (rep > 0 && ms < best) best = ms;
        }
        printf("%-8s cublasDdot: dot = %.0f; best of 5 %.4f s, %.0f GB/s\n", "cublas",
               r, best / 1000.0f, bytes * 2 / 1e9 / (best / 1000.0f));
        cublasDestroy(h);
    }
    CHECK(cudaFree(d_a)); CHECK(cudaFree(d_b)); CHECK(cudaFree(d_dot)); free(a); free(b);
    return 0;
}
