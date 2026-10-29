#!/bin/bash
# ITCS 4145, OpenMP Lecture 3, frame 9: the maximum (conditional update)
# with critical, the speculative check, and reduction(max:); gcc -O2,
# n = 2e8, parallel phase only, best of five.
# Submit from openmp3-code:  sbatch run_max.slurm  -> max-<jobid>.out
#
#SBATCH --job-name=omp-max
#SBATCH --partition=Centaurus
#SBATCH --nodelist=gal-c1
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=36
#SBATCH --exclusive
#SBATCH --time=00:30:00
#SBATCH --output=max-%j.out

set -u
echo "node: $(hostname)   date: $(date)"
make max_sync

for mode in reduction spec critical; do
    echo
    echo "===== Frame 9: max_sync $mode, p = 1 8 36 ====="
    for p in 1 8 36; do ./max_sync $p $mode; done
done
echo
echo "===== Frame 9 (record only): max_sync wrong, p = 36, three runs ====="
for r in 1 2 3; do ./max_sync 36 wrong; done
