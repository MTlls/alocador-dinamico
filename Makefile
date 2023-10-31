CC = gcc
AS = as -g
CFLAGS = -Wall -std=c99 -g -D_DEFAULT_SOURCE
LDFLAGS = -no-pie
PROGRAM = chamador

all: $(PROGRAM)

$(PROGRAM): segunda_tentativa.o chamador.o
	$(CC) $(CFLAGS) $(LDFLAGS) -o $(PROGRAM) segunda_tentativa.o chamador.o

segunda_tentativa.o: segunda_tentativa.s
	$(AS) -o segunda_tentativa.o segunda_tentativa.s

chamador.o: chamador.c segunda_tentativa.h
	$(CC) $(CFLAGS) -c -o chamador.o chamador.c

clean:
	rm -f $(PROGRAM) segunda_tentativa.o chamador.o

.PHONY: all clean
