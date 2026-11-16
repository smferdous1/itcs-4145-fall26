/* devptr_wrong.cu: the host dereferences a device pointer.
 * ITCS 4145, Programming with CUDA, Lecture 2, frame 5 (wrong program).
 * Expected: a segmentation fault at the printf. The pattern above it
 * (malloc, cudaMalloc, cudaMemcpy, cudaFree) is the frame's correct one.
 * Build: nvcc -arch=sm_70 -o devptr_wrong devptr_wrong.cu
 */
#include <stdio.h>
#include <stdlib.h>

int main(void) {
    size_t n = 1000;
    double *a = (double *)malloc(n * sizeof(double));   /* host */
    for (size_t i = 0; i < n; i++) a[i] = 1.0;
    double *d_a;                                         /* device */
    cudaMalloc(&d_a, n * sizeof(double));
    cudaMemcpy(d_a, a, n * sizeof(double), cudaMemcpyHostToDevice);
    printf("a[0] on the host:   %f\n", a[0]);
    printf("d_a[0] on the host: ");
    fflush(stdout);
    printf("%f\n", d_a[0]);        /* wrong: host reads device memory */
    cudaFree(d_a); free(a);
    return 0;
}
