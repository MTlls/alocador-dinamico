#ifndef _GERENCIADOR_MEMORIA_H_
#define _GERENCIADOR_MEMORIA_H_

/**
 * Executa syscall brk para obter o endereço do topo corrente da heap e o armazena em uma variável global, inicioHeap.
*/
extern void iniciaAlocador();

/**
 * Executa syscall brk para restaurar o valor original da heap contido em topoInicialHeap.
*/
extern void finalizaAlocador();

/**
 * Função que libera o bloco de memória e o libera, limpa com sucesso e retorna 1, caso o bloco não esteja na heap, retorna 0.
 * @param bloco o bloco de memória que vai ser liberado.
*/
extern int liberaMem(void* bloco);

/**
 * Procura um bloco livre com tamanho maior ou igual à num_bytes.
 * Se encontrar, indica que o bloco está ocupado e retorna o endereço inicial do bloco.
 * Se não encontrar, abre espaço para um novo bloco usando a syscall brk, indica que o bloco está ocupado e retorna o endereço inicial do bloco.
 * @param num_bytes o número de bytes que será alocado
*/
extern void *alocaMem(long int num_bytes);

/**
 * Função que retorna o valor brk atual
*/
extern void *getBrk();

/**
 * Função que procura todos os nós vizinhos, e se os dois vizinhos forem livres, fusiona os dois.
*/
extern void *fusionaLivres();

/**
 * Função que calcula o começo dos metadados do próximo metadados e o retorna
 * @param bloco endereço de onde está o começo dos metadados
*/
extern void *proximoBloco(void *bloco);

/**
 * Função responsável por imprimir a heap.
 * Cada byte da parte gerencial do nó deve ser impresso com o caractere "#". 
 * O caractere usado para a impressão dos bytes do bloco de cada nó depende se o bloco estiver livre ou ocupado. 
 * Se estiver livre, imprime o caractere -". Se estiver ocupado, imprime o caractere "+".
*/
extern void imprimeHeap();

/**
 * Função que imprime n caracteres c em sequencia
 * @param c caractere que será imprimido
 * @param n vezes que será imprimido
*/
extern void imprime_sequencia(char c, int n);
#endif