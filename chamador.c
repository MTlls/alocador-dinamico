#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include "gerenciador_memoria.h"

int main() {
    void *ptr1, *ptr2, *ptr3;
    iniciaAlocador();
    printf("heap vazia\n");
    printf("valor da brk: %p\n", (void*)(getBrk()));
    imprimeHeap();

    ptr1 = alocaMem(100 * 1);
    imprimeHeap();
    printf("tam = %d, ptr = %p\n", 100, ptr1);

    printf("valor da brk: %p\n", (void*)(getBrk()));
    ptr2 = alocaMem(100 * 2);
    imprimeHeap();
    printf("tam = %d, ptr = %p\n", 200, ptr2);

    printf("valor da brk: %p\n", (void*)(getBrk()));
    ptr3 = alocaMem(100 * 3);
    imprimeHeap();
    printf("tam = %d, ptr = %p\n", 300, ptr3);

    liberaMem(ptr1);
    imprimeHeap();

    liberaMem(ptr2);
    imprimeHeap();

    ptr1 = alocaMem(100);
    printf("aloquei 100 de novo\n");
    imprimeHeap();
    printf("valor da brk: %p\n", (void*)(getBrk()));
 
    finalizaAlocador();
    return 0;
}