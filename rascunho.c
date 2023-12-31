extern void *INICIO_HEAP;
extern void *TOPO_HEAP;

/**
 * Executa syscall brk para obter o endereço do topo corrente da heap e o
 * armazena em uma variável global, inicioHeap.
 */
void iniciaAlocador() {
    void *atualBrk = getBrk();

    INICIO_HEAP = atualBrk;
    TOPO_HEAP = atualBrk;
}

/**
 * Executa syscall brk para restaurar o valor original da heap contido em
 * topoInicialHeap.
 */
void finalizaAlocador() {
    brk(INICIO_HEAP);
}

/**
 * Função que retorna o valor brk atual, facilita pois não precisamos assim nos
 * preocupar com como vai ser salvo os registradores, devido ao registro de
 * ativação.
 */
void *getBrk() {
    return brk(0);
}

/**
 * Indica que o bloco está livre.
 * @param bloco o bloco de memória que vai ser liberado.
 */
int liberaMem(void *bloco) {
    void *cursor = bloco;

    if (cursor < INICIO_HEAP || cursor > TOPO_HEAP)
        return 0;

    // seta para zero o metadado que diz se está livre ou não.
    *((long int *)(cursor - 16)) = 0;

    // procura nós livres.
    fusionaLivres();

    return 1;
}

/**
 * Função que calcula o começo dos metadados do próximo metadados e o retorna
 * @param bloco endereço de onde está o começo dos metadados
 */
void *proximoBloco(void *bloco) {
    void *bloco_atual;
    long int tamanho;

    // aponta para o tamanho do bloco
    bloco_atual = bloco - 8;

    // pega o tamanho do bloco
    tamanho = *((long int *)bloco_atual);

    // o proximo bloco é o bloco atual + tamanho + 8
    bloco_atual += tamanho + 8;

    return bloco_atual;
}

/**
 * Função que procura todos os nós vizinhos, e se os dois vizinhos forem livres,
 * fusiona os dois.
 */
void fusionaLivres() {
    void *cursor, *topo_heap_local;
    void *prox_bloco;

    cursor = INICIO_HEAP;
    topo_heap_local = TOPO_HEAP;

    // -16 pois precisamos dos metadados
    prox_bloco = proximoBloco(cursor + 16) - 16;

    while (prox_bloco < topo_heap_local) {
        // caso os dois estejam livres...
        if ((*(long int *)cursor == 0) && (*(long int *)prox_bloco == 0)) {
            // cursor e prox_bloco vai para area de tamanho
            cursor += 8;
            prox_bloco += 8;

            // tamanho dos dois + os metadados do prox_bloco.
            (*(long int *)cursor) =
                *(long int *)cursor + (*(long int *)prox_bloco) + 16;

            // volta o proximo bloco para o começo do novo bloco fusionado
            prox_bloco = cursor - 8;
        }

        cursor = prox_bloco;
        prox_bloco = proximoBloco(prox_bloco + 16) - 16;
    }

    return;
}

/**
 * Procura um bloco livre com tamanho maior ou igual à num_bytes.
 * Se encontrar, indica que o bloco está ocupado e retorna o endereço inicial do
 * bloco. Se não encontrar, abre espaço para um novo bloco usando a syscall brk,
 * indica que o bloco está ocupado e retorna o endereço inicial do bloco.
 * @param num_bytes o número de bytes que será alocado
 */
void *alocaMem(long int num_bytes) {
    void *novo_bloco;
    long int *bytes;

    bytes = &num_bytes;
    // caso nao consiga achar algum que caiba, abre espaço.
    if ((novo_bloco = firstFit(bytes)) == 0)
        novo_bloco = abreEspaco(*bytes);

    // mexeremos nos metadados
    novo_bloco -= 16;
    // bloco alocado está ocupado
    *((long int *)novo_bloco) = 1;

    // pula para área de tamanho e escreve o mesmo
    novo_bloco += 8;
    *((long int *)novo_bloco) = *bytes;

    // pula dos metadados para o novo bloco
    novo_bloco += 8;

    return novo_bloco;
}

/**
 * Função que procura algum nó dentro da heap que caiba num_bytes.
 * Retorna ou o endereço do novo bloco alocado ou 0 caso contrario
 */
