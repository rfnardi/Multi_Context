# MultiContext AI - Plugin Neovim

## Visão Geral
MultiContext AI é um plugin nativo para Neovim que integra assistentes de IA com capacidades autônomas (estilo Devin/Claude Code). O plugin permite interação com múltiplos agentes especializados através de uma interface de chat, com acesso direto ao sistema de arquivos, execução de terminal, loops autônomos de raciocínio (ReAct) e gerenciamento ativo de janela de contexto. Na sua versão mais recente, suporta **Swarm Architecture** (Enxames de IA com MoA - Mixture of Agents), persistência assíncrona de estado (Stateful Workspace) e um **Ecossistema de Skills Pluggáveis** que permite aos usuários expandirem as habilidades da IA localmente.

## Arquitetura Técnica

### Tecnologias Principais
- **Linguagem**: Lua (integração nativa com Neovim)
- **Framework de Testes**: `plenary.nvim` (busted)
- **Operações Assíncronas e Rede**: `vim.fn.jobstart` / `vim.fn.jobstop` abstraídos via módulo de transporte customizado (`curl` não-bloqueante).
- **Processamento de XML**: Parser funcional tolerante a falhas, com auto-fechamento implícito de tags contra alucinações.
- **Concorrência**: Implementação de *Worker Pool* nativo gerenciando Promises assíncronas do `curl` sem travar a thread principal de UI do Neovim.
- **Serialização de Estado**: Metadata Envelope e injeção de JSON em XML para salvar e recuperar as sessões do enxame sem perder legibilidade do arquivo original.

### Estrutura de Diretórios
```text
lua/multi_context/
├── init.lua              # Orquestrador principal, monitoramento live de stream e hooks
├── config.lua            # Configurações, Bootstrapping de Usuário e Auto-Setup
├── agents.lua            # Inicializador do mctx_agents.json do usuário
├── api_client.lua        # Roteador de filas e fallbacks de API
├── transport.lua         # Motor de HTTP (curl), streams e cleanup de temp files
├── prompt_parser.lua     # Parser de intenções e Montador Dinâmico de Prompts e Skills
├── tool_parser.lua       # Extrator funcional e sanitizador de tags XML (Auto-close)
├── tool_runner.lua       # Gatekeeper de Permissões, executor nativo e roteador de plugins
├── swarm_manager.lua     # Cérebro do Enxame: filas, workers, ReAct, MoA, Pipelines e Coreografia
├── skills_manager.lua    # Loader assíncrono e validador de código externo (Hot-Reload)
├── react_loop.lua        # Gerenciador de estado de sessão e Circuit Breaker
├── context_builders.lua  # Extratores de contexto injetando numeração de linhas estrita (1 | code)
├── tools.lua             # Ferramentas nativas (leitura, edição, bash, LSP)
├── utils.lua             # Ferramentas de cálculo de token e serialização de Workspace
├── ui/
│   ├── popup.lua         # Lógica da janela flutuante, carrossel de buffers e atalhos
│   ├── scroller.lua      # Smart Auto-Scroll silencioso e rastreador direcional
│   └── highlights.lua    # Highlights sintáticos customizados
└── tests/                # Suíte de testes automatizados (TDD/Plenary) - 64/64 Passando
```

## Funcionalidades e Capacidades Implementadas

### 1. Swarm Architecture Avançada (MoA, Pipelines e Coreografia)
- **Delegação via Tech Lead (Lazy Delegator)**: A persona `@tech_lead` orquestra a divisão de trabalho através da tool `spawn_swarm`, passando um payload JSON com as tarefas. O Tech Lead é orientado a não programar, mas sim projetar e repassar o trabalho.
- **Roteamento Cognitivo (Mixture of Agents - MoA)**: APIs e Agentes possuem um `abstraction_level` (high, medium, low). O `swarm_manager` distribui as tarefas priorizando APIs mais baratas (medium/low) que deem conta do recado, subindo para APIs caras (high) apenas como *Fallback Direcional*.
- **Pipelines Declarativos (Esteiras de Produção)**: Suporte à diretiva `"chain": ["coder", "qa"]`. Quando o Coder termina, a tarefa não é encerrada: ela "reencarna" na fila para o QA, acumulando o contexto do agente anterior.
- **Coreografia (Ping-Pong Autônomo)**: Sub-agentes autorizados via `"allow_switch"` podem usar a tool `switch_agent` para transferir o controle da aba e da tarefa em tempo real para outro agente (ex: chamar o DBA). O sistema injeta o novo System Prompt *in-flight* sem fechar o motor ReAct.
- **Carrossel de Buffers (UI)**: Sub-agentes rodam em abas invisíveis (`nofile`) dentro do mesmo *popup*. O usuário navega em tempo real com `<Tab>` e `<S-Tab>`.

