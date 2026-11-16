#!/bin/bash
# run_gpu2.slurm: every measured number of Lecture 2 on the Titan V, one
# labeled section per frame. Submit with: sbatch run_gpu2.slurm
# (Frame 8's CPU comparison runs separately on gal-c1: run_gpu2_cpu.slurm.)
#SBATCH --job-name=gpu2
#SBATCH --partition=GPU
#SBATCH --gres=gpu:TitanV:1
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --time=00:20:00
#SBATCH --output=gpu2-%j.out

set -e
cd "$SLURM_SUBMIT_DIR"
module load cuda 2>/dev/null || true
date; hostname; nvcc --version | tail -1
nvidia-smi --query-gpu=name --format=csv,noheader

echo "=== frame 2: hello, one block of four threads ==="
make hello
./hello 1 4

echo "=== frame 3: hello without the wait (expect no output; 5 runs) ==="
make hello_nosync
for r in 1 2 3 4 5; do echo "run $r:"; ./hello_nosync; done

echo "=== frame 4: hello, two blocks of four; which block prints first? (20 runs) ==="
for r in $(seq 1 20); do ./hello 2 4 | head -1; done | sort | uniq -c
echo "one full run:"; ./hello 2 4

echo "=== frame 5: the host dereferences a device pointer (expect a segmentation fault) ==="
make devptr_wrong
./devptr_wrong || echo "exit status $?"

echo "=== frame 6: the loop as one block of n threads, unchecked ==="
make scale_wrong
./scale_wrong nocheck
echo "=== frame 7: the same launch, checked ==="
./scale_wrong check || echo "exit status $?"
echo "=== frame 7: a grid of blocks with the guard ==="
make scale
./scale
./scale 1000
echo "=== frame 8: timing the scale kernel, with and without the copies ==="
./scale time
echo "=== frame 9: the sum with one shared variable (3 runs) ==="
make sum_race
./sum_race; ./sum_race; ./sum_race
echo "=== frame 10: the sum with atomicAdd from every thread ==="
make sum_atomic
./sum_atomic
echo "=== frame 11: private partials, one atomicAdd per thread (640 blocks; and 80, 320, 1280) ==="
make sum_partial
./sum_partial 640
for b in 80 320 1280; do ./sum_partial $b | tail -1; done
echo "=== frame 13: the matrix multiply kernel, N = 2000 and 4096 ==="
make matmul
./matmul 2000
./matmul 4096
