#!/bin/bash

#SBATCH --partition=Centaurus
#SBATCH --job-name=add
#SBATCH --time=00:05:00

make clean
make



echo "hello_wrong"
echo "---------"
./hello_wrong

#echo "hello"
#echo "---------"
#./hello


