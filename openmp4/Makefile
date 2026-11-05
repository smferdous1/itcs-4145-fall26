# ITCS 4145, OpenMP Lecture 4 companion programs (gcc -O2: the timings
# compare recursion structures, so the optimized build is the fair one).
CC = gcc
CFLAGS = -O2 -Wall -fopenmp
PROGS = task_hello fib_wrong fib task_cost msort

all: $(PROGS)

%: %.c
	$(CC) $(CFLAGS) $< -o $@

clean:
	rm -f $(PROGS)
