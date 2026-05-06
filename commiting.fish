#!/bin/fish

gitgo "
feat(memory): implementa Ecossistema CONTEXT.md Orgânico e The Harvester

Este commit resolve a amnésia da IA entre sessões (Feitiço do Tempo), transformando o arquivo CONTEXT.md no 'Córtex Frontal Compartilhado' (Memória de Longo Prazo) entre o usuário e o Swarm.

Principais implementações (Fase 45):
- **Injeção AST Silenciosa (Zero-Click):** Anexa o CONTEXT.md passivamente no payload do LLM sem poluir o buffer visual do usuário. Gerenciado pelo novo toggle `[ ON ] Auto-Inject` no Painel de Controle.
- **Feedback Visual (Badge):** Adiciona o indicador dinâmico `[📖 CONTEXT.md: Active]` no título do popup de chat.
- **Nova MCP Skill & Tool:** Cria a skill semântica `manage_project_knowledge` e a system tool `update_context_md`, dando autonomia aos agentes para documentar bugs crônicos cirurgicamente.
- **The Harvester (Colheitadeira em Background):** Acoplado ao evento `WORKSPACE_SAVED`. Delega a uma API em background a tarefa de ler o histórico da sessão, extrair decisões arquiteturais e injetar os aprendizados organicamente no CONTEXT.md sem travar o Neovim.
- **Self-Healing Ontology:** Lógica de merge no `skills_ontology.lua` para atualizar automaticamente o arquivo JSON de usuários legados com as novas skills padrão.

Cobertura: Mais de 250 testes Plenary passando com sucesso (TDD Green Phase).
"

# Alexandro agência BB Jaguaré
# protocolo atendimento BB: 202635367468/12 
# número do dispositivo: ****-9058 (samsung A16)
# Ricardo Dutra gerente vai entrar em contato comigo
