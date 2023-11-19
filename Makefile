CC = gcc
AS = as -g
CFLAGS = -Wall -std=c99 -g
LDFLAGS = -no-pie
PROGRAM = chamador

all: $(PROGRAM)

$(PROGRAM): gerenciador_memoria.o chamador.o
	$(CC) $(CFLAGS) $(LDFLAGS) -o $(PROGRAM) gerenciador_memoria.o chamador.o

gerenciador_memoria.o: gerenciador_memoria.s
	$(AS) -c gerenciador_memoria.s -o gerenciador_memoria.o

chamador.o: chamador.c gerenciador_memoria.o
	$(CC) $(CFLAGS) -c chamador.c -o chamador.o 

clean:
	rm -f $(PROGRAM) gerenciador_memoria.o chamador.o

.PHONY: all clean
