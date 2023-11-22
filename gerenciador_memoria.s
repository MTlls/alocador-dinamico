#include "gerencia_memoria.h"
.section .data
    INICIO_HEAP: .quad 0            # ptr começo da heap
    TOPO_HEAP: .quad 0              # ptr final da heap
    META: .string "################"      # string de metadados
    OCUPADO: .string "+"
    DESOCUPADO: .string "-"
    NEWLINE: .string "\n"
.section .text

.globl iniciaAlocador
.globl finalizaAlocador
.globl liberaMem
.globl alocaMem
.globl getBrk
.globl fusionaLivres
.globl proximoBloco
.globl imprimeMapa
.globl INICIO_HEAP

iniciaAlocador:
    pushq %rbp
    movq %rsp, %rbp

    call getBrk                    # pega o valor de brk e coloca em %rax
    movq %rax, INICIO_HEAP          # guarda o valor em INICIO_HEAP
    movq %rax, TOPO_HEAP            # guarda o valor em TOPO_HEAP
    popq %rbp
    ret

finalizaAlocador:
    pushq %rbp                      
    movq %rsp, %rbp

    movq INICIO_HEAP, %rax
    movq %rax,  %rdi                # seta %rdi para o inicio da heap
    movq $12, %rax                  # serviço brk
    syscall                         # seta brk para o inicio da heap
    
    popq %rbp
    ret

getBrk:
    pushq %rbp
    movq %rsp, %rbp

    movq $12, %rax                  # 12 = serviço brk
    movq $0, %rdi                   # arg1 = 0 retorna o endereço de brk
    syscall                         # chamada do serviço brk

    # %rax já está com o valor atual da brk.
    popq %rbp
    ret

liberaMem:
    pushq %rbp
    movq %rsp, %rbp
    
    cmpq INICIO_HEAP, %rdi          # caso cursor < INICIO_HEAP
    jl bloco_fora_heap

    cmpq TOPO_HEAP, %rdi            # caso cursor > TOPO_HEAP
    jg bloco_fora_heap

    movq $0, -16(%rdi)              # indica que está livre, valor 0

    call fusionaLivres             # fusiona nós livres.
    movq $1, %rax                   # feita a limpeza com sucesso

    bloco_fora_heap:
    movq $0, %rax                   # o bloco nao esta na heap.

    fim_liberaMem:
    popq %rbp
    ret

proximoBloco:
    pushq %rbp
    movq %rsp, %rbp
     
    addq -8(%rdi), %rdi     # incrementa o endereço com o tamanho do bloco
    movq %rdi, %rax         # salto na memória para o proximo dado

    addq $16, %rax          # começo do proximo bloco
    popq %rbp
    ret

fusionaLivres:
    pushq %rbp
    movq %rsp, %rbp

    subq $24, %rsp                  # temos 3 variáveis locais.

    # -8(%rbp) = cursor
    # -16(%rbp) = topo_heap_local
    # -24(%rbp) = prox_bloco

    movq INICIO_HEAP, %rax
    movq %rax,  -8(%rbp)
    movq TOPO_HEAP, %rax
    movq %rax,  -16(%rbp)

    movq -8(%rbp), %rdi             # adiciona o cursor ao argumento
    addq $16, %rdi                  # proximoBloco(cursor + 16)
    call proximoBloco

    subq $16, %rax                  # proximoBloco(cursor + 16) -16
    movq %rax, -24(%rbp)            # para as variaveis locais.

    movq -8(%rbp), %rsi             # cursor em %rsi

    # %rax = prox_bloco
    # %rsi = cursor
    # %rdi = topo_heap_local
    loop_ate_fim_heap1:
        movq -16(%rbp), %rdx        # topo_heap em %rdx
        movq -8(%rbp), %rsi
        cmpq %rdx, %rax             # verifica se prox_bloco > topo
        jge fim_fusao                # se sim, vai sai do loop

        cmpq $0, (%rsi)             # verifica se está livre 
        jne fim_loop_heap1          # se nao, executa o final do loop
        
        cmpq $0, (%rax)             # verifica se o proximo bloco está livre
        jne fim_loop_heap1          # se nao, executa o final do loop

        addq $8, %rsi               # cursor += 8
        addq $8, %rax               # prox_bloco += 8

        # (*(long int *)cursor) = *(long int *)cursor + (*(long int *)prox_bloco) + 16
        movq (%rsi), %rcx           # %rcx = *(long int *)cursor
        addq (%rax), %rcx           # %rcx += *(long int *)prox_bloco
        addq $16, %rcx              # %rcx += 16

        movq %rcx, (%rsi)           # inserido a soma no endereço que aponta %rsi

        # prox_bloco = cursor - 8;
        movq %rsi, %rcx
        subq $8, %rcx
        movq %rcx, -24(%rbp)

    fim_loop_heap1:
        movq -24(%rbp), %rax
        movq %rax, -8(%rbp)               # cursor = prox_bloco

        # prox_bloco = proximoBloco(prox_bloco + 16) - 16;
        addq $16, %rax
        movq %rax, %rdi
        call proximoBloco
        subq $16, %rax

        movq %rax, -24(%rbp)          # voltando para as variaveis locais
        jmp loop_ate_fim_heap1        # volta ao começo do loop

    fim_fusao:
        addq $24, %rsp              # desempilha todas as variaveis locais
        popq %rbp
        ret


