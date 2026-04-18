# MultiContext AI - Plugin Neovim

## Visão Geral
MultiContext AI é um plugin nativo para Neovim que integra assistentes de IA com capacidades autônomas (estilo Devin/Claude Code). O plugin permite interação com múltiplos agentes especializados através de uma interface de chat, com acesso direto ao sistema de arquivos, execução de terminal, loops autônomos de raciocínio (ReAct) e gerenciamento ativo de janela de contexto.

## Arquitetura Técnica

### Tecnologias Principais
- **Linguagem**: Lua (integração nativa com Neovim)
- **Framework de Testes**: `plenary.nvim` (busted)
- **Operações Assíncronas**: `vim.fn.jobstart` e `vim.fn.jobstop` (HTTP não-bloqueante e controle de stream)
- **Processamento de XML**: Parser funcional tolerante a falhas.

### Estrutura de Diretórios
```text
lua/multi_context/
├── init.lua              # Orquestrador principal, monitoramento live de stream e hooks
├── config.lua            # Configurações, Bootstrapping de Usuário e Auto-Setup
├── agents.lua            # Inicializador do mctx_agents.json do usuário
├── api_client.lua        # Cliente HTTP, fila de APIs e injeção de job_id
├── api_handlers.lua      # Manipuladores de requisição nativos
├── prompt_parser.lua     # Parser de intenções e Montador Dinâmico de Prompts (Lego)
├── tool_parser.lua       # Extrator funcional e sanitizador de tags XML/JSON
├── tool_runner.lua       # Gatekeeper de Permissões, executor e injetor de LSP
├── react_loop.lua        # Gerenciador de estado de sessão e Abort de Jobs
├── api_selector.lua      # UI de seleção de API
├── commands.lua          # Rotas de comandos do Neovim
├── conversation.lua      # Motor de reconstrução de histórico
├── context_builders.lua  # Extratores de contexto com proteção OOM (>100kb/Binários)
├── tools.lua             # Ferramentas nativas (leitura, edição, bash, LSP)
├── utils.lua             # Utilitários e exportação isolada de Workspace (.mctx_chats)
├── skills/
│   ├── registry.lua      # Dicionário de habilidades e montador de manual
│   └── docs/             # Instruções modulares em Markdown (.md) para cada ferramenta
├── ui/
│   ├── scroller.lua      # Smart Auto-Scroll silencioso e rastreador direcional
│   ├── popup.lua         # Lógica da janela flutuante e atalhos de emergência (<C-x>)
│   └── highlights.lua    # Highlights sintáticos customizados
└── tests/                # Suíte de testes automatizados (TDD/Plenary)
```

## Funcionalidades e Capacidades Implementadas

### 1. Sistema de Agentes e Arquitetura de Skills 🆕
- **Princípio do Menor Privilégio**: O sistema abandonou o modelo de "Ferramentas Globais". Agora os agentes possuem arrays de `skills` (`"list_files"`, `"run_shell"`, etc).
- **Gatekeeper de Segurança**: Se um agente tentar alucinar ou usar uma ferramenta fora do seu escopo, o `tool_runner.lua` intercepta o comando, bloqueia a execução e alerta a IA (`Operação negada`).
- **Token Saver Dinâmico**: O manual de ferramentas não é mais uma string monolítica. O sistema lê os arquivos `.md` modulares apenas das skills autorizadas e constrói um "Mini-Manual" JIT (Just-in-Time), economizando centenas de tokens no System Prompt.

### 2. Experiência do Usuário (Onboarding) 🆕
- **Auto-Setup e Bootstrapping**: O código-fonte do plugin foi totalmente isolado das configurações de usuário. Ao instalar o plugin, o `config.lua` gera automaticamente arquivos de fallback (`api_keys.json`, `context_apis.json` e `mctx_agents.json`) na pasta local do usuário (`~/.config/nvim/`), garantindo atualizações seguras sem perder customizações pessoais.
- **Backward Compatibility**: Script interno garante a migração silenciosa de agentes antigos (booleano `use_tools`) para o novo paradigma de `skills` estruturadas.

### 3. Loop Autônomo, ReAct e Job Control
- **Controle de Stream (`<C-x>`)**: Atalho de emergência para assassinar requisições alucinadas (`vim.fn.jobstop`).
- **Auto-Halt Inteligente**: Se a IA executa uma ferramenta de mutação (`edit_file`, `run_shell`), a geração HTTP é cortada na raiz no exato fechamento da tag, prevenindo encadeamento de código quebrado.

### 4. Integração LSP — Smart Push (Fase 2)
- Captura transparente de diagnóstico LSP no modo `--auto`, injetado como [Auto-LSP] nas respostas de sucesso, forçando a IA a consertar o que acabou de quebrar sem consumir turnos extras requisitando o leitor.

### 5. Smart Auto-Scroll Silencioso
- A rolagem acompanha a IA digitando, mas **pausa** direcionalmente ao identificar que o usuário moveu o cursor para cima, e **retoma** se ele voltar para a última linha (`G`).

### 6. Memória de Longo Prazo e Prompt Caching ⚡
- Leitura do `CONTEXT.md` cacheada em servidores (DeepSeek/Anthropic/OpenAI), com economia notificada via UI.

## Decisões Técnicas Críticas (Registro para Agentes)
1. **Desacoplamento e SRP**: `init.lua` esvaziado. Uso de módulos puros (`tool_parser`, `prompt_parser`).
2. **Separação de Lógica e Engenharia de Prompt**: O core Lua não possui strings massivas de documentação. O treinamento da IA fica em arquivos `.md` soltos na pasta `/skills/docs/`. Para criar uma nova skill, basta criar o script Lua, o arquivo Markdown, e autorizar a IA no JSON.
3. **Bootstrapping Isolado**: A persistência de estado do usuário (APIs e Agentes) está externalizada para `stdpath("config")`. O plugin em si pode ser apagado e clonado via GitHub sem perda de dados (Design profissional de OSS).

---

## Estado Atual do Desenvolvimento

### ✅ Concluído (Fases 1 a 16)
- Loop ReAct, Arquitetura de UI e OOM protection.
- Suíte de testes TDD/PlenaryBusted.
- Integração LSP e Otimização via Prompt Caching.
- **Smart Auto-Scroll sem travamentos** (Fase 14).
- **LSP Smart Push e Job Control/Abort `<C-x>`** (Fase 15).
- **Arquitetura de Skills, Gatekeeper de Segurança e Onboarding OSS** (Fase 16).

### 🔄 Próximos Passos
1. **Padronização DRY no `api_handlers.lua`**: Abstrair a rotina de requests `curl` em um construtor genérico.
2. **Sistema de Plugins Externos**: Repositório comunitário para download de novas Skills (`.md` + `.lua`) para injeção via config.

---
*Última atualização: 2026-04-18 - Fase 16 concluída (Arquitetura de Skills e Onboarding/Isolamento de Repo).*
