#!/bin/fish

gitgo "feat(core): fase 44 - Load Balancer Cognitivo e Indexação Semântica Ativa

Nesta fase evoluímos a injeção de contexto de um simples 'copiar e colar' 
para um motor robusto de indexação RAG em tempo real distribuída.

Detalhes da implementação:
- Motor de Injetores Tabulares (`injectors.lua`): Injetores agora retornam 
  arrays estruturados (`title`, `content`), que são encapsulados em blocos 
  XML `<block>` individuais.
- Zero-Freeze UX & Popcorn Patching: Arquivos pesados (como `project_dump`) 
  são injetados instantaneamente com um `<abstract>` provisório (ex: 
  'Indexando: src/main.lua...'), eliminando travamentos de UI. Quando as 
  APIs retornam, o texto é atualizado assincronamente.
- Load Balancer Cognitivo (`dynamic_watchdog.lua`): Nova função 
  `dispatch_parallel_jit_tasks` que adota um algoritmo Round-Robin para 
  distribuir requisições pesadas entre um pool de APIs de background, 
  evitando rate limits.
- UI do Command Center (`controls_view.lua`): Adicionado o toggle 
  `[ ON / OFF ] Background Pool` para o usuário gerenciar o esquadrão 
  de APIs de indexação.
- Refatoração do `project_dump.lua`: Adaptado para a nova engine tabular.
- Documentação (`README.md`, `CONTEXT.md`): Atualizada para v2.4 com 
  exemplos das novas capabilities.
- Cobertura de Testes: Atingimos a marca de 257 testes unitários e de 
  integração isolados via Plenary (100% Passing)."
