# MultiContext AI - Plugin Neovim

## Visão Geral
MultiContext AI é um plugin nativo para Neovim que integra assistentes de IA com capacidades autônomas (estilo Devin/Claude Code). O plugin permite interação com múltiplos agentes especializados através de uma interface de chat, com acesso direto ao sistema de arquivos, execução de terminal, loops autônomos de raciocínio (ReAct) e gerenciamento ativo de janela de contexto. Na sua versão mais recente, suporta **Swarm Architecture** (Enxames de IA com MoA - Mixture of Agents), persistência assíncrona de estado (Stateful Workspace), **Meta-Agentes (Squads)**, **Memória Quadripartite (Watchdog Preditivo)** e um **Ecossistema de Skills Pluggáveis** que permite aos usuários expandirem as habilidades da IA localmente.

## Arquitetura Técnica

### Tecnologias Principais
- **Linguagem**: Lua (integração nativa com Neovim)
- **Framework de Testes**: `plenary.nvim` (busted) - **79/79 Passando Absolutamente**.
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
├── memory_tracker.lua    # Watchdog Preditivo com cálculo de Média Móvel (EMA) (Fase 22)
├── context_builders.lua  # Extratores de contexto injetando numeração de linhas estrita (1 | code)
├── queue_editor.lua      # Interface interativa visual (UI) para gerenciar APIs e permissões de Swarm
├── tools.lua             # Ferramentas nativas (leitura, edição, bash, LSP, Unified Diff)
├── utils.lua             # Ferramentas de cálculo de token e serialização de Workspace
├── ui/
│   ├── popup.lua         # Lógica da janela flutuante, carrossel de buffers e atalhos
│   ├── scroller.lua      # Smart Auto-Scroll silencioso e rastreador direcional
│   └── highlights.lua    # Highlights sintáticos customizados
└── tests/                # Suíte de testes automatizados (TDD/Plenary) - 79/79 Passando
```

## Funcionalidades e Capacidades Implementadas

### 1. Swarm Architecture Avançada (MoA, Pipelines e Coreografia)
- **Delegação via Tech Lead (Lazy Delegator)**: A persona `@tech_lead` orquestra a divisão de trabalho através da tool `spawn_swarm`, passando um payload JSON com as tarefas. O Tech Lead é orientado a não programar, mas sim projetar e repassar o trabalho.
- **Roteamento Cognitivo (Mixture of Agents - MoA)**: APIs e Agentes possuem um `abstraction_level` (high, medium, low). O `swarm_manager` distribui as tarefas priorizando APIs mais baratas (medium/low) que deem conta do recado, subindo para APIs caras (high) apenas como *Fallback Direcional*.
- **Pipelines Declarativos (Esteiras de Produção)**: Suporte à diretiva `"chain":["coder", "qa"]`. Quando o Coder termina, a tarefa não é encerrada: ela "reencarna" na fila para o QA, acumulando o contexto do agente anterior.
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

### 5. O Guardião Preditivo e a Compressão Quadripartite (Fase 22)
- **Watchdog via EMA**: Um rastreador analisa o tamanho histórico de tokens por turno usando uma Média Móvel Exponencial. Antes de despachar, o plugin projeta o tamanho futuro da requisição.
- **A Persona `@archivist`**: Se a janela segura (Cognitive Horizon) estiver ameaçada, o sistema sequestra a requisição do usuário, invoca o Arquivista invisivelmente, extrai a Memória Quadripartite (`<genesis>`, `<journey>`, `<now>`, `<plan>`), destrói a prolixidade do chat em tela e injeta essa memória hiper-compacta, restaurando o contexto antes de prosseguir com a requisição original.

### 6. Esquadrões Meta-Agentes (Squads - Fase 23)
- **Compilação Transparente de Intents**: O usuário pode chamar equipes pré-definidas no chat (ex: `@squad_dev`). O `prompt_parser` detecta o Squad, anexa a intent do usuário e transpila isso para um Payload JSON rígido encabeçado pelo `@tech_lead`, ativando Swarms complexos com fluidez de linguagem natural.

### 7. Unified Diff e Ferramentas Estritas (Fase 24)
- **Binário Nativo `patch`**: Implementação da skill `apply_diff`, focada em edições cirúrgicas em arquivos de milhares de linhas utilizando a arquitetura Universal Diff, prevenindo a temida alucinação do *"resto do código inalterado aqui..."* das LLMs.
- **Otimização Extrema de Prompts**: O manual do sistema base injetado na LLM foi emagrecido ao limite absoluto, garantindo a economia de centenas de tokens a cada requisição enviada.

### 8. Sistema de Agentes Estritos e Resiliência
- **Gatekeeper e Menor Privilégio**: Bloqueio de alucinações de agentes não autorizados usando ferramentas críticas (ex: Arquiteto rodando bash).
- **Parser de Tags**: O `tool_parser.lua` força o fechamento implícito de `<tool_call>` corrompidas.
- **Fallback Automático**: O `api_client` tenta automaticamente a próxima API da fila se a primária falhar por instabilidade ou Rate Limit.

---

## Decisões Técnicas Críticas
1. **Desacoplamento de UI e Background**: O motor Swarm distribui a carga via `curl` assíncrono e `vim.schedule()` mantendo a navegação do usuário fluida.
2. **Injeção Dinâmica de System Prompt**: Para permitir a troca de agentes na mesma aba (Coreografia), a primeira posição do array `messages` é reescrita *on-the-fly* dentro do próprio `tool_runner`/`swarm_manager`, enganando a LLM para assumir a nova persona sem perder o fluxo de consciência da tarefa.
3. **Delegation vs Execution (Skills)**: Isolamento das skills do usuário via `loadfile` e `pcall`.
4. **Queue Editor Interativo (`queue_editor.lua`)**: Em vez de editar JSON bruto, manipulamos buffers `acwrite` renderizando opções virtuais (`[x]`) para alternar a flag `allow_spawn` em tempo real na interface do editor.
5. **Uso de Ferramentas UNIX Nativas**: A escolha pelo utilitário `patch --force` garante operações de Unified Diff robustas a nível de Kernel sem reinventar a roda ou prender a *thread* com prompts de terminal interativos.

---

## Estado Atual do Desenvolvimento

### ✅ Implementado, Estável e Testado (Fases 1 a 24)
O core do produto alcançou o padrão de motor de orquestração industrial pesado.
- Arquitetura Swarm Avançada com Roteamento Cognitivo (MoA), Pipelines e Coreografia.
- Guardião Preditivo com compressão baseada no formato Quadripartite.
- Suporte a Squads (Esquadrões) fluindo por linguagem natural.
- Prevenção de Token Leak com `<final_report>`.
- Persistência de Workspace e Ressurreição de Estado (`.mctx`).
- Injeção e motor de execução de custom skills (Plugins), incluindo a skill pesada `apply_diff`.
- Refinamento de UI para gestão de APIs (Queue Editor).
- **Cobertura Testes Plenary:** 79 de 79 Sucessos absolutos (0 Falhas).

### 🔄 Próximos Passos (Fase Opcional e Comunidade)
Com a fundação tecnológica da V1 totalmente concluída e testada:
1. **Catalogar Exemplos de Skills**: Criar um repositório ou pasta `examples/` contendo scripts avançados de skills prontas (ex: `read_jira.lua`, `sql_inspector.lua`, `run_pytest.lua`).
2. **Distribuição via Lazy.nvim**: Preparar releases com *tags* (ex: `v1.0.0`) para garantir setups fluídos via gerenciadores de pacotes.

---
*Última atualização: 23 de Abril de 2026 - Preditividade de Contexto (Watchdog), Squads e Unified Diff consolidados.*
