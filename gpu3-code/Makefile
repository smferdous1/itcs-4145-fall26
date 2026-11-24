# ITCS 4145, Programming with CUDA, Lecture 3 companion programs.
# nvcc 12.8 on Centaurus; the Titan V is compute capability 7.0 (sm_70).
# dot and matvec link cuBLAS for the library comparison. Each target builds
# only itself.
NVCC    = nvcc
NVFLAGS = -O2 -arch=sm_70 -Wno-deprecated-gpu-targets

all: dot matvec matmul

dot: dot.cu
	$(NVCC) $(NVFLAGS) -o dot dot.cu -lcublas

matvec: matvec.cu
	$(NVCC) $(NVFLAGS) -o matvec matvec.cu -lcublas

matmul: matmul.cu
	$(NVCC) $(NVFLAGS) -o matmul matmul.cu

blas_cpu: blas_cpu.c
	gcc -O2 -fopenmp -o blas_cpu blas_cpu.c

clean:
	rm -f dot matvec matmul blas_cpu
