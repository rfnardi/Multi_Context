#!/bin/fish

gitgo '

feat(core): implementa topologia semântica, deduplicação de tools e polimorfismo de squads

Transição profunda da arquitetura do plugin de um modelo mecanicista para um Modelo Organizacional Semântico (Agentes -> Skills -> Tools), resolvendo problemas de token bloat e alucinações de tool-use.

Mudanças principais:
* Desempacotamento de Squads: O Swarm Manager agora aceita Squads como "targets" de delegação, desempacotando-os dinamicamente em pipelines de execução e injetando o "propósito coletivo" no prompt inicial.
* Deduplicação de Tools (Token Saving): O compilador de prompts agora analisa as dependências das skills e injeta o schema XML de cada ferramenta estritamente uma única vez por prompt, gerando extrema economia de tokens.
* Menu Polimórfico (@): O Fuzzy Finder de inserção foi unificado e agora lista tanto Agentes [A] quanto Squads [S], permitindo delegação transparente.
* Justificativa Semântica: Agentes agora recebem o "propósito" de uma habilidade antes da instrução mecânica, fornecendo contexto do "porquê" usar a ferramenta.
* Auto-Wrapper de Retrocompatibilidade: Camada de segurança que envelopa automaticamente ferramentas antigas e scripts soltos em Skills de acesso direto na RAM, garantindo que as configurações atuais do usuário não quebrem.

Ref: Fase 40 (Semantic Topology)
Testes: 220 testes unitários e de integração aprovados (100% Verde).

'
