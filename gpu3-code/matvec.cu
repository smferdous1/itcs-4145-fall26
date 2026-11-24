/* matvec.cu: y = A x for an N x N matrix of doubles, N = 16384 (2.1 GB).
 * ITCS 4145, Programming with CUDA, Lecture 3, frames 6 to 11.
 *   ./matvec thread   one thread per row, A row-major: lane t of a warp
 *                     reads A[row*N + k], addresses N apart       frame 6 (wrong)
 *   ./matvec threadT  one thread per row, A stored transposed (column-
 *                     major): lane t reads At[k*N + row], consecutive  frame 9
 *   ./matvec block    one block of 256 per row, A row-major: the block's
 *                     threads stride along the row, then each does
 *                     atomicAdd(&y[row], s)                       frames 9, 10
 *   ./matvec cublas   cublasDgemv on the row-major A (op T)       frame 11
 *   ./matvec          all four
 * A[i][j] = ((i + 2j) mod 7) - 3, x[j] = (j mod 5) - 2: small integers, so
 * every y[i] is exact in double and is checked against the host on 1000
 * rows. Warm-up, then best of 5 with CUDA events; GB/s over the matrix.
 * Build: nvcc -O2 -arch=sm_70 -o matvec matvec.cu -lcublas
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <cublas_v2.h>

#define CHECK(e) { cudaError_t r = (e); if (r != cudaSuccess) { \
    fprintf(stderr, "%s:%d: %s\n", __FILE__, __LINE__, cudaGetErrorString(r)); exit(1); } }
#define CHECKB(e) { cublasStatus_t r = (e); if (r != CUBLAS_STATUS_SUCCESS) { \
    fprintf(stderr, "%s:%d: cuBLAS error %d\n", __FILE__, __LINE__, (int)r); exit(1); } }

/* The wrong program: the CPU habit. Each thread walks its own row. */
__global__ void matvec_thread(const double *A, const double *x, double *y, int N) {
    int row = blockIdx.x * blockDim.x + threadIdx.x;
    if (row < N) {
        double s = 0.0;
        for (int k = 0; k < N; k++) s += A[(long)row * N + k] * x[k];
        y[row] = s;
    }
}

/* First correction: the same kernel on the transposed matrix. */
__global__ void matvec_threadT(const double *At, const double *x, double *y, int N) {
    int row = blockIdx.x * blockDim.x + threadIdx.x;
    if (row < N) {
        double s = 0.0;
        for (int k = 0; k < N; k++) s += At[(long)k * N + row] * x[k];
        y[row] = s;
    }
}

/* Second correction: a block per row, threads stride along it, and each
 * adds its partial to y[row] (set to 0 before the launch). */
__global__ void matvec_block(const double *A, const double *x, double *y, int N) {
    int row = blockIdx.x, t = threadIdx.x;
    double s = 0.0;
    for (int k = t; k < N; k += 256) s += A[(long)row * N + k] * x[k];
    atomicAdd(&y[row], s);
}

int main(int argc, char **argv) {
    const char *mode = (argc > 1) ? argv[1] : "all";
    int N = 16384;
    size_t nn = (size_t)N * N, bytes = nn * sizeof(double);
    double *A = (double *)malloc(bytes), *At = (double *)malloc(bytes);
    double *x = (double *)malloc(N * 8), *y = (double *)malloc(N * 8), *yh = (double *)malloc(N * 8);
    for (int i = 0; i < N; i++)
        for (int j = 0; j < N; j++) {
            double v = (double)((i + 2 * j) % 7 - 3);
            A[(size_t)i * N + j] = v; At[(size_t)j * N + i] = v;
        }
    for (int j = 0; j < N; j++) x[j] = (double)(j % 5 - 2);
    srand(1);
    int rows[1000];
    for (int r = 0; r < 1000; r++) {
        int i = rows[r] = rand() % N; double s = 0.0;
        for (int j = 0; j < N; j++) s += A[(size_t)i * N + j] * x[j];
        yh[r] = s;
    }
    double *dA, *dAt, *dx, *dy;
    CHECK(cudaMalloc(&dA, bytes)); CHECK(cudaMalloc(&dAt, bytes));
    CHECK(cudaMalloc(&dx, N * 8)); CHECK(cudaMalloc(&dy, N * 8));
    CHECK(cudaMemcpy(dA, A, bytes, cudaMemcpyHostToDevice));
    CHECK(cudaMemcpy(dAt, At, bytes, cudaMemcpyHostToDevice));
    CHECK(cudaMemcpy(dx, x, N * 8, cudaMemcpyHostToDevice));
    cublasHandle_t h; CHECKB(cublasCreate(&h));
    cudaEvent_t t0, t1; CHECK(cudaEventCreate(&t0)); CHECK(cudaEventCreate(&t1));
    printf("N = %d, A is %.2f GB of doubles\n", N, bytes / 1e9);

    const char *names[4] = {"thread", "threadT", "block", "cublas"};
    const char *how[4] = {"<<<64, 256>>>, 16384 threads, row-major",
                          "<<<64, 256>>>, 16384 threads, transposed",
                          "<<<16384, 256>>>, 4194304 threads, row-major",
                          "cublasDgemv, op T on the row-major A"};
    double one = 1.0, zero0 = 0.0;
    for (int m = 0; m < 4; m++) {
        if (strcmp(mode, "all") && strcmp(mode, names[m])) continue;
        float best = 1e30f;
        for (int rep = 0; rep < 6; rep++) {
            CHECK(cudaMemset(dy, 0, N * 8));
            CHECK(cudaEventRecord(t0));
            if (m == 0) matvec_thread<<<(N + 255) / 256, 256>>>(dA, dx, dy, N);
            if (m == 1) matvec_threadT<<<(N + 255) / 256, 256>>>(dAt, dx, dy, N);
            if (m == 2) matvec_block<<<N, 256>>>(dA, dx, dy, N);
            if (m == 3) CHECKB(cublasDgemv(h, CUBLAS_OP_T, N, N, &one, dA, N, dx, 1, &zero0, dy, 1));
            CHECK(cudaGetLastError());
            CHECK(cudaEventRecord(t1)); CHECK(cudaEventSynchronize(t1));
            float ms; CHECK(cudaEventElapsedTime(&ms, t0, t1));
            if (rep > 0 && ms < best) best = ms;
        }
        CHECK(cudaMemcpy(y, dy, N * 8, cudaMemcpyDeviceToHost));
        int wrong = 0;
        for (int r = 0; r < 1000; r++) if (y[rows[r]] != yh[r]) wrong++;
        printf("%-8s %-46s best of 5 %.4f s, %4.0f GB/s; %d of 1000 rows wrong\n",
               names[m], how[m], best / 1000.0f, bytes / 1e9 / (best / 1000.0f), wrong);
    }
    cublasDestroy(h);
    CHECK(cudaFree(dA)); CHECK(cudaFree(dAt)); CHECK(cudaFree(dx)); CHECK(cudaFree(dy));
    free(A); free(At); free(x); free(y); free(yh);
    return 0;
}
