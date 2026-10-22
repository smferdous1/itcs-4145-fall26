# ITCS 4145, OpenMP Lecture 2 companion programs (unoptimized, as in the unit)
CC = gcc
CFLAGS = -Wall -fopenmp

all: temp_wrong temp_fixed schedule_print imbalance where sum_touch

temp_wrong: temp_wrong.c
	$(CC) $(CFLAGS) $< -o $@

temp_fixed: temp_fixed.c
	$(CC) $(CFLAGS) $< -o $@

schedule_print: schedule_print.c
	$(CC) $(CFLAGS) $< -o $@

imbalance: imbalance.c
	$(CC) $(CFLAGS) $< -o $@

where: where.c
	$(CC) $(CFLAGS) $< -o $@

sum_touch: sum_touch.c
	$(CC) $(CFLAGS) $< -o $@

# temp_none.c does not compile: default(none) with t unlisted (frame 4)
temp_none: temp_none.c
	-$(CC) $(CFLAGS) $< -o $@

clean:
	rm -f temp_wrong temp_fixed temp_none schedule_print imbalance where sum_touch
