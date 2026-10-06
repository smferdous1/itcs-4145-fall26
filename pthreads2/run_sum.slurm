#!/bin/bash
# ITCS 4145, pthreads Lecture 2: timing runs.
# Submit from the directory holding sum_time.c:   sbatch run_sum.slurm
# Results land in sum_times.txt (and the Slurm log).
#
#SBATCH --partition=Centaurus
#SBATCH --job-name=sum_time
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=36           # one whole node: 2 sockets x 18 cores
#SBATCH --exclusive                  # no other job on the node while timing
#SBATCH --mem=16G
#SBATCH --time=00:15:00
#SBATCH --output=sum_time_%j.log

set -e
gcc -Wall -pthread sum_time.c -o sum_time

N=200000000                          # 2e8 doubles = 1.6 GB, far beyond L3
OUT=sum_times.txt

{
  echo "# node: $(hostname)   date: $(date)"
  echo "# gcc -pthread, n = $N, best of 5 runs, parallel phase only"
  echo "# mode   threads          n   seconds  check"
  #  the correct program across thread counts.
  # 1..18 stay on one socket; 36 uses both sockets (NUMA not yet taught).
  for p in 1 2 4 8 12 18 36; do
    ./sum_time $p local $N
  done
  echo
  #  false sharing. Same per-iteration store, slots on one line
  # (slot) versus one line per thread (padded).
  for p in 1 2 4 8 18; do
    ./sum_time $p slot   $N
    ./sum_time $p padded $N
  done
} | tee $OUT
