# MultiContext AI - Plugin Neovim

## Visão Geral
MultiContext AI é um plugin nativo para Neovim que integra assistentes de IA com capacidades autônomas (estilo Devin/Claude Code). O plugin permite interação com múltiplos agentes especializados através de uma interface de chat, com acesso direto ao sistema de arquivos, execução de terminal, loops autônomos de raciocínio (ReAct) e gerenciamento ativo de janela de contexto. Na sua versão mais recente, suporta **Swarm Architecture** (Enxames de IA com MoA - Mixture of Agents), persistência assíncrona de estado (Stateful Workspace), **Meta-Agentes (Squads)**, **Memória Quadripartite (Watchdog Preditivo)**, **Engine Virtual UI em Grid** e um **Ecossistema de Skills Pluggáveis e Editáveis** que permite aos usuários forjarem as habilidades da IA localmente.

## Arquitetura Técnica

### Tecnologias Principais
- **Linguagem**: Lua (integração nativa com Neovim)
- **Framework de Testes**: `plenary.nvim` (busted) - **84/84 Passando Absolutamente**.
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
├── squads.lua            # Loader e resolvedor de Esquadrões Meta-Agentes (Fase 23)
├── skills_manager.lua    # Loader assíncrono e validador de código externo (Hot-Reload)
├── react_loop.lua        # Gerenciador de estado de sessão e Circuit Breaker
├── memory_tracker.lua    # Watchdog Preditivo com cálculo de Média Móvel (EMA) e Imunidade de Turno Inicial
├── context_builders.lua  # Extratores de contexto injetando numeração de linhas estrita (1 | code)
├── context_controls.lua  # Engine Virtual UI (Grid-Style) para Controle Mestre (API, IAM, Swarm, Watchdog)
├── tools.lua             # Ferramentas nativas (leitura, edição, bash, LSP, Unified Diff)
├── utils.lua             # Ferramentas de cálculo de token e serialização de Workspace
├── ui/
│   ├── popup.lua         # Lógica da janela flutuante, carrossel de buffers e atalhos
│   ├── scroller.lua      # Smart Auto-Scroll silencioso e rastreador direcional
│   └── highlights.lua    # Highlights sintáticos unificados e paleta global
└── tests/                # Suíte de testes automatizados (TDD/Plenary) - 84/84 Passando
```

## Funcionalidades e Capacidades Implementadas

### 1. Engine Virtual UI e Identity & Access Management (IAM) - (Fase 26)
- **Grid Declarativo (Lazy-Style)**: Interface interativa unificada acessada via `:ContextControls`. Renderiza opções alinhadas horizontalmente com pontilhados (dot-leaders), cursores ocultos (`cursorline`) e ícones de alternância (`●` / `○`).
- **Matriz de Permissões de Agentes**: Controle fino (Drill-down) que lista cada agente e permite ligar/desligar ferramentas específicas (Skills) apenas para aquele agente, salvando no perfil isolado.
- **Fábrica de Entidades**: Criação de novas Skills customizadas e novas Personas dinamicamente a partir do painel.
- **Edição Expressa**: O atalho `e` no painel sobre o nome de uma Skill abre instantaneamente o seu código Lua base para debug.

### 2. Swarm Architecture Avançada (MoA, Pipelines e Coreografia)
- **Delegação via Tech Lead**: Orquestração via `spawn_swarm`.
- **Roteamento Cognitivo (MoA)**: O painel visual permite ordenar quem resolve qual tarefa e marcar quem é *Fallback Direcional*.
- **Pipelines e Coreografia**: Reencarnação de tarefas em esteiras e injeção do sistema `switch_agent` para o agente ceder o controle in-flight.

### 3. O Guardião Preditivo, Compressão Quadripartite e 3 Motores (Fase 22 a 25)
- **Watchdog via EMA**: O rastreador calcula a média móvel, somando o peso do buffer atual. Exibe a telemetria ao vivo na UI: `Multi_Context_Chat | ~3500 tokens | WD: Ask`.
- **3 Motores de Compressão**: Configurável via painel interativo (Semântico, Percentual e Fixo).
- **Imunidade de Turno (Cold Start)**: O sistema detecta colagens gigantes no começo da conversa e não sequestra a requisição do usuário no turno inaugural.

### 4. Esquadrões Meta-Agentes e Skills Pluggáveis (Fases 19 e 23)
- Compilação transparente de menções a esquadrões (ex: `@squad_dev`).
- Scripts pluggáveis via `~/.config/nvim/mctx_skills/` com validação de Gatekeeper e hot-reload autônomo.

### 5. Unified Diff e Persistência de Workspace
- Persistência e Ressurreição de todo o Enxame através de injeção JSON-in-XML no arquivo `.mctx`.
- Edições cirúrgicas nativas acopladas ao Kernel UNIX via `patch --force`.

---

## Decisões Técnicas Críticas
1. **Desacoplamento de UI e Background**: O motor Swarm distribui a carga via `curl` assíncrono e `vim.schedule()` mantendo a navegação do usuário fluida.
2. **Injeção Dinâmica de System Prompt**: A primeira posição do array de redes é reescrita *on-the-fly* no `tool_runner`/`swarm_manager`, emulando a persona nova sem perder o raciocínio.
3. **Virtual DOM com Mutação Segura**: O `:ContextControls` opera lendo e manipulando uma Tabela de Estado Lua e forçando re-renderizações no buffer visual sem bloquear arquivos. A limpeza agressiva previne vazamento de buffers (`buftype=acwrite`, `bufhidden=wipe`).

---

## Estado Atual do Desenvolvimento

### ✅ Implementado, Estável e Testado (Fases 1 a 26)
O core do produto é um motor de orquestração industrial de ponta.
- Interface `LazyVim-like` (Grid, Ícones, Toggles de Permissão, Drill-down).
- Watchdog Preditivo 2.0 (Motores de Compressão Flexíveis).
- IAM de Agentes e Skills editáveis em tempo real.
- Swarm Avançado (MoA, Pipelines, Coreografia).
- **Cobertura Testes Plenary:** 84 de 84 Sucessos absolutos (0 Falhas / 0 Erros).

### 🔄 Próximos Passos (Fase Opcional e Comunidade)
Com a fundação tecnológica da V1.0 totalmente concluída e testada:
1. **Catalogar Exemplos de Skills**: Criar um repositório com scripts avançados de skills prontas (ex: `read_jira.lua`, `sql_inspector.lua`, `run_pytest.lua`).
2. **Distribuição via Lazy.nvim**: Preparar releases com *tags* (ex: `v1.0.0`) para distribuição.

---
*Última atualização: Abril de 2026 - Fase 26: Modernização UI/UX (Lazy-Style Grid) e Gestão IAM concluídos (84/84 tests).*
