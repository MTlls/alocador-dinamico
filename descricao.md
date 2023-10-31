# (6.1) Segunda tentativa 

Esta parte do trabalho tem como objetivo a implementação de um código em assembly que execute as funcionalidades essenciais de alocação e gerenciamento de memória propostos na Seção 6.1.2 do livro. O intuito é demonstrar um algoritmo para alocação de memória, baseado nas funcionalidades apresentadas por Jonathan Bartlett.

## Funções

A funcionalidade das funções genéricas é a seguinte:

1. **iniciaAlocador()**
   - Executa syscall brk para obter o endereço do topo corrente da heap e o armazena em uma variável global, `topoInicialHeap`.

2. **finalizaAlocador()**
   - Executa syscall brk para restaurar o valor original da heap contido em `topoInicialHeap`.

3. **liberaMem(void\* bloco)**
   - Indica que o bloco está livre.

4. **alocaMem(int num_bytes)**
   - Procura um bloco livre com tamanho maior ou igual à `num_bytes`.
   - Se encontrar, indica que o bloco está ocupado e retorna o endereço inicial do bloco.
   - Se não encontrar, abre espaço para um novo bloco usando a syscall brk, indica que o bloco está ocupado e retorna o endereço inicial do bloco.

## Mecanismo

A questão que não foi abordada é o mecanismo de buscar o próximo bloco livre ou melhor, qual estrutura de dados usar. Jonathan Bartlett apresenta uma alternativa bastante simples para fins ilustrativos, porém ineficiente. A abordagem implementada por Bartlett utiliza uma lista ligada onde o começo e o fim da lista são variáveis globais que aqui chamaremos de `início_heap` e `topo_heap`. Cada nó da lista contém três campos:

- o primeiro indica se o bloco está livre (igual a 0) ou se está ocupado (igual a 1);
- o segundo indica o tamanho do bloco. Também é usado para determinar o endereço do próximo nó da lista.
- o terceiro é o bloco alocado (o primeiro endereço é retornado por `alocaMem()`).