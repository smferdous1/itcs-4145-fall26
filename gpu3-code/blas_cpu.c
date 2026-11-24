/* blas_cpu.c: the dot product and the matrix-vector product on the CPU
 * node with OpenMP, for frames 5 and 11. Same sizes and values as dot.cu and
 * matvec.cu; parallel initialization (first touch); omp_get_wtime, warm-up
 * then best of 5; -O2.
 * Build: gcc -O2 -fopenmp -o blas_cpu blas_cpu.c
 * Run:   OMP_PROC_BIND=true OMP_PLACES=cores OMP_NUM_THREADS=36 ./blas_cpu
 */
#include <stdio.h>
#include <stdlib.h>
#include <omp.h>

int main(void) {
    long n = 200000000L;
    double *a = malloc(n * sizeof(double)), *b = malloc(n * sizeof(double));
    #pragma omp parallel for
    for (long i = 0; i < n; i++) { a[i] = 1.0; b[i] = 2.0; }
    double best = 1e30, dot = 0.0;
    for (int r = 0; r < 6; r++) {
        double t0 = omp_get_wtime(), s = 0.0;
        #pragma omp parallel for reduction(+:s)
        for (long i = 0; i < n; i++) s += a[i] * b[i];
        double t = omp_get_wtime() - t0;
        if (r > 0 && t < best) best = t;
        dot = s;
    }
    printf("dot,    %d threads: dot = %.0f; %.4f s (%.0f GB/s over 3.2 GB)\n",
           omp_get_max_threads(), dot, best, 3.2 / best);
    free(a); free(b);

    int N = 16384;
    double *A = malloc((size_t)N * N * sizeof(double)), *x = malloc(N * 8), *y = malloc(N * 8);
    #pragma omp parallel for
    for (int i = 0; i < N; i++)
        for (int j = 0; j < N; j++) A[(size_t)i * N + j] = (double)((i + 2 * j) % 7 - 3);
    for (int j = 0; j < N; j++) x[j] = (double)(j % 5 - 2);
    best = 1e30;
    for (int r = 0; r < 6; r++) {
        double t0 = omp_get_wtime();
        #pragma omp parallel for
        for (int i = 0; i < N; i++) {
            double s = 0.0;
            for (int k = 0; k < N; k++) s += A[(size_t)i * N + k] * x[k];
            y[i] = s;
        }
        double t = omp_get_wtime() - t0;
        if (r > 0 && t < best) best = t;
    }
    double bytes = (double)N * N * 8 / 1e9;
    printf("matvec, %d threads: N = %d, y[0] = %.0f; %.4f s (%.0f GB/s over %.2f GB)\n",
           omp_get_max_threads(), N, y[0], best, bytes / best, bytes);
    free(A); free(x); free(y);
    return 0;
}