### 2. Prevenção Extrema de Token Leak (Fase 20)
- **Extração Cirúrgica (`<final_report>`)**: Em vez de retornar todo o scratchpad (logs de ferramentas, raciocínios intermediários) para o Tech Lead, o Swarm extrai rigorosamente apenas o que está dentro da tag `<final_report>`. Isso salva milhares de tokens a cada turno.

### 3. Persistência de Workspace Stateful (Fase 18.5)
- **Metadata Envelope (`<mctx_session>`)**: Cada sessão salva em disco recebe um ID e timestamps. Isso evita a duplicação de arquivos e mantém rastreabilidade.
- **JSON-in-XML**: Todo o estado volátil das tarefas do enxame (`M.state.queue`, buffers inativos e `reports`) é empacotado e salvo em uma tag oculta `<swarm_state>`. Quando o usuário reabre o Neovim e invoca o log, todo o Swarm ressuscita perfeitamente.

### 4. Sistema Pluggável de Skills (Fase 19)
- **Extensibilidade Local**: O `skills_manager` varre a pasta `~/.config/nvim/mctx_skills/` em busca de novos scripts `.lua`.
- **Injeção de Prompt**: O plugin gera os manuais em formato XML das funções do usuário dinamicamente e ensina a IA a utilizá-las.
- **Roteamento Seguro**: O `tool_runner` roda a ferramenta do usuário através de um `pcall` (Proteção contra crashes por código mal formatado).
- **Hot-Reload Automático**: A qualquer momento a ram é limpa e atualizada via `:ContextReloadSkills`.

### 5. Sistema de Agentes Estritos (Padrão Devin/Claude Code)
- **Princípio do Menor Privilégio**: O Gatekeeper intercepta alucinações de agentes não autorizados (ex: Arquiteto rodando bash).
- **Prevenção de Context Rot**: Regras estritas nos *system prompts* priorizam substituições cirúrgicas (`replace_lines`) em vez de reescritas totais.

### 6. Resiliência de Parser e Rede
- **Fechamento Implícito de Tags**: O `tool_parser.lua` força o fechamento de `<tool_call>` corrompidas.
- **Proteção de Papéis Strict (Anthropic)**: O `conversation.lua` funde textos órfãos prevenindo falhas de papéis adjacentes.
- **Fallback Automático**: O `api_client` tenta automaticamente a próxima API da fila se a primária estourar limite.

---

## Decisões Técnicas Críticas
1. **Desacoplamento de UI e Background**: O motor Swarm distribui a carga via `curl` assíncrono e `vim.schedule()` mantendo a navegação do usuário fluida.
2. **Injeção Dinâmica de System Prompt**: Para permitir a troca de agentes na mesma aba (Coreografia), a primeira posição do array `messages` é reescrita *on-the-fly* dentro do próprio `tool_runner`/`swarm_manager`, enganando a LLM para assumir a nova persona sem perder o fluxo de consciência da tarefa.
3. **Delegation vs Execution (Skills)**: Isolamento das skills do usuário via `loadfile` e `pcall`.

---

## Estado Atual do Desenvolvimento

### ✅ Implementado, Estável e Testado (Fases 1 a 21)
O core do produto alcançou o padrão de motor de orquestração industrial.
- A Arquitetura Swarm Avançada (MoA, Pipelines, Coreografia e Worker Pool).
- O motor de Retry contra Rate Limits assíncrono.
- A Prevenção de Token Leak com `<final_report>`.
- A Persistência de Workspace e Ressurreição de Estado (`.mctx`).
- A injeção e motor de execução de custom skills (Plugins).
- **Cobertura Testes Plenary:** 64 de 64 Sucessos absolutos.

### 🔄 Próximos Passos
1. **Refinamento do Queue Editor**: Atualizar a interface do `queue_editor.lua` para que o usuário possa ativar ou desativar a flag `"allow_spawn"` de cada API diretamente pela UI do Neovim.
2. **Ferramenta de Diff Unificado (Opcional)**: Adicionar uma skill nativa baseada em *Unified Diff/Patch* para edições muito grandes.
3. **Revisão e Otimização do System Prompt Base**: Sintetizar as instruções nativas base para dar mais espaço de token às skills criadas pelos usuários.

---
*Última atualização: 23 de Abril de 2026 - Fases 20 e 21 (Handoffs Avançados e MoA) consolidadas.*
