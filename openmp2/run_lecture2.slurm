#!/bin/bash
# ITCS 4145, OpenMP Lecture 2: companion runs on Centaurus (gal-c1).
# Submit from the openmp2-code directory:  sbatch run_lecture2.slurm
# Output: lecture2-<jobid>.out, one labeled section per frame.
#
#SBATCH --job-name=omp-lec2
#SBATCH --partition=Centaurus
#SBATCH --nodelist=gal-c1
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=36
#SBATCH --exclusive
#SBATCH --time=00:10:00
#SBATCH --output=lecture2-%j.out

set -u
echo "node: $(hostname)   date: $(date)"
echo "gcc:  $(gcc --version | head -1)"
echo
echo "===== Node layout (for frames 10 to 13) ====="
lscpu | grep -E "^(CPU\(s\)|Thread\(s\) per core|Core\(s\) per socket|Socket\(s\)|NUMA node|Model name|L1d|L2|L3)"
echo
numactl -H 2>/dev/null || echo "numactl not available"

make clean > /dev/null
make

echo
echo "===== Frame 2: temp_wrong (temporary declared before the loop), 36 threads, three runs ====="
for i in 1 2 3; do OMP_NUM_THREADS=36 ./temp_wrong; done
echo "--- 8 threads, three runs"
for i in 1 2 3; do OMP_NUM_THREADS=8 ./temp_wrong; done

echo
echo "===== Frame 4: temp_fixed (private(t)), 36 threads, three runs ====="
for i in 1 2 3; do OMP_NUM_THREADS=36 ./temp_fixed; done
echo
echo "===== Frame 4: temp_none (default(none), t not listed): compiler message ====="
gcc -Wall -fopenmp temp_none.c -o temp_none 2>&1 | head -6

echo
echo "===== Frame 7: schedule_print, n = 16, p = 4: thread per iteration under each schedule ====="
for sch in static static,2 dynamic,2 guided,1; do
    printf "%-10s " "$sch"; OMP_SCHEDULE=$sch ./schedule_print
done

echo
echo "===== Frame 10: where, 8 threads, unbound (two regions) ====="
OMP_NUM_THREADS=8 ./where
echo "--- bound: OMP_PROC_BIND=true OMP_PLACES=cores"
OMP_NUM_THREADS=8 OMP_PROC_BIND=true OMP_PLACES=cores ./where
echo "--- bound, 36 threads"
OMP_NUM_THREADS=36 OMP_PROC_BIND=true OMP_PLACES=cores ./where