alocaMem:                           # %rdi = num_bytes
    pushq %rbp
    movq %rsp, %rbp

    subq $16, %rsp                   # espaço para as variaveis novo_bloco e bytes
    movq INICIO_HEAP, %rsi
    movq TOPO_HEAP, %r8
    cmpq %rsi, %r8                 
    movq %rdi, -8(%rbp)              # empilha-se o tamanho do novo bloco.
    je abrindo

    movq %rbp, %rdi
    # é enviado como parametro o ponteiro para o tamanho do bloco.
    subq $8, %rdi      

    call worstFit
    movq %rax, -16(%rbp)             # novo_bloco = firstFit(&num_bytes)

    cmpq $0, %rax                   # verifica se firstFit(&num_bytes)) == 0
    jne fim_if_alocaMem

    movq -8(%rbp), %rdi

    abrindo: 
    call abreEspaco

    movq %rax, -16(%rbp)             # novo_bloco = abreEspaco(num_bytes)

    fim_if_alocaMem:
    # tratamento do valor de num_bytes, que pode ter mudado
    movq -8(%rbp), %rdi 
    movq %rdi, %rcx

    subq $16, %rax                  # mexeremos nos metadados
    movq $1, (%rax)                 # bloco alocado está ocupado
    addq $8, %rax                   # pula para área de tamanho
    movq %rcx, (%rax)               # escreve o mesmo
    
    addq $8, %rax                   # pula dos metadados para o novo bloco

    addq $16, %rsp
    popq %rbp
    ret

