/* devq.cu: print what the driver reports about each GPU of the node.
 * ITCS 4145, Programming with CUDA, Lecture 1, frame 2 (and inputs of
 * frames 8 and 9). No kernel is launched; cudaGetDeviceProperties only.
 * Build: nvcc -O2 -o devq devq.cu       Run: srun -p GPU --gres=gpu:1 ./devq
 */
#include <stdio.h>
#include <cuda_runtime.h>

/* FP32 lanes per SM by compute capability (CUDA samples, helper_cuda.h). */
static int lanes_per_sm(int major, int minor) {
    if (major == 6 && minor == 1) return 128;   /* Pascal GP102 (1080 Ti) */
    if (major == 6 && minor == 0) return 64;    /* Pascal GP100 */
    if (major == 7 && minor == 0) return 64;    /* Volta (V100) */
    if (major == 7 && minor == 5) return 64;    /* Turing (Titan RTX) */
    if (major == 8 && minor == 0) return 64;    /* Ampere A100 */
    if (major == 8)               return 128;   /* other Ampere, Ada */
    if (major == 9)               return 128;   /* Hopper */
    return -1;
}

int main(void) {
    int n = 0;
    cudaError_t e = cudaGetDeviceCount(&n);
    if (e != cudaSuccess) { fprintf(stderr, "cudaGetDeviceCount: %s\n", cudaGetErrorString(e)); return 1; }
    printf("devices on this node: %d\n", n);
    for (int d = 0; d < n; d++) {
        cudaDeviceProp p;
        cudaGetDeviceProperties(&p, d);
        int lanes = lanes_per_sm(p.major, p.minor);
        double ghz = p.clockRate / 1.0e6;                 /* kHz -> GHz */
        double mem_ghz = p.memoryClockRate / 1.0e6;
        printf("device %d: %s\n", d, p.name);
        printf("compute capability: %d.%d\n", p.major, p.minor);
        printf("multiprocessors: %d\n", p.multiProcessorCount);
        printf("FP32 lanes per multiprocessor: %d (from the capability)\n", lanes);
        printf("clock: %.3f GHz\n", ghz);
        if (lanes > 0)
            printf("peak FP32: %d x %d x 2 x %.3f = %.1f TFLOP/s\n",
                   p.multiProcessorCount, lanes, ghz,
                   p.multiProcessorCount * lanes * 2.0 * ghz / 1000.0);
        printf("memory: %.1f GB\n", p.totalGlobalMem / 1.0e9);
        printf("memory clock: %.3f GHz, bus %d bits\n", mem_ghz, p.memoryBusWidth);
        printf("peak memory bandwidth: %.3f x %d / 8 x 2 = %.0f GB/s\n",
               mem_ghz, p.memoryBusWidth,
               mem_ghz * p.memoryBusWidth / 8.0 * 2.0);       /* double data rate */
        printf("L2 cache: %d KB\n", p.l2CacheSize / 1024);
        printf("warp size: %d\n", p.warpSize);
        printf("max threads per multiprocessor: %d\n", p.maxThreadsPerMultiProcessor);
        printf("max threads per block: %d\n", p.maxThreadsPerBlock);
        printf("registers per multiprocessor: %d (32-bit)\n", p.regsPerMultiprocessor);
        printf("shared memory per multiprocessor: %zu KB\n", p.sharedMemPerMultiprocessor / 1024);
        printf("\n");
    }
    return 0;
}
