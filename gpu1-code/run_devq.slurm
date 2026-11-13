#!/bin/bash
# run_devq.slurm: devq only, for the frame 2 table (one row per GPU type).
# Submit once per type, naming the type on the command line, which overrides
# the gres below:
#   sbatch --gres=gpu:TitanRTX:1  run_devq.slurm
#   sbatch --gres=gpu:GTX1080ti:1 run_devq.slurm     (done Nov 11 on gal-gpu5)
# The Titan V row comes from run_gpu1.slurm.
#SBATCH --job-name=devq
#SBATCH --partition=GPU
#SBATCH --gres=gpu:TitanV:1
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --time=00:05:00
#SBATCH --output=devq-%j.out

cd "$SLURM_SUBMIT_DIR"
module load cuda 2>/dev/null || true
date; hostname
nvidia-smi --query-gpu=name,memory.total,clocks.max.sm --format=csv
make devq
./devq
