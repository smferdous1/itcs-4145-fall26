/* bw.cu: memory bandwidth of one GPU, three ways.
 * ITCS 4145, Programming with CUDA, Lecture 1, frames 13 and 17.
 *   d2d   device-to-device copy, cudaMemcpy: the GPU's own memory, read + write
 *   h2d   host-to-device over PCIe, cudaMemcpy from pageable host memory
 *   h2dp  host-to-device from pinned host memory (cudaMallocHost)
 * Protocol: n = 2e8 doubles (1.6 GB) as in the OpenMP sum; one warm-up copy,
 * then best of 5, timed with CUDA events. Bandwidth for d2d counts bytes read
 * and written (2 x 1.6 GB), as the OpenMP sum counted bytes read; h2d counts
 * the 1.6 GB moved once.
 * Build: nvcc -O2 -o bw bw.cu        Run: srun -p GPU --gres=gpu:1 ./bw
 */
#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>

#define CHECK(call) do { cudaError_t e = (call); if (e != cudaSuccess) { \
    fprintf(stderr, "%s:%d: %s\n", __FILE__, __LINE__, cudaGetErrorString(e)); exit(1); } } while (0)

static float time_copy(void *dst, const void *src, size_t bytes, cudaMemcpyKind kind) {
    cudaEvent_t t0, t1; CHECK(cudaEventCreate(&t0)); CHECK(cudaEventCreate(&t1));
    CHECK(cudaMemcpy(dst, src, bytes, kind));            /* warm-up */
    float best = 1e30f;
    for (int r = 0; r < 5; r++) {
        CHECK(cudaEventRecord(t0));
        CHECK(cudaMemcpy(dst, src, bytes, kind));
        CHECK(cudaEventRecord(t1));
        CHECK(cudaEventSynchronize(t1));
        float ms; CHECK(cudaEventElapsedTime(&ms, t0, t1));
        if (ms < best) best = ms;
    }
    CHECK(cudaEventDestroy(t0)); CHECK(cudaEventDestroy(t1));
    return best / 1000.0f;                                /* seconds */
}

int main(int argc, char **argv) {
    size_t n = (argc > 1) ? strtoull(argv[1], NULL, 10) : 200000000ULL;
    size_t bytes = n * sizeof(double);
    double *d_a, *d_b, *h_page, *h_pin;
    CHECK(cudaMalloc(&d_a, bytes)); CHECK(cudaMalloc(&d_b, bytes));
    h_page = (double *)malloc(bytes);
    CHECK(cudaMallocHost(&h_pin, bytes));
    for (size_t i = 0; i < n; i++) { h_page[i] = 1.0; h_pin[i] = 1.0; }
    CHECK(cudaMemcpy(d_a, h_page, bytes, cudaMemcpyHostToDevice));

    printf("n = %zu doubles, %.2f GB; best of 5 after a warm-up\n", n, bytes / 1e9);
    float t;
    t = time_copy(d_b, d_a, bytes, cudaMemcpyDeviceToDevice);
    printf("d2d   device to device: %.4f s, %.0f GB/s (read + write)\n", t, 2.0 * bytes / 1e9 / t);
    t = time_copy(d_a, h_page, bytes, cudaMemcpyHostToDevice);
    printf("h2d   host to device, pageable: %.4f s, %.1f GB/s\n", t, bytes / 1e9 / t);
    t = time_copy(d_a, h_pin, bytes, cudaMemcpyHostToDevice);
    printf("h2dp  host to device, pinned:   %.4f s, %.1f GB/s\n", t, bytes / 1e9 / t);
    t = time_copy(h_pin, d_a, bytes, cudaMemcpyDeviceToHost);
    printf("d2hp  device to host, pinned:   %.4f s, %.1f GB/s\n", t, bytes / 1e9 / t);

    CHECK(cudaFree(d_a)); CHECK(cudaFree(d_b)); free(h_page); CHECK(cudaFreeHost(h_pin));
    return 0;
}
