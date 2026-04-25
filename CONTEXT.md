# MultiContext AI - Plugin Neovim

## Visão Geral
MultiContext AI é um plugin nativo para Neovim que integra assistentes de IA com capacidades autônomas (estilo Devin/Claude Code). O plugin permite interação com múltiplos agentes especializados através de uma interface de chat, com acesso direto ao sistema de arquivos, execução de terminal, loops autônomos de raciocínio (ReAct) e gerenciamento ativo de janela de contexto. Na sua versão V1.0, suporta **Swarm Architecture** (Enxames de IA com MoA - Mixture of Agents), persistência assíncrona de estado (Stateful Workspace), **Meta-Agentes (Squads)**, **Memória Quadripartite (Watchdog Preditivo)**, **Engine Virtual UI em Grid**, um **Ecossistema de Skills Pluggáveis e Editáveis** provido de exemplos práticos comunitários e **Context Injectors (\)** para composição dinâmica de prompts.

## Arquitetura Técnica

### Tecnologias Principais
- **Linguagem**: Lua (integração nativa com Neovim)
- **Framework de Testes**: `plenary.nvim` (busted) - **92/92 Passando Absolutamente**.
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
├── injectors.lua         # Motor visual (Menu \) e Loader para macros dinâmicas do usuário
├── api_client.lua        # Roteador de filas e fallbacks de API
├── transport.lua         # Motor de HTTP (curl), streams e cleanup de temp files
├── prompt_parser.lua     # Parser de intenções e Montador Dinâmico de Prompts e Skills
├── tool_parser.lua       # Extrator funcional e sanitizador de tags XML (Auto-close)
├── tool_runner.lua       # Gatekeeper de Permissões, executor nativo e roteador de plugins
├── swarm_manager.lua     # Cérebro do Enxame: filas, workers, ReAct, MoA, Pipelines e Coreografia
├── squads.lua            # Loader e resolvedor de Esquadrões Meta-Agentes (Fase 23)
├── skills_manager.lua    # Loader assíncrono e validador de código externo (Hot-Reload)
├── react_loop.lua        # Gerenciador de estado de sessão e Circuit Breaker
├── memory_tracker.lua    # Watchdog Preditivo com cálculo de Média Móvel (EMA) e Imunidade de Turno Inicial
├── context_builders.lua  # Extratores de contexto injetando numeração de linhas estrita (1 | code)
├── context_controls.lua  # Engine Virtual UI (Grid-Style) para Controle Mestre (API, IAM, Swarm, Watchdog)
├── tools.lua             # Ferramentas nativas (leitura, edição, bash, LSP, Unified Diff)
├── utils.lua             # Ferramentas de cálculo de token e serialização de Workspace
├── ui/
│   ├── popup.lua         # Lógica da janela flutuante, carrossel de buffers e atalhos (\, @)
│   ├── scroller.lua      # Smart Auto-Scroll silencioso e rastreador direcional
│   └── highlights.lua    # Highlights sintáticos unificados e paleta global
├── tests/                # Suíte de testes automatizados (TDD/Plenary) - 92/92 Passando
└── examples/
    ├── skills/           # Template Comunitário de Skills (Jira, Pytest, SQL)
    └── injectors/        # Template Comunitário de Injetores (Project Dump, LSP Errors, Git Log)
