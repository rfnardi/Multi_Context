# MultiContext AI - Plugin Neovim

## Visão Geral
MultiContext AI é um plugin nativo para Neovim que integra assistentes de IA com capacidades autônomas (estilo Devin/Claude Code). O plugin permite interação com múltiplos agentes especializados através de uma interface de chat, com acesso direto ao sistema de arquivos, execução de terminal, loops autônomos de raciocínio (ReAct) e gerenciamento ativo de janela de contexto. Na sua versão V1.2, suporta **Swarm Architecture** (Enxames de IA com MoA - Mixture of Agents), persistência assíncrona de estado (Stateful Workspace), **Meta-Agentes (Squads)**, **Memória Quadripartite (Watchdog Preditivo)**, um **Ecossistema de Skills Pluggáveis e Editáveis** provido de exemplos práticos comunitários, **Context Injectors (\)** para composição dinâmica de prompts, pesquisa ultrarrápida com **Ripgrep**, navegação cirúrgica por código via **LSP** (Go to Definition/References), um **Agente DevOps** para automação local de Git e um **Centro de Comando Virtual** com 12 seções para gerenciamento total da IDE.

## Arquitetura Técnica

### Tecnologias Principais
- **Linguagem**: Lua (integração nativa com Neovim)
- **Framework de Testes**: `plenary.nvim` (busted) - **111 Testes Unitários e de Integração (100% de Sucesso Absoluto)**, com isolamento severo de mocks (I/O, Kernel).
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
├── transport.lua         # Motor de HTTP (curl), streams, telemetria (debug) e cleanup
├── prompt_parser.lua     # Parser de intenções e Montador Dinâmico de Prompts e Skills
├── tool_parser.lua       # Extrator funcional e sanitizador de tags XML (Auto-close)
├── tool_runner.lua       # Gatekeeper de Permissões, executor nativo e roteador de plugins
├── swarm_manager.lua     # Cérebro do Enxame: filas, workers, ReAct, MoA, Pipelines e Coreografia
├── squads.lua            # Loader e resolvedor de Esquadrões Meta-Agentes (Fase 23)
├── skills_manager.lua    # Loader assíncrono e validador de código externo (Hot-Reload)
├── lsp_utils.lua         # Ponte silenciosa com o Neovim LSP (Go to Definition/References)
├── react_loop.lua        # Gerenciador de estado de sessão e Circuit Breaker
├── memory_tracker.lua    # Watchdog Preditivo com cálculo de Média Móvel (EMA) e Imunidade de Turno Inicial
├── context_builders.lua  # Extratores de contexto injetando numeração de linhas estrita (1 | code)
├── context_controls.lua  # Centro de Comando Master (12 Seções: API, IAM, Swarm, Histórico, Vault, Apperance)
├── tools.lua             # Ferramentas nativas (leitura, edição, bash, LSP, Unified Diff, Git, Ripgrep)
├── utils.lua             # Ferramentas de cálculo de token e serialização de Workspace
├── ui/
│   ├── popup.lua         # Lógica da janela flutuante dinamicamente estilizada, carrossel e atalhos
│   ├── scroller.lua      # Smart Auto-Scroll silencioso e rastreador direcional
│   └── highlights.lua    # Highlights sintáticos unificados e paleta global
├── tests/                # Suíte de testes automatizados (TDD/Plenary) contendo mocks complexos
│   ├── git_tools_spec.lua        # Testes de Automação Git e Gatekeeper
│   ├── lsp_utils_spec.lua        # Testes da Ponte LSP Silenciosa
│   ├── tool_runner_lsp_spec.lua  # Testes de Roteamento LSP
│   └── ... (mais 34 arquivos)
└── examples/
    ├── skills/           # Template Comunitário de Skills (Jira, Pytest, SQL)
    └── injectors/        # Template Comunitário de Injetores (Project Dump, LSP Errors, Git Log)
