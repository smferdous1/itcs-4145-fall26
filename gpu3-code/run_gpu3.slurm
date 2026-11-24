#!/bin/bash
# run_gpu3.slurm: every new measured number of Lecture 3 on the Titan V, one
# labeled section per frame. Submit with: sbatch run_gpu3.slurm
# (The CPU node comparison runs separately on gal-c1: run_gpu3_cpu.slurm.
#  The matrix multiply numbers on frame 13 are Lecture 2's run of Nov 16;
#  the section below repeats it as a check.)
#SBATCH --job-name=gpu3
#SBATCH --partition=GPU
#SBATCH --gres=gpu:TitanV:1
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --time=00:30:00
#SBATCH --output=gpu3-%j.out

set -e
cd "$SLURM_SUBMIT_DIR"
module load cuda 2>/dev/null || true
date; hostname; nvcc --version | tail -1
nvidia-smi --query-gpu=name --format=csv,noheader
make clean; make dot matvec matmul

echo "=== frames 2 and 5: the dot product (our kernel, cuBLAS) ==="
./dot

echo "=== frames 6, 9, 11: the matrix-vector product (thread per row, transposed, block per row, cuBLAS) ==="
./matvec

echo "=== frame 13: the matrix multiply, N = 2000 and 4096 (repeat of Lecture 2) ==="
./matmul 2000
./matmul 4096
date