firstFit:
    pushq %rbp
    movq %rsp, %rbp 
    
    # -8(%rbp) = &num_bytes
    # -16(%rbp) = bloco_atual
    # -24(%rbp) = topo_heap_local
    # -32(%rbp) = tamanho
    # -40(%rbp) = prox_bloco
    # -48(%rbp) = cursor

    subq $48, %rsp
    movq %rdi, -8(%rbp)             # &num_bytes

    # bloco_atual = INICIO_HEAP + 16;
    movq INICIO_HEAP, %rax
    movq %rax, -16(%rbp)
    addq $16, -16(%rbp)

    # topo_heap_local = TOPO_HEAP
    movq TOPO_HEAP, %rax
    movq %rax, -24(%rbp)

    movq -24(%rbp), %r9
    # %rsi = bloco_atual
    # %r9 = topo_heap_local
    # %rcx = bloco_atual - 16
    # %rdx = bloco_atual - 8
    loop_ate_fim_heap2:
        # para cada loop atualize o valor.
        movq -16(%rbp), %rsi
    
        movq %rsi, %rcx
        movq %rsi, %rdx
        
        subq $16, %rcx              # %rcx = bloco_atual - 16
        subq $8, %rdx               # %rdx = bloco_atual - 8

        cmpq %r9, %rcx              # compara o topo da heap com o bloco-16
        jge fim_nao_encontrado      # pula para o rotulo caso tenha chegado ao fim da heap

        # verifica se está ocupado
        cmpq $1, (%rcx)             # *((long int *)(bloco_atual - 16))) == 1
        je proximo

        # verifica se cabe num_bytes no bloco atual
        # *num_bytes > *((long int *)(bloco_atual - 8))
        movq -8(%rbp), %rdi
        movq (%rdi), %r8
        cmpq %r8, (%rdx)            
        jle proximo

        movq (%rdx), %r10           # %r10 = *((long int *)(bloco_atual - 8));
        movq %r10, -32(%rbp)        # tamanho = %r10 

        # prox_bloco = proximoBloco(bloco_atual) - 16;
        movq %rsi, %rdi             # param1: bloco_atual
        call proximoBloco
        subq $16, %rax              
        movq %rax, -40(%rbp)        # prox_bloco = %rax

        movq %rsi, -48(%rbp)        # cursor = bloco_atual

        # prox_bloco - (*num_bytes + bloco_atual ) >= 16
        movq %rax, %r11             # r11 = prox_bloco
        subq %r8, %r11              # r11 -= num_bytes
        subq %rsi, %r11             # r11 -= bloco_atual
        cmpq $16, %r11
        jl else_ff

        movq -8(%rbp), %rax         # pega o &num_bytes
        addq (%rax), %rsi           # cursor += *num_bytes

        movq $0, (%rsi)             # proximo nó está livre

        addq $8, %rsi               # indo para o tamanho do nó

        # *((long int *)(cursor)) = prox_bloco - cursor - 8
        movq -40(%rbp), %rax        # prox_bloco em rax
        subq %rsi, %rax             # %rax = prox_bloco - cursor - 8
        subq $8, %rax               
        movq %rax, (%rsi)           # setando o tamanho do bloco

        fim_loop_heap2:
            movq -16(%rbp), %rax    # retorna o endereço do bloco alocado.
            addq $48, %rsp          # desempilha todas as variaveis locais
            
            popq %rbp
            ret
            
        else_ff:
            movq -8(%rbp), %rdi
            movq %r10, (%rdi)       # *num_bytes = tamanho
            jmp fim_loop_heap2      # vai para o fim do laço
    proximo:
        movq %rsi, %rdi             # prepara o argumento
        call proximoBloco

        movq %rax, -16(%rbp)        # atualiza o valor de bloco_atual
        jmp loop_ate_fim_heap2      # continue;

    fim_nao_encontrado:
        addq $48, %rsp              # desempilha todas as variaveis locais

        movq $0, %rax               # retorna 0 em %rax
        popq %rbp
        ret

abreEspaco:
    pushq %rbp
    movq %rsp, %rbp 
    
    subq $16, %rsp                  # duas variaveis locais

    movq TOPO_HEAP, %rax
    movq %rax,  -8(%rbp)        # antigo_topo = TOPO_HEAP   
    
    addq -8(%rbp), %rdi             # num_bytes += antigo_topo
    addq $16, %rdi                  # num_bytes += 16

    movq $12, %rax                  # chama brk.
    syscall

    call getBrk
    movq %rax, TOPO_HEAP

    addq $16, -8(%rbp)              # return antigo_topo + 16
    movq -8(%rbp), %rax             # %rax = antigo_topo + 16

    addq $16, %rsp                  # limpa as duas variaveis locais
    popq %rbp
    ret

imprimeMapa:
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
    call proximoBloco
    subq $16, %rax                  # %rax contem o endereco da prox area de dados
    movq %rax, %r8                  # atualiza o cursor
    jmp heap_loop

    fim_heap:
    movq $1, %rax                   # 1 = serviço write
    movq $1, %rdi                   # 1 = stdout
    movq $1, %rdx                   # 1 = tamanho do buffer
    movq $NEWLINE, %rsi             # \n to buffer
    syscall
    addq $16, %rsp                  # fecha stack
    popq %rbp
    ret
    
