.section .data
    INICIO_HEAP: .quad 0            # ptr começo da heap
    TOPO_HEAP: .quad 0              # ptr final da heap
.section .text

.globl iniciaAlocador
.globl finalizaAlocador
.globl liberaMem
.globl alocaMem
.globl getBrk

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
        jne loop_busca              # vai procurar um bloco livre.
    
    abre_espaco:
        pushq %rdi                  # empilha o tamanho do bloco
        movq $12, %rax              # 12 = serviço brk
        addq $16, %rdi              # num_bytes += 2 long ints
        addq TOPO_HEAP, %rdi        # TOPO_HEAP += num_bytes
        movq %rdi, TOPO_HEAP        # endereço novo do topo da heap
        
        # OBS: como por padrão o registrador %rdi é temporário, achamos melhor empilhar o valor do que confiar no serviço brk 

        syscall                     # chama brk

        popq %rdi                   # desempilha o tamanho do bloco em %rdi
        popq %rax                   # desempilha o antigo topo da pilha em %rax

        movq $1, (%rax)             # indicando que está ocupado
        addq $8, %rax               # pula para o espaço de tamanho do bloco
        movq %rdi, (%rax)           # tamanho da area alocada indicada

        addq $8, %rax               # ponteiro do bloco
        popq %rbp
        ret                         # ret %rax

    loop_busca:                     # endereço do bloco atual = %rax
        movq 8(%rax), %rsi          # espaço do bloco atual = %rsi
        cmpq %rsi, %rdi             # verifica se num_bytes <= %rsi
        jg proximo_bloco            # se num_bytes > bloco, vai para o proximo

        cmpq $1, (%rax)             # verifica se a area está livre
        jne achou_bloco             # se estiver, aloca-se o bloco
        proximo_bloco:
            addq $16, %rsi          # espaço ocupado do bloco atual + metadados
            addq %rsi, %rax         # salto na memória para o proximo dado
            cmpq TOPO_HEAP, %rax    # verifica se já ultrapassou o topo
            jge abre_espaco         # abre espaco para alocação
            jmp loop_busca          # verifica novamente para mais um bloco
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
