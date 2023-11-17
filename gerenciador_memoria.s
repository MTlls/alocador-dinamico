#include "gerencia_memoria.h"
.section .data
    INICIO_HEAP: .quad 0            # ptr começo da heap
    TOPO_HEAP: .quad 0              # ptr final da heap
    META: .string "################"      # string de metadados
    OCUPADO: .string "+"
    DESOCUPADO: .string "-"
.section .text

.globl inicia_alocador
.globl finaliza_alocador
.globl libera_mem
.globl aloca_mem
.globl get_brk
.globl fusiona_livres
.globl proximo_bloco
.globl imprime_heap

inicia_alocador:
    pushq %rbp
    movq %rsp, %rbp

    call get_brk                    # pega o valor de brk e coloca em %rax
    movq %rax, INICIO_HEAP          # guarda o valor em INICIO_HEAP
    movq %rax, TOPO_HEAP            # guarda o valor em TOPO_HEAP
    popq %rbp
    ret

finaliza_alocador:
    pushq %rbp                      
    movq %rsp, %rbp

    movq $12, %rax                  # serviço brk
    movq INICIO_HEAP, %rax
    movq %rax,  %rdi          # seta %rdi para o inicio da heap
    syscall                         # seta brk para o inicio da heap
    
    popq %rbp
    ret

get_brk:
    pushq %rbp
    movq %rsp, %rbp

    movq $12, %rax                  # 12 = serviço brk
    movq $0, %rdi                   # arg1 = 0 retorna o endereço de brk
    syscall                         # chamada do serviço brk

    # %rax já está com o valor atual da brk.
    popq %rbp
    ret

libera_mem:
    pushq %rbp
    movq %rsp, %rbp
    
    movq $0, -16(%rdi)              # indica que está livre, valor 0

    call fusiona_livres             # fusiona nós livres.

    popq %rbp
    ret

proximo_bloco:
    pushq %rbp
    movq %rsp, %rbp
     
    addq -8(%rdi), %rdi     # incrementa o endereço com o tamanho do bloco
    movq %rdi, %rax         # salto na memória para o proximo dado

    addq $16, %rax          # começo do proximo bloco
    popq %rbp
    ret

fusiona_livres:
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
    addq $16, %rdi                  # proximo_bloco(cursor + 16)
    call proximo_bloco

    subq $16, %rax                  # proximo_bloco(cursor + 16) -16
    movq %rax, -24(%rbp)            # para as variaveis locais.

    movq -8(%rbp), %rsi             # cursor em %rsi
    movq -16(%rbp), %rdx            # topo_heap em %rdx

    # %rax = prox_bloco
    # %rsi = cursor
    # %rdi = topo_heap_local
    loop_ate_fim_heap1:
        cmpq %rcx, %rsi             # verifica se cursor > ao topo
        jg fim_fusao                # se sim, vai sai do loop

        cmpq $0, (%rdx)             # verifica se está livre 
        jne fim_loop              # se nao, executa o final do loop
        
        cmpq $0, (%rax)             # verifica se o proximo bloco está livre
        jne fim_loop              # se nao, executa o final do loop

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
        movq %rcx, %rax

        jmp fim_loop_heap1

    fim_loop_heap1:
        movq %rax, %rsi         # cursor = prox_bloco

        # prox_bloco = proximo_bloco(prox_bloco + 16) - 16;
        addq $16, %rax
        movq %rax, %rdi
        call proximo_bloco
        subq $16, %rax

        jmp loop_ate_fim_heap1        # volta ao começo do loop

    fim_fusao:
        addq $24, %rsp              # desempilha todas as variaveis locais
        popq %rbp
        ret


aloca_mem:                           # %rdi = num_bytes
    pushq %rbp
    movq %rsp, %rbp

    subq $16, %rsp                   # novo_bloco e bytes = &num_bytes
    movq %rdi, -8(%rbp)              # método caller, empilha-se o endereço.
    movq %rbp, %rdi
    subq $8, %rdi                    # first_fit(bytes)

    call first_fit
    movq %rax, -16(%rbp)             # novo_bloco = first_fit(&num_bytes)

    cmpq $0, %rax                   # verifica se first_fit(&num_bytes)) == 0
    jne fim_if_aloca_mem

    movq -8(%rbp), %rdi
    call abre_espaco
    movq %rax, -16(%rbp)             # novo_bloco = abre_espaco(num_bytes)

    fim_if_aloca_mem:
    #tratamento do valor de num_bytes, que pode ter mudado
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

first_fit:
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

        # prox_bloco = proximo_bloco(bloco_atual) - 16;
        movq %rsi, %rdi             # param1: bloco_atual
        call proximo_bloco
        subq $16, %rax              
        movq %rax, -40(%rbp)        # prox_bloco = %rax

        movq %rsi, -48(%rbp)        # cursor = bloco_atual

        # prox_bloco - (*num_bytes + bloco_atual ) > 32
        movq %rax, %r11             # r11 = prox_bloco
        subq %r8, %r11              # r11 -= num_bytes
        subq %rsi, %r11             # r11 -= bloco_atual
        cmpq $32, %r11
        jle else_ff

        movq -8(%rbp), %rax         # vai para o começo do pŕoximo nó 
        addq (%rax), %rsi           # cursor += *num_bytes

        movq $0, (%rsi)             # proximo nó está livre

        addq $8, %rsi               # indo para o tamanho do nó

        # *((long int *)(cursor)) = prox_bloco - cursor
        movq -40(%rbp), %rax        # prox_bloco em rax
        subq %rdi, %rax             # %rax = prox_bloco - cursor;
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
        call proximo_bloco

        movq %rax, -16(%rbp)        # atualiza o valor de bloco_atual
        jmp loop_ate_fim_heap2      # continue;

    fim_nao_encontrado:
        addq $48, %rsp              # desempilha todas as variaveis locais

        movq $0, %rax               # retorna 0 em %rax
        popq %rbp
        ret

abre_espaco:
    pushq %rbp
    movq %rsp, %rbp 
    
    subq $16, %rsp                  # duas variaveis locais

    movq TOPO_HEAP, %rax
    movq %rax,  -8(%rbp)        # antigo_topo = TOPO_HEAP   
    
    addq -8(%rbp), %rdi             # num_bytes += antigo_topo
    addq $16, %rdi                  # num_bytes += 16

    movq $12, %rax                  # chama brk.
    syscall

    call get_brk
    movq %rax, TOPO_HEAP

    addq $16, -8(%rbp)              # return antigo_topo + 16
    movq -8(%rbp), %rax             # %rax = antigo_topo + 16

    addq $16, %rsp                  # limpa as duas variaveis locais
    popq %rbp
    ret