worstFit:
    pushq %rbp
    movq %rsp, %rbp

    subq $32, %rsp                   # variavel local

    # -8(%rbp) = ponteiro num_bytes
    # -16(%rbp) = bloco_atual (navegaremos por ele)
    # -24(%rbp) = topo_heap
    # -32(%rbp) = tam_max 
    movq %rdi, -8(%rbp)
    movq INICIO_HEAP, %rax
    movq %rax, -16(%rbp)
    movq TOPO_HEAP, %rax
    movq %rax, -24(%rbp)
    movq $0, -32(%rbp)

    loop_ate_fim_heap3:
        movq -16(%rbp), %rcx         # bloco_atual = rcx
        movq -24(%rbp), %rsi         # topo_heap = rcx
        # caso ja tenha passado do fim da heap
        cmpq %rcx, %rsi
        jle fim_loop_heap3

        cmpq $1, (%rcx)              # bloco livre?
        je salta_prox

        # tam_max = %r8
        movq -32(%rbp), %r8
        # verifica o ponteiro de tam_max para naao haver acesso indevido de memoria
        cmpq $0, %r8
        je verifica_max

        # caso contrario pegamos o valor do ponteiro de %r8
        movq (%r8), %r8

        verifica_max:
        # verifica se o tamanho do bloco atual > tam_max
        cmpq %r8, 8(%rcx)
        jl salta_prox

        # se o bloco for maior que o tam_max, altera tam_max, recebendo o ponteiro do bloco
        movq %rcx, %r8
        addq $8, %r8
        movq %r8, -32(%rbp)

        jmp salta_prox

    salta_prox:
        movq -16(%rbp), %rdi
        addq $16, %rdi

        # chama proximo bloco e diminui 16, para começar nos metadados
        call proximoBloco

        subq $16, %rax
        movq %rax, -16(%rbp)
        jmp loop_ate_fim_heap3
    fim_loop_heap3:
        # valor dos ponteiros de tamanho: num_bytes e tam_max
        movq -8(%rbp), %rax
        movq (%rax), %rax                   # rax = valor de *num_bytes
        movq -32(%rbp), %rsi                # rsi = endereco do tamanho do maior bloco

        # verifica se nao eh 0
        cmpq $0, %rsi
        je nao_achou_maior

        movq (%rsi), %r8                    # rsi = valor do maior bloco
        cmpq %r8, %rax
        jg nao_achou_maior
        
        # se cabe num_bytes no bloco, realiza as seguintes tarefas:
        # verifica se o espaco para o bloco fragmentado eh > 16
        # caso contrario, apenas seta o valor de num_bytes = tam_max
        # caso seja >16, pula para o metadado do bloco fragmentado e seta seus metadados.
        # retorna o endereco do novo bloco alocado.
        
        # o tamanho do bloco fragmentado eh:
        # tamanho do maior bloco - tamanho que se deseja alocar

        # *tam_max -= *num_bytes
        subq %rax, %r8

        cmpq $16, %r8
        jl nao_fragmenta

        # pula para o bloco fragmentado
        addq %rax, %rsi
        addq $8, %rsi   
        movq $0, (%rsi)                     # bloco nao ocupado
        subq $16, %r8                       # tamanho do bloco 
        movq %r8, 8(%rsi)                   # seta o tamanho do bloco fragmentado
        subq %rax, %rsi                     # volta ao bloco que sera alocado
        movq %rsi, %rax
        jmp fim_wf

    nao_fragmenta:
        # caso o valor do bloco fragmentado seja < 0, seta num_bytes apenas 
        movq -8(%rbp), %rdi
        addq %rax, %rsi                     # restaura o valor do tamanho do maior bloco.
        movq %rsi, (%rdi)                   # *num_bytes = tamanho

        jmp fim_wf                          # vai para o fim da funcao

    nao_achou_maior:
        movq $0, %rax
    fim_wf:
    addq $32, %rsp                          # variavel local
    popq %rbp
    ret
