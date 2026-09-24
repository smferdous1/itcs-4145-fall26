#!/bin/bash

#SBATCH --partition=Centaurus
#SBATCH --job-name=add
#SBATCH --time=00:05:00
#SBATCH --mem=128GB

rm add

#vector addition with vectorization activated
g++ -O3 -o add -march=native vec-add-test.cpp

#turn off vectorization
#g++ -o add -O0 -fno-tree-loop-vectorize vec-add-test.cpp

time ./add 100
time ./add 1000
time ./add 10000
time ./add 100000
time ./add 1000000
time ./add 10000000
time ./add 100000000
time ./add 1000000000

