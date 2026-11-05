#!/bin/bash
# ITCS 4145, OpenMP Lecture 4: all companion runs on Centaurus (gal-c1).
# Submit from openmp4-code:  sbatch run_lecture4.slurm  -> lecture4-<jobid>.out
#
#SBATCH --job-name=omp-lec4
#SBATCH --partition=Centaurus
#SBATCH --nodelist=gal-c1
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=36
#SBATCH --exclusive
#SBATCH --time=00:30:00
#SBATCH --output=lecture4-%j.out

set -u
echo "node: $(hostname)   date: $(date)"
echo "gcc:  $(gcc --version | head -1)"
make clean > /dev/null; make

echo
echo "===== Frame 4: task_hello, 4 threads, two runs ====="
OMP_NUM_THREADS=4 ./task_hello; echo "---"; OMP_NUM_THREADS=4 ./task_hello

echo
echo "===== Frame 6: fib_wrong(20), 4 threads, three runs (expected 6765) ====="
for r in 1 2 3; do OMP_NUM_THREADS=4 ./fib_wrong 20 || echo "(crashed, exit $?)"; done

echo
echo "===== Frame 7: fib(30) with taskwait, no cut-off: p = 1 and 36 (expected 832040) ====="
./fib 30 0 1
./fib 30 0 36

echo
echo "===== Frame 8: task_cost, 1e6 empty tasks, p = 1 and 36 ====="
./task_cost 1000000 1
./task_cost 1000000 36

echo
echo "===== Frame 8: fib(36), p = 36, cut-off 0 10 15 20 25 30 (expected 14930352); sequential p = 1 cut-off 36 ====="
./fib 36 36 1
for c in 0 10 15 20 25 30; do ./fib 36 $c 36; done

echo
echo "===== Frame 10: msort, n = 1e8, cut-off 16384, p = 1 2 4 8 18 36 ====="
for p in 1 2 4 8 18 36; do ./msort 100000000 16384 $p; done
