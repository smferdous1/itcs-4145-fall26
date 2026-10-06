#!/bin/bash

#SBATCH --partition=Centaurus
#SBATCH --job-name=add
#SBATCH --time=00:05:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=36

make clean
make



echo "hello_wrong"
echo "---------"
./hello_wrong

echo "hello"
echo "---------"
./hello


