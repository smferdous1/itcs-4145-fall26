#!/bin/bash
# ITCS 4145, pthreads Lecture 3, frame 7: one shared counter, three ways.
# Submit from the directory holding count_atomic.c:   sbatch run_count.slurm
# Results land in count_times.txt (and the Slurm log).
#
#SBATCH --job-name=count_atomic
#SBATCH --partition=Centaurus        # adjust to the CPU partition name
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=36
#SBATCH --exclusive
#SBATCH --mem=8G
#SBATCH --time=00:30:00
#SBATCH --output=count_atomic_%j.log

set -e
gcc -O2 -Wall -pthread count_atomic.c -o count_atomic

N=100000000
OUT=count_times.txt
{
  echo "# node: $(hostname)   date: $(date)"
  echo "# gcc -O2 -pthread, n = $N (about n/2 increments), best of 3, parallel phase only"
  echo "# mode    threads          n   seconds  check"
  for p in 1 2 4 8 18; do
    ./count_atomic $p private $N
    ./count_atomic $p atomic  $N
    ./count_atomic $p mutex   $N
  done
} | tee $OUT
