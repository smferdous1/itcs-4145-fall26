#!/bin/bash
# ITCS 4145, OpenMP Lecture 3: correctness runs on Centaurus (gal-c1); the
# timing runs are in run_sum_sync.slurm.
# Submit from openmp3-code:  sbatch run_lecture3.slurm  -> lecture3-<jobid>.out
#
#SBATCH --job-name=omp-lec3
#SBATCH --partition=Centaurus
#SBATCH --nodelist=gal-c1
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=36
#SBATCH --exclusive
#SBATCH --time=00:10:00
#SBATCH --output=lecture3-%j.out

set -u
echo "node: $(hostname)   date: $(date)"
echo "gcc:  $(gcc --version | head -1)"
make filter buffer

echo
echo "===== Frame 7: filter (atomic capture), p = 36, three runs; then p = 1 ====="
for r in 1 2 3; do ./filter 36; done
./filter 1

echo
echo "===== Frame 10: buffer, p = 36, 1000 regions each: master (wrong), master+barrier, single ====="
for mode in master master+barrier single; do ./buffer 36 $mode; done
