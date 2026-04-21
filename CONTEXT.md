# MultiContext AI - Plugin Neovim

## Visão Geral
MultiContext AI é um plugin nativo para Neovim que integra assistentes de IA com capacidades autônomas (estilo Devin/Claude Code). O plugin permite interação com múltiplos agentes especializados através de uma interface de chat, com acesso direto ao sistema de arquivos, execução de terminal, loops autônomos de raciocínio (ReAct) e gerenciamento ativo de janela de contexto. Na sua versão mais recente, suporta **Swarm Architecture** (Enxames de IA), permitindo que um Tech Lead delegue tarefas em paralelo para sub-agentes trabalharem em background.

## Arquitetura Técnica

### Tecnologias Principais
- **Linguagem**: Lua (integração nativa com Neovim)
- **Framework de Testes**: `plenary.nvim` (busted)
- **Operações Assíncronas e Rede**: `vim.fn.jobstart` / `vim.fn.jobstop` abstraídos via módulo de transporte customizado (`curl` não-bloqueante).
- **Processamento de XML**: Parser funcional tolerante a falhas, com auto-fechamento implícito de tags contra alucinações.
- **Concorrência**: Implementação de *Worker Pool* nativo gerenciando Promises assíncronas do `curl` sem travar a thread principal de UI do Neovim.

### Estrutura de Diretórios
```text
lua/multi_context/
├── init.lua              # Orquestrador principal, monitoramento live de stream e hooks
├── config.lua            # Configurações, Bootstrapping de Usuário e Auto-Setup
├── agents.lua            # Inicializador do mctx_agents.json do usuário
├── api_client.lua        # Roteador de filas e fallbacks de API
├── transport.lua         # Motor de HTTP (curl), streams e cleanup de temp files
├── prompt_parser.lua     # Parser de intenções e Montador Dinâmico de Prompts
├── tool_parser.lua       # Extrator funcional e sanitizador de tags XML (Auto-close)
├── tool_runner.lua       # Gatekeeper de Permissões, executor e injetor de LSP
├── swarm_manager.lua     # Cérebro do Enxame: gerencia filas, workers, auto-retry e ReAct background
├── react_loop.lua        # Gerenciador de estado de sessão e Circuit Breaker
├── context_builders.lua  # Extratores de contexto injetando numeração de linhas estrita (1 | code)
├── tools.lua             # Ferramentas nativas (leitura, edição, bash, LSP)
├── ui/
│   ├── popup.lua         # Lógica da janela flutuante, carrossel de buffers e atalhos
│   ├── scroller.lua      # Smart Auto-Scroll silencioso e rastreador direcional
│   └── highlights.lua    # Highlights sintáticos customizados
└── tests/                # Suíte de testes automatizados (TDD/Plenary)
```

## Funcionalidades e Capacidades Implementadas

### 1. Swarm Architecture (Enxames de IA em Paralelo) 🆕
- **Delegação via Tech Lead**: A persona `@tech_lead` orquestra a divisão de trabalho através da tool `spawn_swarm`, passando um payload JSON com as tarefas e isolando rigorosamente quais arquivos cada sub-agente (`@coder`, `@qa`, etc) pode ler no contexto.
- **Worker Pool Inteligente**: O `swarm_manager.lua` lê as APIs disponíveis (`"allow_spawn": true`) e as usa como esteiras de produção (*workers*). Múltiplas APIs operam simultaneamente resolvendo a fila de tarefas assincronamente.
- **Carrossel de Buffers (UI)**: Sub-agentes rodam em abas invisíveis (`nofile`) dentro do mesmo *popup*. O usuário navega em tempo real com `<Tab>` e `<S-Tab>` observando as APIs digitando e invocando ferramentas no background.
- **ReAct Loop em Background**: Sub-agentes processam suas próprias ferramentas autônomas (editando, buscando) e ao finalizar, o Swarm consolida um sumário `Reduce` para o `@tech_lead` avaliar na aba principal.

### 2. Sistema de Agentes Estritos (Padrão Devin/Claude Code)
- **Princípio do Menor Privilégio**: O Gatekeeper intercepta alucinações de agentes não autorizados.
- **Prevenção de Context Rot**: Regras estritas nos *system prompts* proíbem o uso de shell para ler arquivos e priorizam substituições cirúrgicas (`replace_lines`) em vez de reescritas totais. A numeração de linhas (`12 | código`) é injetada nos leitores de contexto para garantir precisão nas edições.

### 3. Resiliência de Parser e Rede (Fase 17)
- **Fechamento Implícito de Tags**: O `tool_parser.lua` força o fechamento de `<tool_call>` corrompidas.
- **Proteção de Papéis Strict (Anthropic)**: O `conversation.lua` funde textos órfãos prevenindo falhas de papéis adjacentes (*user/assistant*).
- **Fallback Automático**: O `api_client` tenta automaticamente a próxima API da fila se a primária estourar limite.

---

