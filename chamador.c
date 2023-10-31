#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>
#include "segunda_tentativa.h"

int main(){
    void *ptr1, *ptr2;
    iniciaAlocador();
    long int tam = 100;
    printf("valor da brk: %p\n", (void *)(getBrk()));
    ptr1 = alocaMem(100);
    printf("tam = %ld, ptr = %p\n", tam, ptr1);
    printf("valor da brk: %p\n", (void *)(getBrk()));
    ptr2 = alocaMem(200);
    printf("tam = %d, ptr = %p\n", 200, ptr2);
    printf("valor da brk: %p\n", (void *)(getBrk()));
    liberaMem(ptr1);

    ptr1 = alocaMem(100);
    printf("tam = %d, ptr = %p\n", 100, ptr1);
    printf("valor da brk: %p\n", (void *)(getBrk()));
    ptr1 = finalizaAlocador();
    printf("valor da brk: %p\n", (void *)(getBrk()));
    return 0;
}