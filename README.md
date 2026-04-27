![Neovim](https://img.shields.io/badge/Neovim-0.8+-green.svg?style=for-the-badge&logo=neovim)
![Lua](https://img.shields.io/badge/Lua-100%25-blue.svg?style=for-the-badge&logo=lua)
![Release](https://img.shields.io/badge/Version-v1.3--Final-blue.svg?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)

## 📖 Visão Geral

**MultiContext AI** é um plugin nativo, assíncrono e de alto desempenho para Neovim que integra assistentes de Inteligência Artificial **autônomos** diretamente no editor (inspirado no paradigma do *Claude Code* e *Devin*). 

Diferente de plugins convencionais de autocompletar, o MultiContext atua como um engenheiro de software de ponta: ele navega no sistema usando **LSP e Ripgrep**, edita arquivos cirurgicamente via Unified Diff, roda testes no terminal, e encerra seu trabalho realizando Commits Semânticos puros usando a persona **@devops**.

Tudo isso suportado por uma arquitetura multithread paralela **Swarm (Enxames)** e governado por um **Centro de Comando Master** virtual no seu Neovim.

---

## 🚀 O Poder do Engenheiro Autônomo

| Ícone | Funcionalidade | Descrição |
|:---:|---|---|
| 🎛️ | **Centro de Comando (Virtual UI)** | Painel centralizado (`:ContextControls`) com *Footer Dinâmico*. Controle APIs, Telemetria, Watchdog, crie Injetores ou gerencie Permissões (IAM) na ponta do teclado. |
| 🧩 | **Context Injectors (`\`)** | Componha prompts num menu fuzzy vivo. Injeta a Árvore de Arquivos, Erros do LSP global, etc., preservando seu texto. |
| 🐝 | **Swarm Architecture** | O `@tech_lead` invoca equipes (@coder, @qa, @devops) que operam num carrossel paralelo assíncrono navegável via `<Tab>`. |
| 🛡️ | **Context Watchdog 2.0** | Um rastreador preditivo (EMA) monitora tokens. Se estourar, o `@archivist` realiza Compressão Quadripartite via XML. |
| 🔍 | **Navegação LSP & Ripgrep** | Abandonamos o RAG ruidoso. A IA rastreia o código com `rg` super-rápido e pula em funções via **Go To Definition** usando o próprio LSP do Neovim para economia máxima de tokens. |
| 👨‍💻 | **Automação Git (@devops)** | Ao final do trabalho, a IA cria a branch e dá `git commit` nos arquivos específicos através de uma barreira estrita de segurança Gatekeeper. |
| 🔌 | **Extensibilidade Polyglot** | Ensine habilidades customizadas (ex: Pytest, Jira, Bancos de Dados) escrevendo scripts na sua linguagem favorita e acoplando à IA. |

---

## 📦 Instalação e Bootstrapping (Lazy.nvim)

O MultiContext possui **Auto-Setup**. Ao rodar pela primeira vez, ele criará todos os arquivos base de configuração isoladamente em `~/.config/nvim/`.

```lua
{
    "seu-usuario/multi_context_plugin",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
        user_name = "Seu Nome",
    },
    keys = {
        { "<leader>mc", "<cmd>ContextToggle<cr>", desc = "Toggle MultiContext Chat" },
        { "<leader>mp", "<cmd>ContextControls<cr>", desc = "Painel de Comando" },
    }
}
```

> **Dica**: Logo após instalar, rode `:help multicontext` para abrir o manual rico do Neovim.

---

## 🧪 Testes Automatizados e Confiabilidade (TDD)

O motor do plugin foi desenvolvido estritamente sob TDD e mantido sob resiliência militar (**113 testes isolados passando 100%**).
```bash
make test_agregate_results
```
