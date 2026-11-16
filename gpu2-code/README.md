# gpu2-code: companion programs of CUDA Lecture 2

Built with nvcc 12.8, `-arch=sm_70`, on Centaurus partition `GPU`, Titan V
(gal-gpu3). Results are recorded below with their date and node; a frame
number refers to `gpu2.tex`.

| Program | Frames | What it shows |
|---|---|---|
| `hello_nosync.cu` | 3 | The same kernel without `cudaDeviceSynchronize`: main returns first and nothing is printed (run 5 times in the Slurm script, to show it is not chance). |
| `devptr_wrong.cu` | 5 | The correct malloc / cudaMalloc / cudaMemcpy pattern, then the host reads `d_a[0]`: a segmentation fault. |
| `scale_wrong.cu` | 6, 7 | `a[i] = 2 * a[i]` launched as one block of 2e8 threads: refused, and silent without a check (`nocheck`); `CHECK(cudaGetLastError())` names the error (`check`). |
| `scale.cu` | 7, 8 | The same loop as a grid of (n + 255) / 256 blocks of 256 with the guard `if (i < n)`; checks every element; `./scale 1000` is a size 256 does not divide. `./scale time`: the kernel alone, and the kernel with both copies from pageable and from pinned host memory, best of 5 after a warm-up, CUDA events. |
| `scale_omp.c` | 8 | The same loop on gal-c1 with OpenMP, 36 threads bound to cores, parallel initialization, best of 5 (`run_gpu2_cpu.slurm`). |
| `sum_race.cu` | 9 | The sum with `*sum += a[i]` from every thread: a data race; three runs. |
| `sum_atomic.cu` | 10 | The sum with `atomicAdd(sum, a[i])` from every thread: correct; kernel time, warm-up then best of 5. |
| `sum_partial.cu` | 11 | The sum with a private partial per thread (grid-stride loop) and one `atomicAdd` per thread; 640 blocks of 256 = 163840 threads; kernel time, warm-up then best of 5; also run at 80, 320, 1280 blocks. |
| `matmul.cu` | 13, 14 | C = AB, one thread per element, 16 x 16 blocks, FP32 (and FP64 for the record); N = 2000 and 4096; warm-up then best of 5; 1000 entries checked against the host. Beside cuBLAS's 13.0 TFLOP/s (Lecture 1). |
| `hello.cu` | 2, 4 | The first kernel: `hello<<<1,4>>>` prints "Hello world from thread N of 4"; `./hello 2 4` launches two blocks of four and prints block numbers (frame 4). |

`run_gpu2.slurm` has one labeled section per frame and reserves
`gpu:TitanV:1`. `run_gpu2_cpu.slurm` runs the CPU comparison of frame 8 on
gal-c1 (partition Centaurus, exclusive, 36 threads).

## Results

(none yet: `make clean`, then `sbatch run_gpu2.slurm` and `sbatch run_gpu2_cpu.slurm`; paste the outputs here with date and node, then fill the `\tbd` marks of gpu2.tex from them. Frames 14 to 17 carry no measured numbers of their own; frame 16's two marks repeat frames 11 and 13.)
