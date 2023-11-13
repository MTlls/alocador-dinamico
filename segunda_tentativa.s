.section .data
    INICIO_HEAP: .quad 0            # ptr começo da heap
    TOPO_HEAP: .quad 0              # ptr final da heap
    META: .string "################"      # string de metadados
    OCUPADO: .string "+"
    DESOCUPADO: .string "-"
.section .text

.globl iniciaAlocador
.globl finalizaAlocador
.globl liberaMem
.globl alocaMem
.globl getBrk
.globl fusiona_livres
.globl proximo_bloco
.globl imprime_heap

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
        movq (%rsp), %rdi             # arg1 = topo da pilha
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
    jle verifica_livre          # se sim, verifica se esta livre

    pushq %rdi                  # método caller
    movq %rax, %rdi             # mudando os parametros para a chamda de função
    addq $16, %rdi              # começo do bloco
    call proximo_bloco          # %rax = prox_bloco(ptr)
    popq %rdi                   # método caller

    cmpq TOPO_HEAP, %rax        # verifica se já ultrapassou o topo
    jge abre_espaco             # abre espaco para alocação
    jmp loop_first_fit          # se não, verifica novamente para mais um bloco

    verifica_livre:
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

imprime_heap:
    pushq %rbp
    movq %rsp, %rbp
    subq $16, %rsp     

    movq INICIO_HEAP, %r8           # inicio da heap = %r8
    movq %r8, -8(%rbp)              # guarda o inicio da heap
    movq TOPO_HEAP, %rcx
    movq %rcx, -16(%rbp)            # guarda o topo da heap

    heap_loop:
    movq -16(%rbp), %rcx            # topo da heap = %rcx
    cmpq %r8, %rcx                  # cursor != topo da heap
    je fim_heap

    # imprime_gerencial:    
    movq $1, %rax                   # 1 = serviço write
    movq $1, %rdi                   # 1 = stdout
    movq $META, %rsi                # METADADOS to buffer
    movq $16, %rdx                  # 16 = tamanho do buffer
    syscall                         # imprime ################

    movq $1, %rdx                   # 1 = tamanho do buffer
    movq (%r8), %r10                # %r10 = flag de ocupacao
    movq $OCUPADO, %r11             # flag = OCUPADO (+)
    cmpq $1, %r10                   
    je tam_data
    movq $DESOCUPADO, %r11          # flag = OCUPADO (-)

    tam_data:
    movq %r11, %rsi                 # %rsi = endereco da flag 
    addq $8, %r8                    # pula para o tamanho do bloco
    movq (%r8), %r9                 # %r9 = tamanho do bloco
    movq $0, %r12                   # %r12 = 0 (vai ser o contador)

    loop_data:
    cmpq %r9, %r12                  # contador == tamanho do bloco
    je fim_loop
    movq $1, %rdi                   # 1 = stdout
    movq $1, %rax                   # 1 = serviço write
    syscall
    addq $1, %r12                   # contador++
    jmp loop_data

    fim_loop:
    addq $8, %r8
    movq %r8, %rdi
    call proximo_bloco
    movq %rax,%r8                      # %r8 = prox bloco (deveria ser flag de ocupacao)
    jmp heap_loop

    fim_heap:
    popq %rbp
    addq $16, %rsp                  # fecha stack
    ret
    
