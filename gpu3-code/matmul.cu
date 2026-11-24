/* matmul.cu: C = A B, one thread per element, blocks of 16 x 16.
 * ITCS 4145, Programming with CUDA, Lecture 3, frames 12 to 14 (copied from
 * Lecture 2 with the indices named row and col, as on the slide; the run of
 * Nov 16, 2026 is the one the slides quote). FP32, so that the comparison with
 * cuBLAS SGEMM (Lecture 1 frame 16: 13.0 TFLOP/s at N = 4096) is like for
 * like; the double version runs too and goes in the README.
 *   ./matmul [N]      default 4096; the Slurm script runs 2000 and 4096
 * Warm-up, then best of 5 with CUDA events; rate 2 N^3 / t. The result is
 * checked on 1000 random entries against the host (relative error).
 * Build: nvcc -arch=sm_70 -o matmul matmul.cu
 */
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define CHECK(e) { cudaError_t err_ = (e); if (err_ != cudaSuccess) { \
    fprintf(stderr, "%s:%d: %s\n", __FILE__, __LINE__, cudaGetErrorString(err_)); exit(1); } }

__global__ void matmul(float *A, float *B, float *C, int N) {
    int col = blockIdx.x * blockDim.x + threadIdx.x;
    int row = blockIdx.y * blockDim.y + threadIdx.y;
    if (row < N && col < N) {
        float s = 0.0f;
        for (int k = 0; k < N; k++)
            s += A[row * N + k] * B[k * N + col];
        C[row * N + col] = s;
    }
}

__global__ void matmul_d(double *A, double *B, double *C, int N) {
    int col = blockIdx.x * blockDim.x + threadIdx.x;
    int row = blockIdx.y * blockDim.y + threadIdx.y;
    if (row < N && col < N) {
        double s = 0.0;
        for (int k = 0; k < N; k++)
            s += A[row * N + k] * B[k * N + col];
        C[row * N + col] = s;
    }
}

int main(int argc, char **argv) {
    int N = (argc > 1) ? atoi(argv[1]) : 4096;
    size_t n = (size_t)N * N;
    float  *A = (float *)malloc(n * 4), *B = (float *)malloc(n * 4), *C = (float *)malloc(n * 4);
    srand(1);
    for (size_t i = 0; i < n; i++) { A[i] = (rand() % 100) / 100.0f; B[i] = (rand() % 100) / 100.0f; }
    float *dA, *dB, *dC;
    CHECK(cudaMalloc(&dA, n * 4)); CHECK(cudaMalloc(&dB, n * 4)); CHECK(cudaMalloc(&dC, n * 4));
    CHECK(cudaMemcpy(dA, A, n * 4, cudaMemcpyHostToDevice));
    CHECK(cudaMemcpy(dB, B, n * 4, cudaMemcpyHostToDevice));

    dim3 block(16, 16), grid((N + 15) / 16, (N + 15) / 16);
    cudaEvent_t t0, t1; CHECK(cudaEventCreate(&t0)); CHECK(cudaEventCreate(&t1));
    float best = 1e30f;
    for (int r = 0; r < 6; r++) {                 /* r = 0 is the warm-up */
        CHECK(cudaEventRecord(t0));
        matmul<<<grid, block>>>(dA, dB, dC, N);
        CHECK(cudaGetLastError());
        CHECK(cudaEventRecord(t1));
        CHECK(cudaEventSynchronize(t1));
        float ms; CHECK(cudaEventElapsedTime(&ms, t0, t1));
        if (r > 0 && ms < best) best = ms;
    }
    double flops = 2.0 * N * (double)N * N;
    printf("N = %d, FP32, blocks 16 x 16, grid %d x %d: best of 5 %.4f s, %.2f TFLOP/s\n",
           N, grid.x, grid.y, best / 1000.0f, flops / (best / 1000.0) / 1e12);

    /* check 1000 random entries against the host */
    CHECK(cudaMemcpy(C, dC, n * 4, cudaMemcpyDeviceToHost));
    double maxrel = 0.0;
    for (int t = 0; t < 1000; t++) {
        int y = rand() % N, x = rand() % N;
        double s = 0.0;
        for (int k = 0; k < N; k++) s += (double)A[(size_t)y * N + k] * B[(size_t)k * N + x];
        double rel = fabs(s - C[(size_t)y * N + x]) / (fabs(s) > 1e-6 ? fabs(s) : 1e-6);
        if (rel > maxrel) maxrel = rel;
    }
    printf("max relative error on 1000 entries against the host: %.2e\n", maxrel);

    /* the double version, for the README */
    double *A2 = (double *)malloc(n * 8), *B2 = (double *)malloc(n * 8);
    for (size_t i = 0; i < n; i++) { A2[i] = A[i]; B2[i] = B[i]; }
    double *dA2, *dB2, *dC2;
    CHECK(cudaMalloc(&dA2, n * 8)); CHECK(cudaMalloc(&dB2, n * 8)); CHECK(cudaMalloc(&dC2, n * 8));
    CHECK(cudaMemcpy(dA2, A2, n * 8, cudaMemcpyHostToDevice));
    CHECK(cudaMemcpy(dB2, B2, n * 8, cudaMemcpyHostToDevice));
    best = 1e30f;
    for (int r = 0; r < 6; r++) {
        CHECK(cudaEventRecord(t0));
        matmul_d<<<grid, block>>>(dA2, dB2, dC2, N);
        CHECK(cudaGetLastError());
        CHECK(cudaEventRecord(t1));
        CHECK(cudaEventSynchronize(t1));
        float ms; CHECK(cudaEventElapsedTime(&ms, t0, t1));
        if (r > 0 && ms < best) best = ms;
    }
    printf("N = %d, FP64, same launch: best of 5 %.4f s, %.2f TFLOP/s\n",
           N, best / 1000.0f, flops / (best / 1000.0) / 1e12);

    CHECK(cudaFree(dA)); CHECK(cudaFree(dB)); CHECK(cudaFree(dC));
    CHECK(cudaFree(dA2)); CHECK(cudaFree(dB2)); CHECK(cudaFree(dC2));
    free(A); free(B); free(C); free(A2); free(B2);
    return 0;
}
