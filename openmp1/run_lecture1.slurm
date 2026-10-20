#!/bin/bash
# ITCS 4145, OpenMP Lecture 1: companion runs on Centaurus (gal-c1).
# Submit from the openmp1-code directory:  sbatch run_lecture1.slurm
# Output: lecture1-<jobid>.out, one labeled section per frame.
#
#SBATCH --job-name=omp-lec1
#SBATCH --partition=Centaurus
#SBATCH --nodelist=gal-c1
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=36
#SBATCH --exclusive
#SBATCH --time=00:05:00
#SBATCH --output=lecture1-%j.out

# module load gcc                     # uncomment if gcc is a module on Centaurus

set -u
echo "node: $(hostname)   date: $(date)"
echo "gcc:  $(gcc --version | head -1)"
echo "cores reported by nproc: $(nproc)"
echo

make clean > /dev/null
make

echo
echo "===== Frame 2: hello0 without -fopenmp (pragma ignored, one line) ====="
./hello0_seq

echo
echo "===== Frame 2: hello0 with -fopenmp, OMP_NUM_THREADS=4 (four lines) ====="
OMP_NUM_THREADS=4 ./hello0

echo
echo "===== Frame 4: hello, OMP_NUM_THREADS=4, one run ====="
OMP_NUM_THREADS=4 ./hello

echo
echo "===== Frame 4: hello, 100 runs, distinct line orders (count, order) ====="
for i in $(seq 100); do
    OMP_NUM_THREADS=4 ./hello | sed 's/Hello world from thread //; s/ of 4//' | tr '\n' ' '
    echo
done | sort | uniq -c | sort -rn

echo
echo "===== Frame 5: threads, OMP_NUM_THREADS=4 (expect 4, 3, 2) ====="
OMP_NUM_THREADS=4 ./threads

echo
echo "===== Frame 5 [TBD]: threads, OMP_NUM_THREADS unset (region 1 = default) ====="
unset OMP_NUM_THREADS
./threads

echo
echo "===== Frame 6: hello_wrong, OMP_NUM_THREADS=8, one run ====="
OMP_NUM_THREADS=8 ./hello_wrong

echo
echo "===== Frame 6: hello_wrong, 8 threads, 100 runs: ids printed per run, sorted (count, ids) ====="
for i in $(seq 100); do
    OMP_NUM_THREADS=8 ./hello_wrong | sed 's/Hello world from thread //; s/ of 8//' | sort -n | tr '\n' ' '
    echo
done | sort | uniq -c | sort -rn

echo
echo "===== Frame 6: hello_wrong, 36 threads, 1000 runs: how many runs printed some id twice ====="
bad=0
for i in $(seq 1000); do
    if [ -n "$(OMP_NUM_THREADS=36 ./hello_wrong | sed 's/Hello world from thread //; s/ of 36//' | sort -n | uniq -d)" ]; then
        bad=$((bad+1))
    fi
done
echo "runs with a repeated id: $bad of 1000"

echo
echo "===== Frame 8: hello (declared inside), 8 threads, 100 runs: ids per run, sorted (count, ids) ====="
for i in $(seq 100); do
    OMP_NUM_THREADS=8 ./hello | sed 's/Hello world from thread //; s/ of 8//' | sort -n | tr '\n' ' '
    echo
done | sort | uniq -c | sort -rn

echo
echo "===== Frame 8: hello_private (private clause), 8 threads, 100 runs: ids per run, sorted (count, ids) ====="
for i in $(seq 100); do
    OMP_NUM_THREADS=8 ./hello_private | sed 's/Hello world from thread //; s/ of 8//' | sort -n | tr '\n' ' '
    echo
done | sort | uniq -c | sort -rn

echo
echo "===== Frame 11: sum_wrong (shared sum), OMP_NUM_THREADS=8, three runs ====="
for i in 1 2 3; do OMP_NUM_THREADS=8 ./sum_wrong; done

echo
echo "===== Frame 12: sum (reduction), OMP_NUM_THREADS=8, three runs ====="
for i in 1 2 3; do OMP_NUM_THREADS=8 ./sum; done
