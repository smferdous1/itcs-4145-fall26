# ITCS 4145, OpenMP Lecture 1 companion programs
CC = gcc
CFLAGS = -Wall

all: hello0 hello0_seq hello threads hello_wrong hello_private sum_wrong sum sum_time

hello0: hello0.c
	$(CC) $(CFLAGS) -fopenmp $< -o $@

hello: hello.c
	$(CC) $(CFLAGS) -fopenmp $< -o $@

threads: threads.c
	$(CC) $(CFLAGS) -fopenmp $< -o $@

hello_wrong: hello_wrong.c
	$(CC) $(CFLAGS) -fopenmp $< -o $@

hello_private: hello_private.c
	$(CC) $(CFLAGS) -fopenmp $< -o $@

# sum programs are built unoptimized, as in the pthreads unit
sum_wrong: sum_wrong.c
	$(CC) $(CFLAGS) -fopenmp $< -o $@

sum: sum.c
	$(CC) $(CFLAGS) -fopenmp $< -o $@

sum_time: sum_time.c
	$(CC) $(CFLAGS) -fopenmp $< -o $@

# hello0_seq: the same source compiled without -fopenmp (the pragma is ignored)
hello0_seq: hello0.c
	$(CC) $(CFLAGS) $< -o $@

clean:
	rm -f hello0 hello0_seq hello threads hello_wrong hello_private sum_wrong sum sum_time
