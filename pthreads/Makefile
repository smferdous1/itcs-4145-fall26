CC     = gcc
CFLAGS = -Wall -pthread
PROGS  = hello_wrong hello hello_nojoin hello_malloc

all: $(PROGS)

%: %.c
	$(CC) $(CFLAGS) $< -o $@

clean:
	rm -f $(PROGS)