```

## Funcionalidades e Capacidades Implementadas

### 1. Canvas Dinâmico e Context Injectors (Fase 28)
- **Macros de Contexto**: A tecla `\` em modo de inserção abre um seletor virtual (semelhante ao comando `@` para agentes), permitindo injetar dinamicamente dados do projeto diretamente onde o cursor está posicionado.
- **Ecossistema de Injetores Locais**: Suporte para o usuário programar seus próprios conectores escrevendo um script lua simples (`~/.config/nvim/mctx_injectors/`). Exemplos já providos para leitura de Diagnósticos de LSP, Dump de Projeto e Logs de Git.

### 2. Centro de Comando Master e Identity & Access Management (IAM)
- **Grid Declarativo de 12 Seções**: Interface interativa unificada acessada via `:ContextControls`. Renderiza opções com pontilhados (`· · ·`), expansores `[+]`/`[-]` e ícones lógicos (`[ ON ]`, `[ ✓ ]`). Suporta descrições dinâmicas de seções ocultas.
- **Footer Dinâmico Ancorado**: O rodapé do painel instrui o usuário sobre qual ação tomar (`<Space>`, `c`, `e`, `<CR>`) dependendo de onde o cursor está posicionado. Utiliza a API nativa de `footer` do Neovim 0.10+ para manter a dica sempre visível independentemente da rolagem do buffer.
- **Interatividade e Mutação de Estado**: Controle total via teclado. Permite ligar/desligar permissões, editar limites de loops, reordenar a fila de APIs (`dd` e `p`), editar Master Prompts e acionar a Telemetria da IDE. Proteção nativa contra o erro `E37` garantindo transições suaves de janelas flutuantes para edição de arquivos.
- **Matriz de Permissões de Agentes**: Controle fino que lista cada agente e permite ligar/desligar ferramentas específicas (Skills) apenas para aquele agente, salvando o Perfil de Menor Privilégio no `mctx_agents.json`.
- **Gestão Avançada de Personas**: Permite criar, deletar (com confirmação) e editar o *System Prompt* de agentes. A edição abre um buffer temporário isolado na IDE, com *Auto-Save* em background transparente (`BufWritePost`) direto no arquivo de configuração do usuário.
- **Fábrica Dinâmica de Entidades**: Criação instantânea de novas Skills, Injectors e Personas a partir de botões `[ + ]` no Virtual DOM do painel, gerando boilerplate Lua e abrindo o buffer imediatamente.

### 3. Swarm Architecture Avançada (MoA, Pipelines e Coreografia)
- **Delegação via Tech Lead**: Orquestração via `spawn_swarm`.
- **Roteamento Cognitivo Dinâmico (MoA)**: O painel visual permite ordenar quem resolve qual tarefa, alterar visualmente o **Nível de Abstração Cognitiva** da API (`low/medium/high`) com a tecla `<Space>` e marcar quem é *Fallback Direcional*. O sistema checa automaticamente a compatibilidade entre a capacidade cognitiva da API e a demanda do agente.
- **Pipelines e Coreografia**: Reencarnação de tarefas em esteiras e injeção do sistema `switch_agent` para o agente ceder o controle e reconfigurar a persona *in-flight*.

### 4. O Guardião Preditivo, Compressão Quadripartite e 3 Motores
- **Watchdog via EMA**: O rastreador preditivo calcula a média móvel geométrica (EMA), somando o peso do buffer atual. Exibe a telemetria ao vivo na UI.
- **3 Motores de Compressão**: Configurável via painel interativo (Semântico, Percentual e Fixo).
- **A Persona @archivist**: Transmutações complexas do buffer inteiro num modelo estrito XML `<genesis>`, `<plan>`, `<journey>`, `<now>`.

### 5. Esquadrões Meta-Agentes e Skills Pluggáveis (Comunidade V1.0)
- Compilação transparente de menções a esquadrões (ex: `@squad_dev`).
- Gestão completa de Esquadrões através do painel, permitindo visualizar a esteira (chain) de execução e editar o arquivo `.json`.
- Scripts pluggáveis via `~/.config/nvim/mctx_skills/` com validação de Gatekeeper, hot-reload autônomo e isolamento de escopo.

### 6. Unified Diff e Persistência de Workspace
- **Ressurreição Visual**: A seção `Histórico e Workspaces` no painel lista automaticamente os últimos arquivos `.mctx` salvos no projeto, permitindo dar Load na conversa com um `<CR>`.
- Persistência de todo o Enxame através de injeção JSON-in-XML.
- Edições cirúrgicas nativas acopladas ao Kernel UNIX via `patch --force`.

### 7. Canvas Fuzzy e UX Preditiva (Fase 29)
- **Seletores Inteligentes (Telescope-like)**: Ao invocar `@` (Agentes) ou `\` (Injetores), o menu opera como um Fuzzy Finder ao vivo que lê o buffer no modo Insert (`TextChangedI`) e filtra os resultados instantaneamente.
- **Smart Placement**: O motor de injeção protege o prompt do usuário, lançando os enormes blocos de contexto (dumps, logs) na linha *abaixo* do cursor, preservando a legibilidade.

### 8. Motor Polyglot (Linguagem Agnóstica)
- **Liberdade Absoluta**: Skills e Injectors não estão mais presos a scripts `.lua`. O motor agora aceita **qualquer script executável do sistema** (`.sh`, `.fish`, `.py`, `.js`, binários Golang/Rust).
- **Injeção de Metadados em Comentários**: O usuário documenta o script livremente usando cabeçalhos simples (`# DESC: ...` e `# PARAM: target | string | true | desc`).
- **Ponte de Variáveis de Ambiente**: A IA interage com as linguagens do usuário exportando os parâmetros extraídos como `env` POSIX (ex: envia o parâmetro `query` como `$MCTX_QUERY` direto para o script Bash/Fish local).

