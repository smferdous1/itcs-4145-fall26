#!/bin/bash
# run_gpu3_cpu.slurm: the CPU node side of frames 5 and 11 on gal-c1.
#SBATCH --job-name=gpu3cpu
#SBATCH --partition=Centaurus
#SBATCH --nodelist=gal-c1
#SBATCH --exclusive
#SBATCH --cpus-per-task=36
#SBATCH --time=00:10:00
#SBATCH --output=gpu3cpu-%j.out

cd "$SLURM_SUBMIT_DIR"
date; hostname
gcc -O2 -fopenmp -o blas_cpu blas_cpu.c
echo "=== frames 5, 11: dot product and matrix-vector product on the CPU node, 36 threads ==="
OMP_PROC_BIND=true OMP_PLACES=cores OMP_NUM_THREADS=36 ./blas_cpu
