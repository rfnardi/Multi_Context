#!/bin/fish

gitgo "
test(core): estabiliza suíte (100% determinística) e reforça encapsulamento AST (v2.4.3)

Esta atualização resolve definitivamente as flutuações na quantidade de testes
e vazamentos de estado global, além de blindar a estrutura de memória do chat
(AST) contra ambiguidades de texto livre.

Detalhes técnicos:
- **Async Barrier (Queue Draining)**: Interceptação global de `vim.schedule` e 
  `vim.defer_fn` no `minimal_init.lua`. Garante que todas as promises em background
  sejam resolvidas antes do teardown dos testes, eliminando crashes silenciosos no Plenary.
- **Restore-Before-Assert**: Implementado o padrão seguro de restauração de mocks
  (`vim.fn.system`, `vim.fn.executable`) antes de `asserts`, evitando que uma falha 
  corrompa o kernel de testes subsequentes (Global State Bleeding).
- **Escopo de Testes**: Realocação de blocos `it()` órfãos para dentro de seus 
  respectivos `describe()`, garantindo que o Plenary carregue exatamente 281 testes 
  de forma totalmente determinística.
- **Idempotent AST Encapsulation**: Refatoração do `react_orchestrator` e `session.lua`
  para abandonar o parser híbrido. Agora todo input de usuário, respostas da IA 
  e resultados de ferramentas são envelopados de forma estrita e idempotente em 
  tags `<block>`, erradicando bugs de *Double-Wrapping*.
- **Docs**: Atualização do `CONTEXT.md` para a versão 2.4.3 documentando a nova
  arquitetura de testes e isolamento de AST.
"

