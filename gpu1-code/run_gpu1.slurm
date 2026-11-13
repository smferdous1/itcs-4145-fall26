#!/bin/bash
# run_gpu1.slurm: every measured number of Lecture 1, one labeled section
# per frame. Submit with: sbatch run_gpu1.slurm
# GPU type (sinfo -p GPU, Nov 11): gal-gpu3 gpu:TitanV:8 (Volta, the standard
# GPU of this unit); gal-gpu1, gal-gpu2 gpu:TitanRTX:4; gal-gpu4, 5, 6
# gpu:GTX1080ti:8. There is no V100. For the frame 2 rows of the other types,
# submit run_devq.slurm with the type on the command line:
#   sbatch --gres=gpu:TitanRTX:1 run_devq.slurm
#SBATCH --job-name=gpu1
#SBATCH --partition=GPU
#SBATCH --gres=gpu:TitanV:1
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --time=00:20:00
#SBATCH --output=gpu1-%j.out

set -e
cd "$SLURM_SUBMIT_DIR"
module load cuda 2>/dev/null || true
date; hostname; nvcc --version | tail -1
nvidia-smi --query-gpu=name --format=csv,noheader

echo "=== frame 2: the GPUs of Centaurus (run once per GPU type) ==="
nvidia-smi --query-gpu=name,memory.total,clocks.max.sm --format=csv
make devq
./devq

echo "=== frame 12: the Titan V streaming multiprocessor and its peak (Titan V only) ==="
echo "same devq output as frame 2; the frame uses: multiprocessors, FP32 lanes per"
echo "multiprocessor, clock, warp size, max threads per multiprocessor, registers"
echo "per multiprocessor, and the derived peak FP32 line"
./devq | grep -E "device|multiprocessor|clock|warp|registers|peak FP32"

echo "=== frame 13: memory bandwidth, derived (devq) and measured (bw d2d) ==="
./devq | grep -E "memory clock|peak memory bandwidth"
make bw
./bw

echo "=== frame 16: cuBLAS SGEMM vs tensor-core HGEMM on the Titan V, N = 4096 ==="
make gemm_time
./gemm_time 4096
./gemm_time 8192
