.section .data
    INICIO_HEAP: .quad 0            # ptr começo da heap
    TOPO_HEAP: .quad 0              # ptr final da heap
.section .text

.globl iniciaAlocador
.globl finalizaAlocador
.globl liberaMem
.globl alocaMem
.globl getBrk
.globl fusiona_livres
.globl proximo_bloco

iniciaAlocador:
    pushq %rbp
    movq %rsp, %rbp

    movq $12, %rax                  # 12 = serviço brk
    movq $0, %rdi                   # arg1 = 0 retorna o endereço de brk
    syscall                         # chamada do serviço brk
    movq %rax, INICIO_HEAP          # guarda o valor em INICIO_HEAP
    movq %rax, TOPO_HEAP            # guarda o valor em TOPO_HEAP
    popq %rbp
    ret

alocaMem:                           # %rdi = num_bytes
    pushq %rbp
    movq %rsp, %rbp
    
    movq INICIO_HEAP, %rax
    movq TOPO_HEAP, %rsi
    pushq %rsi                      # empilha o topo da pilha para uso futuro
    
    verifica_fim:
        cmpq %rax, %rsi             # compara o inicio com o fim da heap
        jne loop_first_fit          # vai procurar um bloco livre.
    
    abre_espaco:
        pushq %rdi                  # empilha o tamanho do bloco
        movq $12, %rax              # 12 = serviço brk
        addq $16, %rdi              # num_bytes += 2 long ints
        addq TOPO_HEAP, %rdi        # TOPO_HEAP += num_bytes
        movq %rdi, TOPO_HEAP        # endereço novo do topo da heap
        
        # OBS: como por padrão o registrador %rdi é temporário, 
        # achamos melhor empilhar o valor do que confiar no serviço brk 

        syscall                     # chama brk

        popq %rdi                   # desempilha o tamanho do bloco em %rdi
        popq %rax                   # desempilha o antigo topo da pilha em %rax

        movq $1, (%rax)             # indicando que está ocupado
        addq $8, %rax               # pula para o espaço de tamanho do bloco
        movq %rdi, (%rax)           # tamanho da area alocada indicada

        addq $8, %rax               # ponteiro do bloco
        popq %rbp
        ret                         # ret %rax

loop_first_fit:                 # endereço do bloco atual = %rax
    movq 8(%rax), %rsi          # espaço do bloco atual = %rsi
    cmpq %rsi, %rdi             # verifica se num_bytes <= %rsi
    jle achou_bloco             # se sim, achou o bloco

    pushq %rdi                  # método caller
    movq %rax, %rdi             # mudando os parametros para a chamda de função
    addq $16, %rdi              # começo do bloco
    call proximo_bloco          # %rax = prox_bloco(ptr)
    popq %rdi                   # método caller

    cmpq TOPO_HEAP, %rax        # verifica se já ultrapassou o topo
    jge abre_espaco             # abre espaco para alocação
    jmp loop_first_fit          # se não, verifica novamente para mais um bloco

    cmpq $1, (%rax)             # verifica se a area está livre
    jne achou_bloco             # se estiver, aloca-se o bloco
    movq %rax, %rdi
    achou_bloco:
        movq $1, (%rax)             # O bloco que começa em %rax está ocupado.
        addq $16, %rax              # %rax é deslocado dos metadados
        popq %rsi                   # desempilha auxiliares.
        popq %rbp
        ret                         # ret %rax

finalizaAlocador:
    pushq %rbp                      
    movq %rsp, %rbp
    movq $12, %rax                  # serviço brk
    movq INICIO_HEAP, %rdi          # seta %rdi para o inicio da heap
    syscall                         # seta brk para o inicio da heap
    popq %rbp
    ret

liberaMem:                          # liberaMem(void* bloco)
    pushq %rbp
    movq %rsp, %rbp
    
    movq $0, -16(%rdi)              # indica que está livre, valor 0
    call fusiona_livres
    popq %rbp
    ret

