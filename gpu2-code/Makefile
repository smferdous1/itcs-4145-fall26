# ITCS 4145, Programming with CUDA, Lecture 2 companion programs.
# nvcc 12.8 on Centaurus; the Titan V is compute capability 7.0 (sm_70).
# Each target builds only itself. Run "make clean" by hand before a run on a
# node of another GPU type (binaries copied with the folder look up to date).
NVCC    = nvcc
NVFLAGS = -O2 -arch=sm_70 -Wno-deprecated-gpu-targets

all: hello hello_nosync devptr_wrong scale_wrong scale sum_race sum_atomic sum_partial matmul

hello: hello.cu
	$(NVCC) $(NVFLAGS) -o hello hello.cu

hello_nosync: hello_nosync.cu
	$(NVCC) $(NVFLAGS) -o hello_nosync hello_nosync.cu

devptr_wrong: devptr_wrong.cu
	$(NVCC) $(NVFLAGS) -o devptr_wrong devptr_wrong.cu

scale_wrong: scale_wrong.cu
	$(NVCC) $(NVFLAGS) -o scale_wrong scale_wrong.cu

scale: scale.cu
	$(NVCC) $(NVFLAGS) -o scale scale.cu

sum_race: sum_race.cu
	$(NVCC) $(NVFLAGS) -o sum_race sum_race.cu

sum_atomic: sum_atomic.cu
	$(NVCC) $(NVFLAGS) -o sum_atomic sum_atomic.cu

sum_partial: sum_partial.cu
	$(NVCC) $(NVFLAGS) -o sum_partial sum_partial.cu

matmul: matmul.cu
	$(NVCC) $(NVFLAGS) -o matmul matmul.cu

clean:
	rm -f hello hello_nosync devptr_wrong scale_wrong scale sum_race sum_atomic sum_partial matmul
