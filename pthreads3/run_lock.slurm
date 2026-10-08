#!/bin/bash
# ITCS 4145, pthreads Lecture 3, frames 4 and 5: the sum with a mutex.
# Submit from the directory holding sum_lock.c:   sbatch run_lock.slurm
# Results land in lock_times.txt (and the Slurm log).
#
#SBATCH --job-name=sum_lock
#SBATCH --partition=Centaurus        # adjust to the CPU partition name
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=36
#SBATCH --exclusive
#SBATCH --mem=16G
#SBATCH --time=00:40:00              # the inner-lock runs are slow by design
#SBATCH --output=sum_lock_%j.log

set -e
gcc -O2 -Wall -pthread sum_lock.c -o sum_lock

N=200000000
OUT=lock_times.txt
{
  echo "# node: $(hostname)   date: $(date)"
  echo "# gcc -O2 -pthread, n = $N, best of 5 (inner: best of 2), parallel phase only"
  echo "# mode    threads          n   seconds         sum  check"
  for p in 1 2 4 8 18; do
    ./sum_lock $p private $N
    ./sum_lock $p outer   $N
    ./sum_lock $p inner   $N
  done
} | tee $OUT
