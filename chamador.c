#include <stdio.h>
#include "gerenciador_memoria.h"

int main (long int argc, char** argv) {
    void *a,*b,*c,*d,*e;

    iniciaAlocador(); 
    printf("iniciou\n");
    imprimeMapa();
    // 0) estado inicial

    a=(void *) alocaMem(100);
    b=(void *) alocaMem(130);
    c=(void *) alocaMem(120);
    d=(void *) alocaMem(110);
    // 1) Espero ver quatro segmentos ocupados
    liberaMem(b);
    liberaMem(d);
    fprintf(stdout, "Espero ver quatro segmentos ocupados\n");
    imprimeMapa(); 
    // 2) Espero ver quatro segmentos alternando
    //    ocupados e livres
    fprintf(stdout, "Espero ver quatro segmentos alternando entre ocupados e livres\n");
    
    b=(void *) alocaMem(50);
    fprintf(stdout, "segundo bloco tem 50 e terceiro bloco deve ter 64\n");
    imprimeMapa();
    
    d=(void *) alocaMem(90);
    fprintf(stdout, "penultimo bloco tem 90 e terceiro bloco deve ter 4\n");
    imprimeMapa();
    
    e=(void *) alocaMem(40);
    fprintf(stdout, "segundo bloco tem 40 e terceiro bloco deve ter 8.\n");
    imprimeMapa();
    
    // 3) Deduzam
    fprintf(stdout, "C LIBERADO, quarto bloco com 144 livres\n");
    liberaMem(c);
    imprimeMapa(); 
    
    fprintf(stdout, "A LIBERADO, primeiro bloco com 166 livres.\n");
    liberaMem(a);
    imprimeMapa();
    
    fprintf(stdout, "B LIBERADO, 166 livres no primeiro bloco\n");
    liberaMem(b);
    imprimeMapa();
    
    fprintf(stdout, "D LIBERADO, 270 livres no ultimo bloco \n");
    liberaMem(d);
    imprimeMapa();
    
    fprintf(stdout, "E LIBERADO, 508 liberados, um bloco.\n");
    liberaMem(e);
    imprimeMapa();
    // 4) volta ao estado inicial
    finalizaAlocador();
}