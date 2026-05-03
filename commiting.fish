#!/bin/fish

gitgo '
refactor(ui): alinha Master Command Center com Ontologia Semântica MCP (Fase 41)

Esta grande refatoração de UI resolve a dissonância cognitiva do painel,
espelhando visualmente a arquitetura do Model Context Protocol (MCP).
O Centro de Comando agora separa rigorosamente "Skills Semânticas"
(Comportamentos e guardrails) de "System Tools" (Binários brutos).

Principais alterações:
- feat(controls): separação estrutural entre `all_tools` e `semantic_skills` 
  no estado do DOM virtual.
- feat(iam): Gatekeeper agora delega apenas Skills Semânticas aos agentes, 
  impedido o mapeamento cego de ferramentas (anti-alucinação).
- feat(ui): novas seções interativas para criar, editar (buffer de guardrails) 
  e deletar Skills Semânticas, sincronizadas com `mctx_skills_v2.json`.
- feat(i18n): injeção de novas chaves de tradução (en e pt-BR) para a nova 
  hierarquia e dicas do rodapé dinâmico.
- test(bdd): blindagem profunda dos testes em `controls_view_spec.lua` 
  com mocks de isolamento, mantendo 100% de sucesso nos 223 testes.
- docs: atualização do README.md, CONTEXT.md e doc/multicontext.txt para a 
  Versão 2.3+, documentando o alinhamento MCP, Squads e JIT LSP.

Refs: Fase 41
'