getBrk:
    pushq %rbp
    movq %rsp, %rbp
    movq $12, %rax                  # serviço brk
    movq $0, %rdi                   # queremos o valor de brk
    syscall
    popq %rbp
    ret

proximo_bloco:
    pushq %rbp
    movq %rsp, %rbp
     
    addq -8(%rdi), %rdi     # incrementa o endereço com o tamanho do bloco
    movq %rdi, %rax         # salto na memória para o proximo dado

    popq %rbp
    ret

fusiona_livres:
    pushq %rbp
    movq %rsp, %rbp

    movq INICIO_HEAP, %rdi          # inicio da heap = %rax
    movq TOPO_HEAP, %rsi            # topo da heap = %rdi

    loop_ate_fim_heap:
        cmpq %rsi, %rdi             # verifica se é igual ao topo
        je fim_funcao               # se sim, vai sai do loop

        cmpq $1, (%rdi)             # verifica se está livre 
        je final_loop               # se nao, executa o final do loop

        pushq %rdi                  # método caller
        addq $16, %rdi              # começo do bloco
        call proximo_bloco          # aux = prox_bloco(ptr)
        popq %rdi                   # método caller

        cmpq %rsi, %rax             # verifica se é menor ou igual ao topo
        je fim_funcao               # se sim, vai sai do loop

        cmpq $1, (%rax)             # verifica se está livre
        je final_loop               # se nao, executa o final do loop

        # temos dois blocos livres, %rax e %rdi são o aux e ptr, o começo de cada metadado, aqui é feita a fusão

        movq 8(%rax), %rdx          # aqui %rdx está com o tamanho do bloco2
        addq $16, %rdx              # %rdx = tam do bloco2 e os seus metadados
        addq %rdx, 8(%rdi)          # tamanho do bloco1 de ptr += %rdx
        jmp final_loop              # continua para os proximos blocos

    loop_busca_livre:                   # busca nós consecutivos livres na heap
        cmpq $0, %rsi                   # bloco livre?
        jne loop_busca_livre            # se não, procuramos com o proximo

    final_loop:
        addq $16, %rdi              # começo do bloco
        call proximo_bloco          # prox_bloco(ptr)
        movq %rax, %rdi             # equivalente a ptr = prox_bloco(ptr)
        jmp loop_ate_fim_heap        # volta ao começo do loop

    fim_funcao:
    popq %rbp
    ret

-- imprime_heap:
--     pushq %rbp
--     movq %rsp, %rbp

--     movq INICIO_HEAP, %rax          # começo da heap em %rax
--     movq TOPO_HEAP, %rdx            # topo da heap em %rdx

--     movq $16, %rcx
--     movq $35, %rdi
--     loop_metadados:
--         cmpq $0, %rcx
--         je loop_impressao           # sai do primeiro loop para o proximo
--         call imprime_caractere
--         jmp loop_metadados
        
--     loop_impressao:
--         cmpq %rax, %rdx             # compara o valor atual da heap com o topo
--         je saida_laco
        
--         movq 8(%rax), %rsi          # tamanho do bloco
--         movq (%rax), %rdi           # condição do bloco

--         jmp imprime_sequencia       # imprime_sequencia(%rdi, %rsi)

--         addq $1, %rax
--         jmp loop_impressao          # imprime o proximo valor
    
--     saida_laco:
--     popq %rbp
--     ret

-- imprime_caractere:
--     pushq %rbp
--     movq %rsp, %rbp
    
--     movq $1, %rax                   # servico write
--     movq %rdi, %rsi                 # caractere odo buffer
--     movq %rax, %rdi                 # descritor (stdout)
--     movq $rdi, %rdx                 # tamanho do buffer
--     syscall

--     popq %rbp
--     ret

-- imprime_sequencia:
--     pushq %rbp
--     movq %rsp, %rbp
    
--     cmpq $1, %rdi                   # verifica a condição do bloco
--     jne livre                       # jmp para o rotulo   
    
--     movq $43, %rsi                  # ASCII de "+"

--     livre:
--         movq $45, %rsi              # ASCII de "-"

--     popq %rbp
--     ret
