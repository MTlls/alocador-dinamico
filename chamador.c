#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include "gerenciador_memoria.h"

int main() {
    void *ptr1, *ptr2, *ptr3;
    printf("iniciando alocador\n");
    inicia_alocador();
    printf("heap vazia\n");
    printf("valor da brk: %p\n", (void*)(get_brk()));
    imprime_heap();
    ptr1 = aloca_mem(100 * 1);
    
    printf("\n");
    printf("uma alocada\n");
    // imprime_heap();
    printf("final da primeira alocada\n");
    printf("\n");
    printf("tam = %d, ptr = %p\n", 100, ptr1);

    printf("valor da brk: %p\n", (void*)(get_brk()));
    ptr2 = aloca_mem(100 * 2);
    // imprime_heap();
    printf("\n");
    printf("tam = %d, ptr = %p\n", 200, ptr2);

    printf("valor da brk: %p\n", (void*)(get_brk()));
    ptr3 = aloca_mem(100 * 3);
    // imprime_heap();
    printf("\n");
    printf("tam = %d, ptr = %p\n", 300, ptr3);

    libera_mem(ptr1);
    // imprime_heap();
    printf("\n");
    libera_mem(ptr2);
    // imprime_heap();
    printf("\n");
    ptr1 = aloca_mem(100);
    // imprime_heap();
    printf("\n");
    printf("valor da brk: %p\n", (void*)(get_brk()));
 
    finaliza_alocador();
    return 0;
}