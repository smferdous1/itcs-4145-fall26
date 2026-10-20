#!/bin/bash
# ITCS 4145, OpenMP Lecture 1, frame 13: timing of the reduction sum on gal-c1.
# Same protocol as pthreads2-code/run_sum.slurm: n = 2e8, unoptimized build,
# parallel phase only, best of five, p in 1 2 4 8 12 18 36.
# Submit from openmp1-code:  sbatch run_sum.slurm   -> sum-<jobid>.out
#
#SBATCH --job-name=omp-sum
#SBATCH --partition=Centaurus
#SBATCH --nodelist=gal-c1
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=36
#SBATCH --exclusive
#SBATCH --time=00:10:00
#SBATCH --output=sum-%j.out

set -u
echo "node: $(hostname)   date: $(date)"
echo "gcc:  $(gcc --version | head -1)"
make sum_time

echo
echo "===== Frame 13: sum_time (reduction), n = 2e8, best of 5, parallel phase only ====="
for p in 1 2 4 8 12 18 36; do
    ./sum_time $p
done
