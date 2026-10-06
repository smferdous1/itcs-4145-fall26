CC = gcc
CFLAGS = -Wall -pthread
TARGET = sum_v1 sum_v2 sum_time

all: $(TARGET)

sum_v1: sum_v1.c
	$(CC) $(CFLAGS) $< -o $@

sum_v2: sum_v2.c
	$(CC) $(CFLAGS) $< -o $@

sum_time: sum_time.c
	$(CC) $(CFLAGS) $< -o $@

clean:
	rm -f $(TARGET)

.PHONY: all clean