### 9. Navegação Cirúrgica e Busca (LSP + Ripgrep) (Fase 30)
- **Ripgrep Nativo**: Uso inteligente de `rg` (com fallback seguro para `git grep`) na ferramenta `search_code`, garantindo buscas globais instantâneas, respeitando `.gitignore` e indexando arquivos recém-criados.
- **Integração LSP Avançada**: A IA atua na IDE como um humano. Através da "Ponte Silenciosa", a IA interroga o servidor LSP do Neovim (`lsp_definition`, `lsp_references`, `lsp_document_symbols`), encontrando onde classes/funções foram definidas e extraindo *apenas os blocos relevantes* de código, garantindo uma economia drástica de tokens em relação a buscas via RAG (Vector DBs).

### 10. Automação Git e Agente DevOps (Fase 31)
- **Agente DevOps Autônomo**: Persona nativa (`@devops`) voltada exclusivamente para controle de versão, encarregada de avaliar Diffs e realizar Commits Semânticos.
- **Comandos Git Locais**: Ferramentas cirúrgicas (`git_status`, `git_branch`, `git_commit`) acessíveis para gerenciar o estado da árvore de trabalho e isolar implementações em branches temporárias (ex: `checkout -b`).
- **Gatekeeper de Segurança**: Travas profundas impedem a IA de realizar `git add .` (forçando-a a comitar arquivos individualmente) e proíbem comandos destrutivos/remotos como `git push`, `reset --hard` ou `rebase` sem a confirmação manual via UI (`[Permitir/Negar]`).

---

## Estado Atual do Desenvolvimento

### ✅ Implementado, Estável e Testado (V1.2.1 - Produção)
O core do produto é um motor de orquestração industrial de ponta.
- Interface `LazyVim-like` com Footer Dinâmico Ancorado e 12 Módulos Master (APIs, Watchdog, Estilização, Cofre, Telemetria).
- Extensibilidade dupla: Skills ativas para a IA, Injectors textuais (`\`) para o Usuário.
- Watchdog Preditivo 2.0 (Motores de Compressão Flexíveis).
- IAM de Agentes e Skills editáveis em tempo real (Deleção Segura, Edição de Prompts Isolada).
- Integração Completa: O Motor de HTTP (`transport.lua`) e a UI (`popup.lua`) consomem variáveis do Painel ao vivo.
- Swarm Avançado (MoA, Níveis Cognitivos Mutáveis, Pipelines, Coreografia).
- Unified Diff, Workspace Persistente e Esquadrões.
- Integração nativa com Neovim LSP e Ripgrep para navegação determinística.
- Automação Git local via Agente DevOps com travas de segurança atômicas.
- **Cobertura de Testes Plenary:** 115 testes de Unidade e Integração isolados e garantidos (0 Falhas / 0 Erros - 100% Passando Absolutamente).
