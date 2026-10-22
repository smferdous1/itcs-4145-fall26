#!/bin/bash
# ITCS 4145, OpenMP Lecture 2, frames 8 and 9: the unbalanced loop under
# each schedule, on gal-c1. n = 20000 iterations, iteration i does 20*i steps.
# Submit from openmp2-code:  sbatch run_schedule.slurm   -> schedule-<jobid>.out
#
#SBATCH --job-name=omp-sched
#SBATCH --partition=Centaurus
#SBATCH --nodelist=gal-c1
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=36
#SBATCH --exclusive
#SBATCH --time=00:15:00
#SBATCH --output=schedule-%j.out

set -u
echo "node: $(hostname)   date: $(date)"
make imbalance

echo
echo "===== Frame 8: imbalance, p = 1 (total work) and p = 36 static with per-thread times ====="
OMP_SCHEDULE=static ./imbalance 1
OMP_SCHEDULE=static ./imbalance 36 -v

echo
echo "===== Frame 9: imbalance, p = 36, each schedule (best of three runs is the number for the frame) ====="
for sch in static static,16 static,1 dynamic,1 dynamic,16 dynamic,256 guided,1; do
    for r in 1 2 3; do printf "%-12s " "$sch"; OMP_SCHEDULE=$sch ./imbalance 36; done
done
