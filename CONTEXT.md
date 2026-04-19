# CONTEXT.md Atualizado

# MultiContext AI - Plugin Neovim

## Visão Geral
MultiContext AI é um plugin nativo para Neovim que integra assistentes de IA com capacidades autônomas (estilo Devin/Claude Code). O plugin permite interação com múltiplos agentes especializados através de uma interface de chat, com acesso direto ao sistema de arquivos, execução de terminal, loops autônomos de raciocínio (ReAct) e gerenciamento ativo de janela de contexto.

## Arquitetura Técnica

### Tecnologias Principais
- **Linguagem**: Lua (integração nativa com Neovim)
- **Framework de Testes**: `plenary.nvim` (busted)
- **Operações Assíncronas e Rede**: `vim.fn.jobstart` / `vim.fn.jobstop` abstraídos via módulo de transporte customizado (`curl` não-bloqueante).
- **Processamento de XML**: Parser funcional tolerante a falhas, com auto-fechamento implícito de tags contra alucinações.

### Estrutura de Diretórios
```text
lua/multi_context/
├── init.lua              # Orquestrador principal, monitoramento live de stream e hooks
├── config.lua            # Configurações, Bootstrapping de Usuário e Auto-Setup
├── agents.lua            # Inicializador do mctx_agents.json do usuário
├── api_client.lua        # Roteador de filas e fallbacks de API
├── api_handlers.lua      # Definição de payloads e parsers específicos por Provedor
├── transport.lua         # Motor de HTTP (curl), streams e cleanup de temp files
├── prompt_parser.lua     # Parser de intenções e Montador Dinâmico de Prompts
├── tool_parser.lua       # Extrator funcional e sanitizador de tags XML (Auto-close)
├── tool_runner.lua       # Gatekeeper de Permissões, executor e injetor de LSP
├── react_loop.lua        # Gerenciador de estado de sessão (Circuit Breaker)
├── api_selector.lua      # UI de seleção de API (flutuante)
├── queue_editor.lua      # UI iterativa para reordenação de fallbacks de API
├── commands.lua          # Rotas de comandos do Neovim
├── conversation.lua      # Motor de reconstrução de histórico (Merge de papéis rígidos)
├── context_builders.lua  # Extratores de contexto com proteção OOM (>100kb/Binários)
├── tools.lua             # Ferramentas nativas (leitura, edição, bash, LSP)
├── utils.lua             # Utilitários e exportação isolada de Workspace (.mctx_chats)
├── skills/
│   ├── registry.lua      # Dicionário de habilidades e montador de manual
│   └── docs/             # Instruções modulares em Markdown (.md) para cada ferramenta
├── ui/
│   ├── scroller.lua      # Smart Auto-Scroll silencioso e rastreador direcional
│   ├── popup.lua         # Lógica da janela flutuante e atalhos de emergência
│   └── highlights.lua    # Highlights sintáticos customizados
└── tests/                # Suíte de testes automatizados (TDD/Plenary)
```

## Funcionalidades e Capacidades Implementadas

### 1. Sistema de Agentes e Arquitetura de Skills
- **Princípio do Menor Privilégio**: O sistema usa arrays de `skills` (`"list_files"`, `"run_shell"`, etc). O Gatekeeper intercepta alucinações de agentes não autorizados.
- **Mini-Manuais JIT**: O prompt constrói a documentação do agente lendo apenas os `.md` das habilidades permitidas, salvando milhares de tokens.

### 2. Resiliência de Parser e Conversação (Fase 17) 🆕
- **Fechamento Implícito de Tags**: O `tool_parser.lua` agora detecta quando a IA tenta abrir uma nova `<tool_call>` sem fechar a anterior, forçando o fechamento implícito e prevenindo crash em loops autônomos longos.
- **Proteção de Papéis Strict (Anthropic)**: O `conversation.lua` funde textos órfãos (como saídas de comandos `:ContextGit`) diretamente na mensagem do `user` e previne mensagens adjacentes do mesmo papel, atendendo aos requisitos rígidos da API da Anthropic.

### 3. Camada de Rede Abstraída (DRY) 🆕
- A rotina de `curl`, geração de arquivos temporários e extração de chunks JSON foi extraída do `api_handlers.lua` para o `transport.lua`. Cada provedor (OpenAI, Anthropic, Gemini, Cloudflare) agora apenas define o "shape" do payload, tornando a adição de novas APIs trivial.

### 4. Experiência do Usuário (Onboarding)
- **Auto-Setup**: Geração de `api_keys.json`, `context_apis.json` e `mctx_agents.json` em `stdpath("config")`. Isolamento total de repo OSS.
- **Fallback Automático**: Fila de APIs estruturada. Se a IA primária falhar (ex: rate limit), o sistema tenta automaticamente as fallback APIs (via `api_client.lua`).

### 5. Loop Autônomo, Auto-LSP e Job Control
- **Controle de Stream (`<C-x>`)**: Atalho para `jobstop`.
- **Auto-LSP (Smart Push)**: Injeção de diagnósticos nas respostas de sucesso para forçar correção imediata sem gastar turnos pedindo leitura.
- **Auto-Halt**: O HTTP stream é cortado na raiz assim que uma ferramenta de mutação é fechada.

### 6. Memória de Longo Prazo e Prompt Caching ⚡
- Leitura do `CONTEXT.md` cacheada em servidores (DeepSeek/Anthropic), com telemetria notificada via UI.

## Decisões Técnicas Críticas (Registro para Agentes)
1. **Desacoplamento e SRP**: `init.lua` é apenas um ponto de montagem. O núcleo reside em módulos puros.
2. **Separação de Lógica e Engenharia de Prompt**: O treinamento da IA fica em arquivos `.md` soltos na pasta `/skills/docs/`.
3. **Bootstrapping Isolado**: A persistência de estado do usuário está externalizada (`~/.config/nvim/`). O plugin OSS não guarda estado interno.
4. **Arquitetura de Transporte Centralizada**: Requisições HTTP são gerenciadas por `transport.lua`, que escreve payloads massivos em disco (`os.tmpname()`) e usa `curl @file` para evitar problemas de escape de shell limitados do Neovim.

---

## Estado Atual do Desenvolvimento

### ✅ Concluído (Fases 1 a 17)
- Loop ReAct, Auto-LSP e OOM protection.
- Suíte de testes TDD/PlenaryBusted (cobertura robusta em lógica).
- Arquitetura de Skills e Onboarding OSS.
- **Refatoração da Camada de Rede (DRY)**: Criação do `transport.lua` limpando a redundância de `curl`.
- **Resiliência do Parser**: Fechamento implícito de tags e tratamento seguro de histórico restrito (Anthropic Role Validation).

### 🔄 Próximos Passos (Fase 18+)
1. **Sistema de Plugins de Skills (Extensibilidade)**: Permitir que usuários definam uma pasta customizada em suas configurações locais (`~/.config/nvim/mctx_skills`) onde o plugin buscará automaticamente novos `.lua` e `.md`, tornando-o plugável sem alterar o core.
2. **Refinamento do Queue Editor**: Garantir que o `queue_editor.lua` tenha um atalho exposto como comando e funcione fluentemente para criar/remover provedores via UI do Neovim.
3. **Ferramenta de Diff Unificado (Opcional)**: Adicionar uma skill alternativa ao `replace_lines` baseada em Unified Diff/Patch para edições muito grandes que costumam confundir a IA com números de linha.

---
*Última atualização: [19/Abril/2026] - Fase 17 concluída (Refatoração de Rede `transport.lua` e Estabilização de Parsers XML/Conversação).*
