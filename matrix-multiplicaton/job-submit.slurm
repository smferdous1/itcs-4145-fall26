#!/bin/bash

#SBATCH --partition=Centaurus
#SBATCH --job-name=add
#SBATCH --time=00:05:00

rm mmm 

g++ -o mmm -O2 add-mmm.cpp

./mmm

