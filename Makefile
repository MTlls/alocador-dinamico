CC = gcc
AS = as -g
CFLAGS = -Wall -std=c99 -g -D_DEFAULT_SOURCE
LDFLAGS = -no-pie
PROGRAM = chamador

all: $(PROGRAM)

$(PROGRAM): gerenciador_memoria.o chamador.o
	$(CC) $(CFLAGS) $(LDFLAGS) -o $(PROGRAM) gerenciador_memoria.o chamador.o

gerenciador_memoria.o: gerenciador_memoria.s
	$(AS) -o gerenciador_memoria.o gerenciador_memoria.s

chamador.o: chamador.c gerenciador_memoria.h
	$(CC) $(CFLAGS) -c -o chamador.o chamador.c

clean:
	rm -f $(PROGRAM) gerenciador_memoria.o chamador.o

.PHONY: all clean
