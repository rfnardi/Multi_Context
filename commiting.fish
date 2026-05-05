#!/bin/fish

gitgo '
feat(memory): implementa ledger imutável polimórfico e watchdog dinâmico

A Fase 42 conclui uma mudança arquitetural massiva no gerenciamento de memória,
transitando de um garbage collection destrutivo para um modelo relacional.

Principais adições:
- Ledger Imutável: Substituída a manipulação de strings por um schema 
  estrito de tags XML `<block>` (rastreando `id`, `status`, `type` e `covers`).
  O histórico agora é "append-only", preservando todos os dados brutos.
- Watchdog Dinâmico: Introduzido um bibliotecário assíncrono em background
  que delega a sumarização de contexto para uma API secundária, evitando 
  travamentos na UI e poupando a janela de contexto do modelo principal.
- RAG Local (`deep_dive`): Agentes de IA agora possuem uma ferramenta nativa 
  para buscar e ler blocos de histórico arquivados sob demanda.
- Motor Visual Nativo: Integrados o `conceallevel=2` e `folds` do Neovim 
  para ocultar o XML e encapsular o texto arquivado sob dobras elegantes 
  na interface (ex: `📦[X linhas arquivadas]`).
- Integração de UI: Adicionado seletor de estratégias e escolha de API de 
  background no Master Command Center (`:ContextControls`).
- Testes: Mocks legados migrados para o novo formato de AST XML, alcançando 
  a marca de 233/233 testes passando.

Refs: Fase 42 -- versão 2.3.1
'
