#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>
#include "segunda_tentativa.h"

int main(){
    void *ptr1, *ptr2, *ptr3;
    iniciaAlocador();
    // long int tam = 100;

    printf("valor da brk: %p\n", (void *)(getBrk()));
    ptr1 = alocaMem(100*1);
    printf("tam = %d, ptr = %p\n", 100, ptr1);
    
    printf("valor da brk: %p\n", (void *)(getBrk()));
    ptr2 = alocaMem(100*2);
    printf("tam = %d, ptr = %p\n", 200, ptr2);
    
    printf("valor da brk: %p\n", (void *)(getBrk()));
    ptr3 = alocaMem(100*3);
    printf("tam = %d, ptr = %p\n", 300, ptr3);
    
    liberaMem(ptr1);
    liberaMem(ptr2);

    ptr1 = alocaMem(100);
    printf("valor da brk: %p\n", (void *)(getBrk()));

    finalizaAlocador();
    return 0;
}