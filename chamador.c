#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include "segunda_tentativa.h"

int main() {
    void *ptr1, *ptr2, *ptr3;
    printf("iniciando alocador\n");
    iniciaAlocador();
    printf("heap vazia\n");
    printf("valor da brk: %p\n", (void*)(getBrk()));
    imprime_heap();
    ptr1 = alocaMem(100 * 1);
    /* 
    printf("\n");
    printf("uma alocada\n");
    // imprime_heap();
    printf("final da primeira alocada\n");
    printf("\n");
    printf("tam = %d, ptr = %p\n", 100, ptr1);

    printf("valor da brk: %p\n", (void*)(getBrk()));
    ptr2 = alocaMem(100 * 2);
    // imprime_heap();
    printf("\n");
    printf("tam = %d, ptr = %p\n", 200, ptr2);

    printf("valor da brk: %p\n", (void*)(getBrk()));
    ptr3 = alocaMem(100 * 3);
    // imprime_heap();
    printf("\n");
    printf("tam = %d, ptr = %p\n", 300, ptr3);

    liberaMem(ptr1);
    // imprime_heap();
    printf("\n");
    liberaMem(ptr2);
    // imprime_heap();
    printf("\n");
    ptr1 = alocaMem(100);
    // imprime_heap();
    printf("\n");
    printf("valor da brk: %p\n", (void*)(getBrk()));
 */
    finalizaAlocador();
    return 0;
}