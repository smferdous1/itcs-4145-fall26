/* gemm_time.cu: C = A B on the GPU with cuBLAS, three ways.
 * ITCS 4145, Programming with CUDA, Lecture 1, frame 16. No kernel of ours.
 *   sgemm   single precision (FP32), the ordinary lanes
 *   hgemm   half precision (FP16) inputs and output, tensor cores allowed
 *   tf32    FP32 inputs computed on tensor cores at TF32 precision
 *           (compute capability 8.0 and later only; skipped on the V100)
 * Protocol: N x N square matrices, N given on the command line (default 4096);
 * one warm-up call, then best of 5, timed with CUDA events; rate reported as
 * 2 N^3 / time in TFLOP/s. Matrices filled with small random values; the FP16
 * result is checked against the FP32 result on one row (max relative error).
 * Build: nvcc -O2 -o gemm_time gemm_time.cu -lcublas
 * Run:   srun -p GPU --gres=gpu:1 ./gemm_time 4096
 */
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <cuda_runtime.h>
#include <cuda_fp16.h>
#include <cublas_v2.h>

#define CHECK(call) do { cudaError_t e = (call); if (e != cudaSuccess) { \
    fprintf(stderr, "%s:%d: %s\n", __FILE__, __LINE__, cudaGetErrorString(e)); exit(1); } } while (0)
#define CHECKB(call) do { cublasStatus_t s = (call); if (s != CUBLAS_STATUS_SUCCESS) { \
    fprintf(stderr, "%s:%d: cublas status %d\n", __FILE__, __LINE__, (int)s); exit(1); } } while (0)

__global__ void to_half(const float *x, __half *h, size_t n) {
    size_t i = blockIdx.x * (size_t)blockDim.x + threadIdx.x;
    if (i < n) h[i] = __float2half(x[i]);
}
__global__ void to_float(const __half *h, float *x, size_t n) {
    size_t i = blockIdx.x * (size_t)blockDim.x + threadIdx.x;
    if (i < n) x[i] = __half2float(h[i]);
}

typedef void (*gemm_fn)(cublasHandle_t, int);
static float best_of_5(gemm_fn f, cublasHandle_t h, int N) {
    cudaEvent_t t0, t1; CHECK(cudaEventCreate(&t0)); CHECK(cudaEventCreate(&t1));
    f(h, N); CHECK(cudaDeviceSynchronize());               /* warm-up */
    float best = 1e30f;
    for (int r = 0; r < 5; r++) {
        CHECK(cudaEventRecord(t0)); f(h, N); CHECK(cudaEventRecord(t1));
        CHECK(cudaEventSynchronize(t1));
        float ms; CHECK(cudaEventElapsedTime(&ms, t0, t1));
        if (ms < best) best = ms;
    }
    return best / 1000.0f;
}

static float *dA, *dB, *dC; static __half *hA, *hB, *hC;
static const float one = 1.0f, zero = 0.0f;
static const __half hone = __float2half(1.0f), hzero = __float2half(0.0f);

static void sgemm(cublasHandle_t h, int N) {
    CHECKB(cublasSgemm(h, CUBLAS_OP_N, CUBLAS_OP_N, N, N, N, &one, dA, N, dB, N, &zero, dC, N));
}
static void hgemm(cublasHandle_t h, int N) {
    CHECKB(cublasHgemm(h, CUBLAS_OP_N, CUBLAS_OP_N, N, N, N, &hone, hA, N, hB, N, &hzero, hC, N));
}

int main(int argc, char **argv) {
    int N = (argc > 1) ? atoi(argv[1]) : 4096;
    size_t n = (size_t)N * N, bytes = n * sizeof(float);
    cudaDeviceProp p; CHECK(cudaGetDeviceProperties(&p, 0));
    printf("device: %s, compute capability %d.%d, N = %d\n", p.name, p.major, p.minor, N);

    float *A = (float *)malloc(bytes), *B = (float *)malloc(bytes), *C = (float *)malloc(bytes), *C2 = (float *)malloc(bytes);
    srand(1);
    for (size_t i = 0; i < n; i++) { A[i] = (rand() % 100) / 100.0f; B[i] = (rand() % 100) / 100.0f; }
    CHECK(cudaMalloc(&dA, bytes)); CHECK(cudaMalloc(&dB, bytes)); CHECK(cudaMalloc(&dC, bytes));
    CHECK(cudaMalloc(&hA, n * 2)); CHECK(cudaMalloc(&hB, n * 2)); CHECK(cudaMalloc(&hC, n * 2));
    CHECK(cudaMemcpy(dA, A, bytes, cudaMemcpyHostToDevice));
    CHECK(cudaMemcpy(dB, B, bytes, cudaMemcpyHostToDevice));
    to_half<<<(n + 255) / 256, 256>>>(dA, hA, n);
    to_half<<<(n + 255) / 256, 256>>>(dB, hB, n);
    CHECK(cudaDeviceSynchronize());

    cublasHandle_t h; CHECKB(cublasCreate(&h));
    double flops = 2.0 * N * (double)N * N;

    CHECKB(cublasSetMathMode(h, CUBLAS_DEFAULT_MATH));
    float t = best_of_5(sgemm, h, N);
    printf("sgemm  FP32, ordinary lanes:        %.4f s, %6.1f TFLOP/s\n", t, flops / t / 1e12);
    CHECK(cudaMemcpy(C, dC, bytes, cudaMemcpyDeviceToHost));

    CHECKB(cublasSetMathMode(h, CUBLAS_DEFAULT_MATH));   /* tensor cores allowed for FP16 */
    t = best_of_5(hgemm, h, N);
    printf("hgemm  FP16, tensor cores:          %.4f s, %6.1f TFLOP/s\n", t, flops / t / 1e12);
    to_float<<<(n + 255) / 256, 256>>>(hC, dC, n);
    CHECK(cudaMemcpy(C2, dC, bytes, cudaMemcpyDeviceToHost));
    double maxrel = 0.0;
    for (int j = 0; j < N; j++) {                          /* row 0, column-major: C[0 + j*N] */
        double a = C[(size_t)j * N], b = C2[(size_t)j * N];
        double rel = fabs(a - b) / (fabs(a) > 1e-6 ? fabs(a) : 1e-6);
        if (rel > maxrel) maxrel = rel;
    }
    printf("       max relative error of FP16 against FP32, row 0: %.2e\n", maxrel);

    if (p.major >= 8) {
        CHECKB(cublasSetMathMode(h, CUBLAS_TF32_TENSOR_OP_MATH));
        t = best_of_5(sgemm, h, N);
        printf("tf32   FP32 in, tensor cores:       %.4f s, %6.1f TFLOP/s\n", t, flops / t / 1e12);
    } else {
        printf("tf32   (needs compute capability 8.0; this device is %d.%d)\n", p.major, p.minor);
    }

    cublasDestroy(h);
    CHECK(cudaFree(dA)); CHECK(cudaFree(dB)); CHECK(cudaFree(dC));
    CHECK(cudaFree(hA)); CHECK(cudaFree(hB)); CHECK(cudaFree(hC));
    free(A); free(B); free(C); free(C2);
    return 0;
}
