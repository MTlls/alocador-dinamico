#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include "gerenciador_memoria.h"

int main() {
    void *ptr1, *ptr2, *ptr3;
    iniciaAlocador();
    printf("heap vazia\n");
    printf("valor da brk: %p\n", (void*)(getBrk()));
    imprimeMapa();

    ptr1 = alocaMem(100 * 1);
    imprimeMapa();
    printf("tam = %d, ptr = %p\n", 100, ptr1);

    printf("valor da brk: %p\n", (void*)(getBrk()));
    ptr2 = alocaMem(100 * 2);
    imprimeMapa();
    printf("tam = %d, ptr = %p\n", 200, ptr2);

    printf("valor da brk: %p\n", (void*)(getBrk()));
    ptr3 = alocaMem(100 * 3);
    imprimeMapa();
    printf("tam = %d, ptr = %p\n", 300, ptr3);

    liberaMem(ptr1);
    imprimeMapa();

    liberaMem(ptr2);
    imprimeMapa();

    ptr1 = alocaMem(100);
    printf("aloquei 100 de novo\n");
    imprimeMapa();
    printf("valor da brk: %p\n", (void*)(getBrk()));
 
    finalizaAlocador();
    return 0;
}