int firstFit(long int *num_bytes) {
    void *bloco_atual, *prox_bloco, *cursor;
    void *topo_heap_local = TOPO_HEAP;
    long int tamanho;

    // +16 pois pula os metadados
    bloco_atual = INICIO_HEAP + 16;

    // -16 pois estamos deslocando o tamanho dos metadados
    while (bloco_atual - 16 < topo_heap_local) {
        // verifica se está ocupado e se cabe num_bytes em bloco_atual
        if ((*((long int *)(bloco_atual - 16))) == 1 ||
            (*num_bytes > *((long int *)(bloco_atual - 8)))) {
            bloco_atual = proximoBloco(bloco_atual);

            // volta ao rótulo do loop
            continue;
        }

        // espaço livre e cabe o bloco dentro do nó!

        // Isso é o tamanho do espaço livre
        tamanho = *((long int *)(bloco_atual - 8));

        prox_bloco = proximoBloco(bloco_atual) - 16;

        // usameros esse ponteiro quando quisermos "navegar" na memória,
        // primeiramente está apontando para o começo dos metadados do bloco.
        cursor = bloco_atual;

        // verifica se num_bytes + bloco_atual - proximoBloco >= 16
        // se sim, quer dizer que não cabe outro nó entre o bloco atual e o
        // proximo.
        if (prox_bloco - (*num_bytes + bloco_atual) > 32) {
            // vai para o começo do pŕoximo nó
            cursor += *num_bytes;

            // proximo nó está livre.
            *((long int *)(cursor)) = 0;

            cursor += 8;
            // tamanho do nó indicado.
            *((long int *)(cursor)) = prox_bloco - cursor - 8;

        } else {
            // caso não caiba, apenas mudamos o num_bytes para o valor da área
            // livre.
            *num_bytes = tamanho;
            return 0;
        }

        // retorna 1 caso conseguiu alocar
        return 1;
    }

    // nao encontrou
    return 0;
}

/**
 * Função auxiliar que abre espaço para um nó na alocação de memória.
 * Retorna o começo dos metadados do novo nó pré alocado
 * @param num_bytes o número de bytes que será alocado
 */
void *abreEspaco(long int num_bytes) {
    long int antigo_topo = TOPO_HEAP;
    long int novo_topo;

    novo_topo = antigo_topo + num_bytes + 16;

    // atualiza o novo topo da heap
    brk(novo_topo);

    TOPO_HEAP = getBrk();

    return antigo_topo + 16;
}

/**
 * Função responsável por imprimir a heap.
 * Cada byte da parte gerencial do nó deve ser impresso com o caractere "#".
 * O caractere usado para a impressão dos bytes do bloco de cada nó depende se o
 * bloco estiver livre ou ocupado. Se estiver livre, imprime o caractere -". Se
 * estiver ocupado, imprime o caractere "+".
 */
void imprimeMapa();

/**
 * Função que imprime n caracteres c em sequencia
 * @param c caractere que será imprimido
 * @param n vezes que será imprimido
 */
void imprime_sequencia(char c, int n);

/**
 * Função que realiza o worst fit.
 */
void worstFit(long int *num_bytes) {
    void *bloco_atual, *cursor;
    void *topo_heap_local = TOPO_HEAP;
    long int *tamanho_max;



    // +8 pois só queremos o ponteiro para o tamanho dos metadados
    bloco_atual = INICIO_HEAP + 8;

    // Isso é o endereço do tamanho do espaço livre
    tamanho_max = (bloco_atual);

	topo_heap_local = TOPO_HEAP;

    // -8 pois estamos deslocando apenas o metadado de tamanho
    while (bloco_atual - 8 < topo_heap_local) {
		bloco_atual = proximoBloco(bloco_atual + 8);
        
		// verifica se está ocupado
        if ((*((long int *)(bloco_atual - 8))) == 1) {
            continue;
        } else if (*tamanho_max < *((long int *)(bloco_atual - 8))) {
            tamanho_max = bloco_atual;
            // volta ao rótulo do loop
            continue;
        }
    }

    // tamanho_max tem o ponteiro para o maior bloco
    // é verificado se tamanho_max é menor que o tamanho que se é desejado
    // alocar caso sim, retorna 0 (nao conseguiu alocar)
    if (*tamanho_max < *num_bytes) {
        return 0;
    }

	// guardamos o endereço do maior bloco para facilitar
	cursor = tamanho_max + 8;

    // verifica se o tam_maior_bloco - num_bytes >= 16
    // se sim, quer dizer que cabe outro nó entre o bloco atual e o proximo.
    if (*((long int *)tamanho_max) - (*num_bytes) >= 16) {
        // vai para o começo do proximo nó
        cursor += *num_bytes;

        // proximo nó está livre.
        *((long int *)(cursor)) = 0;

        cursor += 8;

        // tamanho do nó indicado.
        *((long int *)(cursor)) = *tamanho_max - *num_bytes - 16;

		return 1;
    } else {
        // caso não caiba, apenas mudamos o num_bytes para o valor da área
        // livre.
        *num_bytes = *tamanho_max;
        return 0;
    }

    // nao encontrou
    return 0;
}

void imprimeMapa() {
    charcursor = (char )INICIO_HEAP;
    chartopo = (char )TOPO_HEAP;

    while (cursor != topo) {
        // imprime_gerencial
        write(1, META, 16);  // 1 = stdout
        putchar('\n');

        char flag = (cursor == 1) ? OCUPADO : DESOCUPADO;
        char enderecoFlag = &flag;

        cursor += 8;  // Pula para o tamanho do bloco
        size_t tamanhoBloco =((size_t *)cursor);

        for (size_t contador = 0; contador < tamanhoBloco; contador++) {
            // Imprime os dados do bloco
            write(1, enderecoFlag, 1);  // 1 = stdout
        }

        cursor = proximoBloco(cursor);
    }

    // Imprime nova linha ao final
    write(1, NEWLINE, 1);  // 1 = stdout
}