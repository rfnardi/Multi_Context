#!/bin/fish 

gitgo '

feat(llm): blindagem cognitiva e guardrails anti-alucinação

Finaliza a Fase 36 do desenvolvimento, focada em otimização de contexto
e mitigação de alucinações (tool-use) nos modelos de IA.

Mudanças implementadas:
- 🛡️ Recency Bias Guardrails: Regras críticas (STRICT XML ONLY, sem
  wrappers markdown) agora são injetadas no final absoluto do
  System Prompt, garantindo obediência imediata do modelo.
- 🛑 Zero-Skill Awareness: Agentes sem ferramentas habilitadas recebem
  um aviso explícito ("NO TOOLS") para impedir a invenção de tags e 
  forçar a resolução via raciocínio puro.
- ⚙️ Registry Otimizado: O manual de ferramentas foi reescrito
  adotando linguagem imperativa e concisa (estilo Claude Code),
  reduzindo tokens e reforçando o limite de 1 ação por turno.
- 🧪 Testes de Prompt: Adição do `prompt_hardening_spec.lua` para
  garantir a integridade estrutural das strings injetadas no motor.

Marco atingido: 149/149 testes automatizados no verde (100% de sucesso).

[Fase 36 Concluída]


'
