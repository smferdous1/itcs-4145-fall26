/* scale_omp.c: a[i] = 2 * a[i] on the CPU node with OpenMP, for the frame 8
 * comparison. Protocol as the OpenMP unit: n = 2e8, parallel initialization
 * (first touch), omp_get_wtime, best of 5 after a warm-up, -O2.
 * Build: gcc -O2 -fopenmp -o scale_omp scale_omp.c
 * Run:   OMP_PROC_BIND=true OMP_PLACES=cores OMP_NUM_THREADS=36 ./scale_omp
 */
#include <stdio.h>
#include <stdlib.h>
#include <omp.h>

int main(void) {
    long n = 200000000L;
    double *a = malloc(n * sizeof(double));
    #pragma omp parallel for
    for (long i = 0; i < n; i++) a[i] = 1.0;      /* parallel initialization */
    double best = 1e30;
    for (int r = 0; r < 6; r++) {                 /* r = 0 is the warm-up */
        double t0 = omp_get_wtime();
        #pragma omp parallel for
        for (long i = 0; i < n; i++) a[i] = 2 * a[i];
        double t = omp_get_wtime() - t0;
        if (r > 0 && t < best) best = t;
        #pragma omp parallel for
        for (long i = 0; i < n; i++) a[i] = 1.0;  /* reset */
    }
    printf("%d threads: %.4f s  (%.0f GB/s for 3.2 GB)\n",
           omp_get_max_threads(), best, 3.2 / best);
    free(a);
    return 0;
}
