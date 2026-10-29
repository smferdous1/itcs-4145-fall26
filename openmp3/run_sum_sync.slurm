#!/bin/bash
# ITCS 4145, OpenMP Lecture 3, frames 3, 4 and 6: the sum with reduction,
# critical per element, critical once per thread, atomic per element.
# gcc -O2, n = 2e8, parallel phase only, best of five, as pthreads Lecture 3.
# Submit from openmp3-code:  sbatch run_sum_sync.slurm  -> sumsync-<jobid>.out
#
#SBATCH --job-name=omp-sync
#SBATCH --partition=Centaurus
#SBATCH --nodelist=gal-c1
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=36
#SBATCH --exclusive
#SBATCH --time=00:40:00
#SBATCH --output=sumsync-%j.out

set -u
echo "node: $(hostname)   date: $(date)"
echo "gcc:  $(gcc --version | head -1)"
make sum_sync

for mode in reduction critical once atomic; do
    echo
    echo "===== Frames 3, 4, 6: sum_sync $mode, p = 1 2 4 8 18 36 ====="
    for p in 1 2 4 8 18 36; do
        ./sum_sync $p $mode
    done
done
