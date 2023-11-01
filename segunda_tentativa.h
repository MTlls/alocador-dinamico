#ifndef _SEGUNDA_TENTATIVA_H_
#define _SEGUNDA_TENTATIVA_H_

/**
 * Executa syscall brk para obter o endereço do topo corrente da heap e o armazena em uma variável global, inicioHeap.
*/
void iniciaAlocador();

/**
 * Executa syscall brk para restaurar o valor original da heap contido em topoInicialHeap.
*/
void finalizaAlocador();

/**
 * Indica que o bloco está livre.
 * @param bloco o bloco de memória que vai ser liberado.
*/
void liberaMem(void* bloco);

/**
 * Procura um bloco livre com tamanho maior ou igual à num_bytes.
 * Se encontrar, indica que o bloco está ocupado e retorna o endereço inicial do bloco.
 * Se não encontrar, abre espaço para um novo bloco usando a syscall brk, indica que o bloco está ocupado e retorna o endereço inicial do bloco.
 * @param num_bytes o número de bytes que será alocado
*/
void *alocaMem(long int num_bytes);

/**
 * Função que retorna o valor brk atual
*/
void *getBrk();

/**
 * Função que procura todos os nós vizinhos, e se os dois vizinhos forem livres, fusiona os dois.
*/
void *fusiona_livres();

/**
 * Função que calcula o começo dos metadados do próximo metadados e o retorna
 * @param bloco endereço de onde está o começo dos metadados
*/
void *proximo_bloco(void *bloco);

/**
 * Função responsável por imprimir a heap.
 * Cada byte da parte gerencial do nó deve ser impresso com o caractere "#". 
 * O caractere usado para a impressão dos bytes do bloco de cada nó depende se o bloco estiver livre ou ocupado. 
 * Se estiver livre, imprime o caractere -". Se estiver ocupado, imprime o caractere "+".
*/
void imprime_heap();

/**
 * Função que imprime n caracteres c em sequencia
 * @param c caractere que será imprimido
 * @param n vezes que será imprimido
*/
void imprime_sequencia(char c, int n);
#endif