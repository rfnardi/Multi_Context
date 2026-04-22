# MultiContext AI - Plugin Neovim

## Visão Geral
MultiContext AI é um plugin nativo para Neovim que integra assistentes de IA com capacidades autônomas (estilo Devin/Claude Code). O plugin permite interação com múltiplos agentes especializados através de uma interface de chat, com acesso direto ao sistema de arquivos, execução de terminal, loops autônomos de raciocínio (ReAct) e gerenciamento ativo de janela de contexto. Na sua versão mais recente, suporta **Swarm Architecture** (Enxames de IA), persistência assíncrona de estado (Stateful Workspace) e um **Ecossistema de Skills Pluggáveis** que permite aos usuários expandirem as habilidades da IA localmente.

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
├── swarm_manager.lua     # Cérebro do Enxame: gerencia filas, workers, auto-retry e ReAct background
├── skills_manager.lua    # Loader assíncrono e validador de código externo (Hot-Reload)
├── react_loop.lua        # Gerenciador de estado de sessão e Circuit Breaker
├── context_builders.lua  # Extratores de contexto injetando numeração de linhas estrita (1 | code)
├── tools.lua             # Ferramentas nativas (leitura, edição, bash, LSP)
├── utils.lua             # Ferramentas de cálculo de token e serialização de Workspace
├── ui/
│   ├── popup.lua         # Lógica da janela flutuante, carrossel de buffers e atalhos
│   ├── scroller.lua      # Smart Auto-Scroll silencioso e rastreador direcional
│   └── highlights.lua    # Highlights sintáticos customizados
└── tests/                # Suíte de testes automatizados (TDD/Plenary) - 57/57 Passando
```

## Funcionalidades e Capacidades Implementadas

### 1. Swarm Architecture (Enxames de IA em Paralelo)
- **Delegação via Tech Lead**: A persona `@tech_lead` orquestra a divisão de trabalho através da tool `spawn_swarm`, passando um payload JSON com as tarefas e isolando rigorosamente quais arquivos cada sub-agente (`@coder`, `@qa`, etc) pode ler no contexto.
- **Worker Pool Inteligente**: O `swarm_manager.lua` lê as APIs disponíveis (`"allow_spawn": true`) e as usa como esteiras de produção (*workers*). Múltiplas APIs operam simultaneamente resolvendo a fila de tarefas assincronamente.
- **Carrossel de Buffers (UI)**: Sub-agentes rodam em abas invisíveis (`nofile`) dentro do mesmo *popup*. O usuário navega em tempo real com `<Tab>` e `<S-Tab>` observando as APIs digitando e invocando ferramentas no background.
- **ReAct Loop em Background**: Sub-agentes processam suas próprias ferramentas autônomas (editando, buscando) e ao finalizar, o Swarm consolida um sumário `Reduce` para o `@tech_lead` avaliar na aba principal.
- **Auto-Retry Robusto**: O motor delega tarefas com falha de Rate Limit de volta à fila sem travar a interface visual (resolvido na Fase 18 com delegação de eventos).

### 2. Persistência de Workspace Stateful (Fase 18.5)
- **Metadata Envelope (`<mctx_session>`)**: Cada sessão salva em disco recebe um ID e timestamps. Isso evita a duplicação de arquivos e mantém rastreabilidade.
- **JSON-in-XML**: Todo o estado volátil das tarefas do enxame (`M.state.queue`, buffers inativos e `reports`) é empacotado e salvo em uma tag oculta `<swarm_state>`. Quando o usuário reabre o Neovim e invoca o log, todo o Swarm ressuscita perfeitamente.

### 3. Sistema Pluggável de Skills (Fase 19)
- **Extensibilidade Local**: O `skills_manager` varre a pasta `~/.config/nvim/mctx_skills/` em busca de novos scripts `.lua`.
- **Injeção de Prompt**: O plugin gera os manuais em formato XML das funções do usuário dinamicamente e ensina a IA a utilizá-las.
- **Roteamento Seguro**: O `tool_runner` capta a invocação da nova tag de XML e roda a ferramenta do usuário através de um `pcall` (Proteção contra crashes por código mal formatado).
- **Hot-Reload Automático**: Ao enviar uma nova mensagem ou invocar `:ContextReloadSkills`, o plugin limpa a RAM e recarrega os novos scripts escritos pelo usuário em tempo real.

### 4. Sistema de Agentes Estritos (Padrão Devin/Claude Code)
- **Princípio do Menor Privilégio**: O Gatekeeper intercepta alucinações de agentes não autorizados.
- **Prevenção de Context Rot**: Regras estritas nos *system prompts* proíbem o uso de shell para ler arquivos e priorizam substituições cirúrgicas (`replace_lines`) em vez de reescritas totais.

### 5. Resiliência de Parser e Rede
- **Fechamento Implícito de Tags**: O `tool_parser.lua` força o fechamento de `<tool_call>` corrompidas.
- **Proteção de Papéis Strict (Anthropic)**: O `conversation.lua` funde textos órfãos prevenindo falhas de papéis adjacentes.
- **Fallback Automático**: O `api_client` tenta automaticamente a próxima API da fila se a primária estourar limite.

---

## Decisões Técnicas Críticas
1. **Desacoplamento de UI e Background**: O Neovim é *single-threaded* na interface, mas o motor Swarm distribui a carga via `curl` assíncrono e `vim.schedule()` mantendo a navegação do usuário fluida e a tela responsiva.
2. **Isolamento de Contexto no Swarm**: O Swarm não manda a base de código inteira para todos os sub-agentes; apenas os arquivos especificados previnindo exaustão de limites e economizando milhões de tokens.
3. **Delegation vs Execution (Skills)**: Ao usar `loadfile` e `pcall`, garantimos que extensões criadas por usuários terceiros não quebrem o Editor se possuírem erros graves de sintaxe, o erro é contido e repassado para a IA consertar.

---

## Estado Atual do Desenvolvimento

### ✅ Implementado, Estável e Testado (Fases 1 a 19)
O core do produto alcançou maturidade. 
- A Arquitetura Swarm (Enxame em Múltiplas Abas).
- O motor de Retry contra Rate Limits assíncrono.
- A Persistência de Workspace e Ressurreição de Estado (`.mctx`).
- A injeção e motor de execução de custom skills (Plugins).
- **Cobertura Testes Plenary:** 57 de 57 Sucessos absolutos.

### 🔄 Próximos Passos
1. **Refinamento do Queue Editor**: Atualizar a interface do `queue_editor.lua` para que o usuário possa ativar ou desativar a flag `"allow_spawn"` de cada API diretamente pela UI do Neovim, sem precisar editar o JSON manualmente.
2. **Ferramenta de Diff Unificado (Opcional)**: Adicionar uma skill nativa alternativa ao `replace_lines` baseada em *Unified Diff/Patch* para edições muito grandes.
3. **Revisão e Otimização do System Prompt Base**: Sintetizar as instruções nativas base para dar mais espaço de token às skills criadas pelos usuários.

---
*Última atualização: 22 de Abril de 2026 - Fase 19 (Sistema de Skills) consolidada.*
