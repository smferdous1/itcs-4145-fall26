# ITCS 4145, Programming with CUDA, Lecture 1 companion programs.
# nvcc 12.8 on Centaurus. Each target builds only itself (never make clean
# from a Slurm script that may run beside another job).
NVCC   = nvcc
NVFLAGS = -O2

all: devq bw gemm_time

devq: devq.cu
	$(NVCC) $(NVFLAGS) -o devq devq.cu

bw: bw.cu
	$(NVCC) $(NVFLAGS) -o bw bw.cu

gemm_time: gemm_time.cu
	$(NVCC) $(NVFLAGS) -o gemm_time gemm_time.cu -lcublas

clean:
	rm -f devq bw gemm_time
