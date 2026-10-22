#!/bin/bash
# ITCS 4145, OpenMP Lecture 2, frames 11 to 13: the reduction sum with the
# array touched by main (seq) or by the threads (par), threads bound to cores.
# Submit from openmp2-code:  sbatch run_touch.slurm   -> touch-<jobid>.out
#
#SBATCH --job-name=omp-touch
#SBATCH --partition=Centaurus
#SBATCH --nodelist=gal-c1
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=36
#SBATCH --exclusive
#SBATCH --time=00:15:00
#SBATCH --output=touch-%j.out

set -u
echo "node: $(hostname)   date: $(date)"
make sum_touch
export OMP_PROC_BIND=true
export OMP_PLACES=cores

echo
echo "===== Frames 11 and 13: sum_touch, n = 2e8, best of 5, threads bound to cores ====="
for p in 1 2 4 8 12 18 36; do
    ./sum_touch $p seq
    ./sum_touch $p par
done

echo
echo "===== Frame 13: the same at 36 threads without binding (for the record) ====="
unset OMP_PROC_BIND OMP_PLACES
./sum_touch 36 seq
./sum_touch 36 par
