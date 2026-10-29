#!/bin/bash
# ITCS 4145, OpenMP Lecture 3, frame 6: the counter (elements above 0.5 in
# 1e8 random doubles) with reduction, critical, atomic.
# gcc -O2, parallel phase only, best of five, as pthreads Lecture 3 frame 9.
# Submit from openmp3-code:  sbatch run_count_sync.slurm -> countsync-<jobid>.out
# (The same sections are also at the end of run_sum_sync.slurm.)
#
#SBATCH --job-name=omp-count
#SBATCH --partition=Centaurus
#SBATCH --nodelist=gal-c1
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=36
#SBATCH --exclusive
#SBATCH --time=00:20:00
#SBATCH --output=countsync-%j.out

set -u
echo "node: $(hostname)   date: $(date)"
echo "gcc:  $(gcc --version | head -1)"
make count_sync

for mode in reduction critical atomic; do
    echo
    echo "===== Frame 6: count_sync $mode, p = 1 2 4 8 18 36 ====="
    for p in 1 2 4 8 18 36; do
        ./count_sync $p $mode
    done
done
