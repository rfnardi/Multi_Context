# 🤖 MultiContext AI - Neovim Plugin

![Neovim](https://img.shields.io/badge/Neovim-0.8+-green.svg?style=for-the-badge&logo=neovim)
![Lua](https://img.shields.io/badge/Lua-100%25-blue.svg?style=for-the-badge&logo=lua)
![License](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)

## 📖 Visão Geral

**MultiContext AI** é um plugin nativo, assíncrono e de alto desempenho para Neovim que integra assistentes de Inteligência Artificial **autônomos** diretamente no editor (inspirado no paradigma do *Claude Code* e *Devin*). 

Diferente de plugins convencionais de autocompletar, o MultiContext atua como um engenheiro de software: ele navega no sistema, edita arquivos em background, roda testes no terminal e se auto-corrige usando um motor de raciocínio ReAct (Reasoning and Acting).

> **Objetivo:** Acelerar o fluxo de trabalho permitindo que a IA construa, teste e valide código de ponta a ponta, com consumo extremamente otimizado de tokens de contexto.

---

## 🚀 Funcionalidades Principais

| ✅ | Funcionalidade | Descrição |
|:---:|---|---|
| 🥷 | **Arquitetura de Skills** | Agentes seguem o Princípio do Menor Privilégio. O `@arquiteto` não consegue acidentalmente rodar o bash, bloqueado pelo Gatekeeper nativo. |
| 🧩 | **Mini-Manuais Dinâmicos** | O prompt de sistema concatena a documentação `.md` apenas das habilidades autorizadas do agente, economizando centenas de tokens. |
| 🔄 | **Motor Autônomo (ReAct)** | A IA encadeia ferramentas sozinha (flag `--auto`) com um *Circuit Breaker* de segurança de 15 iterações. |
| ⚡ | **Prompt Caching Nativo** | Cache de contexto em servidores (Anthropic, DeepSeek, OpenAI) reduzindo custos draconianamente. |
| 🔍 | **LSP Smart Push (Auto-LSP)** | Se a IA quebrar a sintaxe de um código, o plugin corta a execução na raiz, lê o erro do Neovim e força a IA a consertar imediatamente. |
| 📜 | **Smart Auto-Scroll** | O texto desce automaticamente, mas **pausa silenciosamente** se você mover o cursor para cima para ler o histórico, retomando no final do buffer. |
| 🛑 | **Job Control (Pânico)** | Pressione `<C-x>` a qualquer momento para assassinar a conexão com a API via `jobstop`. |
| 🧠 | **Memória de Longo Prazo** | O arquivo `CONTEXT.md` atualiza e persiste decisões, atuando como "cérebro" do projeto. |
| 🗑️ | **Garbage Collection Ativa** | Comprime buffers gigantes jogando fora logs inúteis para salvar memória (`:ContextUndo` suportado). |

---

## 📦 Instalação e Bootstrapping

O MultiContext possui **Auto-Setup**. Ao rodar pela primeira vez, ele criará todos os arquivos base de configuração na sua pasta `~/.config/nvim/` sem tocar no código-fonte original, garantindo atualizações seguras via GitHub.

### Requisitos do Sistema
- **Neovim 0.8+** (Para a API `vim.diagnostic` e float windows).
- `curl` (Para requisições HTTP não-bloqueantes).
- `git` e `tree` (Ferramentas base de extração de contexto).

### Instalando com `vim-plug` (Recomendado)

Adicione no seu `init.vim` ou gerenciador de plugins:
```vim
Plug 'seu-usuario/multi_context_plugin'
```

*Dica para Desenvolvimento:* Se o plugin estiver local, aponte a pasta:
```vim
Plug '~/repos/multi_context_plugin' 
```

Rode `:PlugInstall` e adicione o *setup*:

```lua
require('multi_context').setup({
  user_name = "Nardi", -- Seu nome no chat
})
```

---

## ⚙️ Configuração (Onboarding Automático)

No primeiro uso, o plugin gerará 3 arquivos na pasta `stdpath("config")` (geralmente `~/.config/nvim/`):

1. **`api_keys.json`**: Insira suas chaves (OpenAI, Anthropic, Gemini, DeepSeek).
2. **`context_apis.json`**: Cadastre os endpoints e parâmetros dos seus modelos favoritos. Alterne entre eles via comando `:ContextApis`.
3. **`mctx_agents.json`**: Crie e customize seus próprios agentes e distribua permissões no array `"skills"`.

---

## 🎮 Comandos (Modo Normal e Visual)

| Comando | Descrição |
|---|---|
| `:ContextChatFull` | Abre o chat vazio ou retoma o workspace ativo. |
| `:'<,'>Context` | *(Visual)* Envia as linhas selecionadas para o chat. |
| `:ContextFolder` | Inicia a sessão enviando os arquivos do diretório atual. |
| `:ContextRepo` | Inicia a sessão mapeando todo o projeto do Git. |
| `:ContextGit` | Envia as alterações não commitadas (`git diff`). |
| `:ContextBuffers`| Envia todos os buffers de código carregados no Neovim. |
| `:ContextTree` | Desenha a árvore do projeto no prompt. |
| `:ContextUndo` | Restaura o buffer de chat após uma compressão destrutiva. |
| `:ContextToggle` | Abre ou esconde a janela flutuante sem perder o histórico. |

---

## ⌨️ UX e Atalhos do Chat

| Atalho | Modo | Ação |
|---|---|---|
| **`<CR>` / `<C-CR>`** | Insert/Normal | Envia a mensagem e invoca a IA. |
| **`@`** | Insert | Abre o menu flutuante para invocar um Agente (`@coder`, `@qa`). |
| **`<C-x>`** | Insert/Normal | 🛑 **Botão de Pânico:** Corta a conexão HTTP e interrompe o stream. |
| **`<A-b>`** | Insert/Normal | Copia o último bloco de código para a área de transferência. |
| **`k` / `<C-u>`** | Normal | Pausa o Auto-Scroll direcionalmente para ler histórico. |
| **`G`** | Normal | Retoma a leitura da última linha engatando o Auto-Scroll. |

> **Modo Manual vs `--auto`:** Se a IA sugerir edição/shell sem a flag `--auto`, o Neovim exigirá sua confirmação em uma janela limpa `[Sim/Não/Todos]`. Com `--auto`, o loop funciona 100% invisível em background.

---

## 🏗️ Estrutura de Módulos (OSS Design)

Totalmente reescrito na Fase 13 para respeitar *Single Responsibility Principle (SRP)*:

```text
lua/multi_context/
├── init.lua              # Monitoramento live e hooks de UI
├── api_client.lua        # HTTP Assíncrono com injeção de Job_ID
├── prompt_parser.lua     # Extrator de intenções e Montador JIT de Habilidades
├── tool_runner.lua       # Gatekeeper de Segurança e Injetor de LSP
├── react_loop.lua        # Gerente de Sessão (Circuit Breaker e Job Abort)
├── skills/               # Cartões modulares (.md) e Registry de permissões
└── ui/                   # Smart Auto-Scroll e Popups
```

---

## 🧪 Testes Automatizados (TDD)

O plugin é coberto por testes robustos usando `plenary.nvim`. As lógicas textuais e matemáticas (Race Conditions de cursor) rodam de forma independente do editor visual.
```bash
make test
```

---

## 📜 Licença

Desenvolvido para hackers e entusiastas do Neovim. Licenciado sob a **MIT License** – veja o arquivo `LICENSE` para detalhes.
