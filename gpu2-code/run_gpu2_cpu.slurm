#!/bin/bash
# run_gpu2_cpu.slurm: the CPU side of Lecture 2 frame 8 on gal-c1, as the
# OpenMP unit measured (exclusive node, 36 threads, bound to cores).
#SBATCH --job-name=gpu2cpu
#SBATCH --partition=Centaurus
#SBATCH --nodelist=gal-c1
#SBATCH --exclusive
#SBATCH --cpus-per-task=36
#SBATCH --time=00:10:00
#SBATCH --output=gpu2cpu-%j.out

cd "$SLURM_SUBMIT_DIR"
date; hostname
gcc -O2 -fopenmp -o scale_omp scale_omp.c
echo "=== frame 8: a[i] = 2 * a[i] on the CPU node, 36 threads ==="
for p in 1 36; do
  OMP_PROC_BIND=true OMP_PLACES=cores OMP_NUM_THREADS=$p ./scale_omp
done
