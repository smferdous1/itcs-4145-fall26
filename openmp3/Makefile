# ITCS 4145, OpenMP Lecture 3 companion programs.
# sum_sync, count_sync and max_sync are built with -O2 to match the pthreads Lecture 3 measurement;
# everything else unoptimized, as in the rest of the unit.
CC = gcc
CFLAGS = -Wall -fopenmp

all: sum_sync count_sync filter max_sync buffer

sum_sync: sum_sync.c
	$(CC) -O2 $(CFLAGS) $< -o $@

count_sync: count_sync.c
	$(CC) -O2 $(CFLAGS) $< -o $@

filter: filter.c
	$(CC) $(CFLAGS) $< -o $@

max_sync: max_sync.c
	$(CC) -O2 $(CFLAGS) $< -o $@

buffer: buffer.c
	$(CC) $(CFLAGS) $< -o $@

clean:
	rm -f sum_sync count_sync filter max_sync buffer
