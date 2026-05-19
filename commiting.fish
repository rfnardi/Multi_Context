#!/bin/fish

gitgo '
fix(swarm): erradica context overflow na serialização de estado

Causa raiz:
A função `build_workspace_content` capturava todo o log visual da UI 
(`lines`) dos workers do Swarm e o injetava no payload JSON da AST. 
Isso causava um Context Overflow massivo, cegando o Mecanismo de Atenção 
do LLM e gerando "Alucinação de Ferramentas" e loops de respostas vazias.

Mudanças:
- Refatorado `utils.build_workspace_content` para salvar estritamente 
  metadados lógicos (nome do worker, status), omitindo a chave `lines`.
- Implementada Degradação Graciosa na UI em `utils.load_workspace_state` 
  para injetar um Placeholder Semântico ("Histórico visual arquivado...") 
  durante a hidratação, mantendo a interface limpa sem gastar tokens.
- Adicionados 2 novos testes TDD em `utils_spec.lua` para garantir a 
  serialização Anti-Leak e o placeholder (total de 284 testes 100% green).
- Atualizado CONTEXT.md para refletir a V2.4.4 e a Fase 49.
'

