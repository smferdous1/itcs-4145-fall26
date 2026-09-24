#!/bin/bash

#SBATCH --partition=Centaurus
#SBATCH --job-name=add
#SBATCH --time=00:05:00

rm stride

g++ -o stride -O3 add-stride.cpp

./stride