## Decisões Técnicas Críticas
1. **Desacoplamento de UI e Background**: O Neovim é *single-threaded* na interface, mas o motor Swarm distribui a carga via `curl` assíncrono mantendo a navegação do usuário fluida e a tela responsiva.
2. **Isolamento de Contexto no Swarm**: O Swarm **não** manda a base de código inteira para todos os sub-agentes; apenas os arquivos especificados no JSON pelo Tech Lead, o que previne exaustão de *Rate Limits* e economiza milhões de tokens.

---

## Estado Atual do Desenvolvimento

### ✅ Implementado e Funcionando (Fase 18 - Swarm)
- O fluxo completo de parsing JSON da tool `spawn_swarm`.
- A criação dinâmica do Carrossel de Buffers na UI (`popup.lua`).
- A injeção de *workers* baseados nas APIs marcadas com `"allow_spawn": true` no config.
- A distribuição assíncrona das tarefas (*Map*) e o recolhimento das respostas finais no Main Buffer (*Reduce*).
- O loop de execução de ferramentas (ReAct) autônomo dentro de cada aba do sub-agente.

### ⚠️ Em Andamento (O Que Não Está Funcionando)
Na finalização da **Fase 18**, implementamos a lógica de *Auto-Retry* (para devolver tarefas à fila quando a API retorna erro de "Rate Limit" ou string vazia) e o cálculo dinâmico de tokens no Título da Janela. 

A suíte `swarm_etapa5_spec.lua` detectou que o estado do `swarm_manager` não está atualizando a fila corretamente após a falha, e o título está quebrando nos testes *headless*. Abaixo está o log de erro atual que precisa ser resolvido no próximo chat:

```text
========================================
Testing:        /home/nardi/repos/multi_context_plugin/lua/multi_context/tests/swarm_etapa5_spec.lua
Fail    ||      Swarm Etapa 5 - Resiliência e UI Dinâmica: Deve realizar retry de uma tarefa se a API retornar string vazia
            ...ext_plugin/lua/multi_context/tests/swarm_etapa5_spec.lua:43: A tarefa deve voltar para a fila
            Expected objects to be the same.
            Passed in:
            (number) 0
            Expected:
            (number) 1

            stack traceback:
                ...ext_plugin/lua/multi_context/tests/swarm_etapa5_spec.lua:43: in function <...ext_plugin/lua/multi_context/tests/swarm_etapa5_spec.lua:32>

Fail    ||      Swarm Etapa 5 - Resiliência e UI Dinâmica: Deve realizar retry de uma tarefa se a API retornar erro HTTP (Rate Limit)
            ...ext_plugin/lua/multi_context/tests/swarm_etapa5_spec.lua:67: A tarefa deve voltar para a fila apos erro
            Expected objects to be the same.
            Passed in:
            (number) 0
            Expected:
            (number) 1

            stack traceback:
                ...ext_plugin/lua/multi_context/tests/swarm_etapa5_spec.lua:67: in function <...ext_plugin/lua/multi_context/tests/swarm_etapa5_spec.lua:58>

Fail    ||      Swarm Etapa 5 - Resiliência e UI Dinâmica: Deve atualizar o titulo do Carrossel e calcular tokens dinamicamente
            ...ext_plugin/lua/multi_context/tests/swarm_etapa5_spec.lua:94: attempt to call method 'match' (a nil value)

            stack traceback:
                ...ext_plugin/lua/multi_context/tests/swarm_etapa5_spec.lua:94: in function <...ext_plugin/lua/multi_context/tests/swarm_etapa5_spec.lua:81>

Success ||      Swarm Etapa 5 - Resiliência e UI Dinâmica: Deve confirmar a presença do agente @qa no acervo

Success:        1
Failed :        3
Errors :        0
========================================
```

### 🔄 Próximos Passos
1. **Consertar a lógica de *Retry*** no `swarm_manager.lua`, garantindo que as tarefas efetivamente voltem para a fila (`M.state.queue`) quando a API falhar por limite de taxa (Rate Limit) ou retornar uma string vazia.
2. **Proteger a leitura do título (`nil`)** na função `update_title` do `popup.lua`, para que o teste *headless* não quebre ao tentar chamar o método `match()` em valores vazios durante a validação da UI.
3. **Iniciar a Fase 19 (Extensibilidade)**: Criação do sistema de Plugins de Skills, permitindo que usuários definam pastas customizadas em suas configurações locais (`~/.config/nvim/mctx_skills`) onde o plugin buscará automaticamente novos scripts `.lua` e manuais `.md`, tornando-o plugável sem alterar o core.
4. **Refinamento do Queue Editor**: Atualizar a interface do `queue_editor.lua` para que o usuário possa ativar ou desativar a flag `"allow_spawn"` de cada API diretamente pela UI do Neovim, sem precisar editar o JSON manualmente.
5. **Ferramenta de Diff Unificado (Opcional)**: Adicionar uma skill alternativa ao `replace_lines` baseada em *Unified Diff/Patch* para edições muito grandes, que costumam confundir a IA com números de linha.

---
*Última atualização: 20 de Abril de 2026 - Fase 18 (Swarm Architecture) core implementado e testado. Pendente estabilização dos testes de resiliência e Auto-Retry da Etapa 5.*
