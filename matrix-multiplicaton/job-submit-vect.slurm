#!/bin/bash

#SBATCH --partition=Centaurus
#SBATCH --job-name=add
#SBATCH --time=00:05:00

rm mmm 
g++ -O3 -march=native -mprefer-vector-width=512 mmm.cpp -o mmm_o3
srun ./mmm_o3 1100
srun ./mmm_o3 2000