```

## Funcionalidades e Capacidades Implementadas

### 1. Canvas Dinâmico e Context Injectors (Fase 28)
- **Macros de Contexto**: A tecla `\` em modo de inserção abre um seletor virtual (semelhante ao comando `@` para agentes), permitindo injetar dinamicamente dados do projeto diretamente onde o cursor está posicionado.
- **Ecossistema de Injetores Locais**: Suporte para o usuário programar seus próprios conectores escrevendo um script lua simples (`~/.config/nvim/mctx_injectors/`). Exemplos já providos para leitura de Diagnósticos de LSP, Dump de Projeto e Logs de Git.

### 2. Engine Virtual UI e Identity & Access Management (IAM)
- **Grid Declarativo (Lazy-Style)**: Interface interativa unificada acessada via `:ContextControls`. Renderiza opções alinhadas horizontalmente com pontilhados (dot-leaders), cursores ocultos (`cursorline`) e ícones de alternância (`●` / `○`).
- **Interatividade e Mutação de Estado**: Controle total via teclado. `<Space>` para ligar/desligar permissões e fallbacks; `c` para editar variáveis contínuas (limites de loops, gatilho do watchdog, identidade); `dd` e `p` para reordenar a fila de APIs.
- **Matriz de Permissões de Agentes**: Controle fino (Drill-down via `<CR>`) que lista cada agente e permite ligar/desligar ferramentas específicas (Skills) apenas para aquele agente, salvando o Perfil de Menor Privilégio no `mctx_agents.json`.
- **Fábrica Dinâmica de Entidades**: Criação instantânea de novas Skills customizadas (gera boilerplate Lua) e novas Personas a partir de botões `[ + ]` inseridos no Virtual DOM do painel.

### 3. Swarm Architecture Avançada (MoA, Pipelines e Coreografia)
- **Delegação via Tech Lead**: Orquestração via `spawn_swarm`.
- **Roteamento Cognitivo (MoA)**: O painel visual permite ordenar quem resolve qual tarefa e marcar quem é *Fallback Direcional*. O sistema checa automaticamente a compatibilidade entre a capacidade cognitiva da API e a demanda do agente.
- **Pipelines e Coreografia**: Reencarnação de tarefas em esteiras e injeção do sistema `switch_agent` para o agente ceder o controle e reconfigurar a persona *in-flight*.

### 4. O Guardião Preditivo, Compressão Quadripartite e 3 Motores
- **Watchdog via EMA**: O rastreador preditivo calcula a média móvel geométrica (EMA), somando o peso do buffer atual. Exibe a telemetria ao vivo na UI.
- **3 Motores de Compressão**: Configurável via painel interativo (Semântico, Percentual e Fixo).
- **A Persona @archivist**: Transmutações complexas do buffer inteiro num modelo estrito XML `<genesis>`, `<plan>`, `<journey>`, `<now>`.

### 5. Esquadrões Meta-Agentes e Skills Pluggáveis (Comunidade V1.0)
- Compilação transparente de menções a esquadrões (ex: `@squad_dev`).
- Scripts pluggáveis via `~/.config/nvim/mctx_skills/` com validação de Gatekeeper, hot-reload autônomo e isolamento de escopo.

### 6. Unified Diff e Persistência de Workspace
- Persistência e Ressurreição de todo o Enxame através de injeção JSON-in-XML no arquivo `.mctx`.
- Edições cirúrgicas nativas acopladas ao Kernel UNIX via `patch --force`.

### 7. Canvas Fuzzy e UX Preditiva (Fase 29)
- **Seletores Inteligentes (Telescope-like)**: Ao invocar `@` (Agentes) ou `\` (Injetores), o menu não é estático. Ele opera como um Fuzzy Finder ao vivo que lê o buffer no modo Insert (`TextChangedI`) e filtra os resultados instantaneamente, lidando com erros de digitação e pesquisas parciais.
- **Smart Placement**: O motor de injeção protege o prompt do usuário, lançando os enormes blocos de contexto (dumps, logs) na linha *abaixo* do cursor, preservando a legibilidade e o raciocínio atual.

### 8. Motor Polyglot (Linguagem Agnóstica)
- **Liberdade Absoluta**: Skills e Injectors não estão mais presos a scripts `.lua`. O motor agora aceita **qualquer script executável do sistema** (`.sh`, `.fish`, `.py`, `.js`, binários Golang/Rust).
- **Injeção de Metadados em Comentários**: O usuário documenta o script livremente usando cabeçalhos simples (`# DESC: ...` e `# PARAM: target | string | true | desc`).
- **Ponte de Variáveis de Ambiente**: A IA interage com as linguagens do usuário exportando os parâmetros extraídos como `env` POSIX (ex: envia o parâmetro `query` como `$MCTX_QUERY` direto para o script Bash/Fish local).

---

## Estado Atual do Desenvolvimento

### ✅ Implementado, Estável e Testado (V1.0 - Produção)
O core do produto é um motor de orquestração industrial de ponta.
- Interface `LazyVim-like` iterativa e mutável (Grid, Ícones, Toggles IAM, Drill-down).
- Extensibilidade dupla: Skills ativas para a IA, Injectors textuais (`\`) para o Usuário.
- Watchdog Preditivo 2.0 (Motores de Compressão Flexíveis).
- IAM de Agentes e Skills editáveis em tempo real.
- Swarm Avançado (MoA, Pipelines, Coreografia).
- Unified Diff, Workspace Persistente e Esquadrões.
- **Cobertura Testes Plenary:** 94 de 94 Sucessos absolutos (0 Falhas / 0 Erros).
