![Neovim](https://img.shields.io/badge/Neovim-0.8+-green.svg?style=for-the-badge&logo=neovim)
![Lua](https://img.shields.io/badge/Lua-100%25-blue.svg?style=for-the-badge&logo=lua)
![Release](https://img.shields.io/badge/Version-v1.2-blue.svg?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)

## 📖 Visão Geral

**MultiContext AI** é um plugin nativo, assíncrono e de alto desempenho para Neovim que integra assistentes de Inteligência Artificial **autônomos** diretamente no editor (inspirado no paradigma do *Claude Code* e *Devin*). 

Diferente de plugins convencionais de autocompletar, o MultiContext atua como um engenheiro de software: ele navega no sistema, edita arquivos em background, roda testes no terminal, delega tarefas para enxames (Swarms) em abas paralelas e se auto-corrige usando um motor de raciocínio ReAct (Reasoning and Acting). Todo esse ecossistema é orquestrado por um **Centro de Comando Centralizado (Virtual UI)** que coloca o poder da IDE na ponta dos seus dedos.

> **Objetivo:** Acelerar o fluxo de trabalho permitindo que a IA construa, teste e valide código de ponta a ponta, com consumo extremamente otimizado de tokens de contexto, governança de custos e alta resiliência a falhas de rede.

---

## 🚀 Funcionalidades Principais

| Ícone | Funcionalidade | Descrição |
|:---:|---|---|
| 🎛️ | **Centro de Comando (Virtual UI)** | Painel centralizado (`:ContextControls`) dividido em 12 seções expansíveis (`[+]`/`[-]`). Controle APIs, aparência (`width/border`), telemetria, crie Injetores ou gerencie Personas. Possui um *Footer Dinâmico* (ancorado na janela) que ensina atalhos ao vivo baseados na posição do seu cursor. |
| 🧩 | **Context Injectors (`\`)** | Componha prompts como um lego. Digite `\` no chat para abrir um menu fuzzy e injetar *buffers abertos*, *git diffs*, ou a *árvore de arquivos*. Suporta criação de Injetores Polyglot (Lua, Bash, Python) em 1 clique pelo painel. |
| 🐝 | **Swarm Architecture** | O agente `@tech_lead` invoca múltiplos sub-agentes (Coder, QA) para trabalharem paralelamente num carrossel dinâmico de abas em background. |
| 🧠 | **Cognitive Routing (MoA)** | O sistema distribui tarefas avaliando o custo/benefício (High/Medium/Low), roteando tasks simples para APIs baratas e caras para complexas. Configurável e mutável diretamente pelo painel de controle visual. |
| 🛡️ | **Context Watchdog 2.0** | Um rastreador preditivo (EMA) monitora a janela do chat. Se ameaçar estourar, invoca o `@archivist` usando motores **Semântico, Percentual ou Fixo** encapsulando a memória em XML Quadripartite. |
| 🎖️ | **Esquadrões (Squads)** | Invoque equipes inteiras mencionando `@squad_nome`. Configure esteiras de produção e visualize a *chain* hierárquica direto pelo painel de controle. |
| 🔐 | **Cofre & Master Prompt** | Verifique se suas `api_keys.json` estão faltando ou configuradas (`[ ✓ ]`) sem expor os segredos, e reescreva o Prompt de Sistema Root da Inteligência Artificial em um clique. |
| 🔌 | **Extensibilidade Pluggável** | Crie scripts Lua locais (`mctx_skills/`) e ensine habilidades customizadas (ex: Jira, SQL) com Auto-Hot-Reload na arquitetura. |
| 💾 | **Workspace Stateful** | Feche o Neovim a qualquer momento. O painel lista os últimos `.mctx` da pasta do projeto. Dê `<CR>` para ressuscitar a fila assíncrona e todas as abas. |
| 🥷 | **Arquitetura de Permissões** | Agentes seguem o Princípio do Menor Privilégio. O Gatekeeper permite ligar/desligar skills, deletar agentes e editar o System Prompt de cada persona em um buffer isolado seguro com Auto-Save. |
| 🔄 | **Fallback de APIs Inteligente** | Se a sua API principal falhar (Rate Limit), o plugin tenta automaticamente a próxima API da sua fila visível no painel. |

---

## 🔌 Provedores Suportados (Zero Dependências)
O plugin possui uma camada nativa de transporte HTTP (`curl`) super otimizada, com suporte nativo e tratamento rigoroso de formato para:
- **Anthropic** (Claude 3.5 Sonnet) - *Com suporte nativo a Strict Role Enforcement & Prompt Caching*
- **OpenAI** (GPT-4o / o1)
- **DeepSeek** (Coder V2 / V3)
- **Google Gemini**
- **Cloudflare AI**

---

## 🛠️ Extensibilidade Dupla: Skills e Injectors

O MultiContext divide a personalização do usuário em duas frentes, com opções de edição instantânea pelo painel apertando a tecla `e`.

### 1. Criando Skills (Ferramentas para a IA)
Acesse `:ContextControls` e pressione `<CR>` em `[+ Criar Nova Skill]`. Ela será salva em `~/.config/nvim/mctx_skills/`.
```lua
return {
    name = "consulta_sql",
    description = "Executa uma query no banco local do projeto",
    parameters = { { name = "query", type = "string", required = true } },
    execute = function(args) return vim.fn.system("sqlite3 db.db '" .. args.query .. "'") end
}
```

### 2. Criando Context Injectors (Macros para você)
Blocos de texto dinâmicos para injetar nos seus prompts usando a tecla `\`. Crie via painel e eles irão para a pasta `~/.config/nvim/mctx_injectors/`.
```lua
return {
    name = "git_log",
    description = "Injeta os últimos 10 commits na janela de chat",
    execute = function()
        return "=== COMMITS ===\n" .. vim.fn.system("git log -n 10 --oneline")
    end
}
```

---

## 📦 Instalação e Bootstrapping

O MultiContext possui **Auto-Setup**. Ao rodar pela primeira vez, ele criará todos os arquivos base de configuração na sua pasta `~/.config/nvim/` sem tocar no código-fonte original.

### Instalando com `lazy.nvim`

```lua
{
    "seu-usuario/multi_context_plugin",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
        user_name = "Seu Nome", -- Será exibido no chat
    },
    keys = {
        { "<leader>mc", "<cmd>ContextToggle<cr>", desc = "Toggle MultiContext Chat" },
        { "<leader>mp", "<cmd>ContextControls<cr>", desc = "Painel de Controle MultiContext" },
    }
}
```

---

## ⌨️ UX e Atalhos do Chat e Painel

### Atalhos do Chat Principal
| Atalho | Modo | Ação |
|---|---|---|
| **`<CR>` / `<C-CR>` / `<S-CR>`** | Insert/Normal | Envia a mensagem e invoca a IA. |
| **`@`** | Insert | Abre o menu flutuante Fuzzy Finder para invocar um Agente (`@coder`) ou Esquadrão. |
| **`\`** *(Barra Invertida)* | Insert | Abre o menu de **Context Injectors** para colar dados vivos no seu prompt. |
| **`<Tab>` / `<S-Tab>`** | Normal | Navega pelo carrossel dinâmico do Enxame (Swarms) rodando em background. |
| **`<C-x>`** | Insert/Normal | 🛑 **Botão de Pânico:** Corta a conexão HTTP e interrompe o stream. |
| **`<A-b>`** | Insert/Normal | Copia o último bloco de código para a área de transferência. |
| **`k` / `<C-u>`** | Normal | Pausa o Auto-Scroll direcionalmente para ler histórico. |

### Centro de Comando (`:ContextControls`)
| Atalho | Ação |
|---|---|
| **`<CR>`** | Expande/Recolhe `[+]`/`[-]` seções, deleta agentes, edita Prompts isoladamente ou dá Load em Históricos. |
| **`<Space>`**| Altera Toggles (`[ ON ]`/`[ OFF ]`), níveis cognitivos (`low`/`medium`/`high`) ou fallbacks. |
| **`c`** | Altera dados contínuos numéricos ou textuais (Master Prompt, Apperance, Identidade). |
| **`e`** | Edição expressa. Abre no Neovim o arquivo fonte de uma Skill, Injetor, ou Cofre `.json`. |
| **`dd` / `p`** | Corta e cola APIs e opções para reordenar hierarquias e filas de prioridade. |

---

## 🎮 Comandos Legados (Modo Normal e Visual)
A maioria das injeções de contexto agora pode ser feita mais rápido com o atalho `\` dentro do próprio chat, mas os comandos globais antigos ainda funcionam:
`:ContextChatFull`, `:Context`, `:ContextFolder`, `:ContextRepo`, `:ContextGit`, `:ContextBuffers`, `:ContextTree`, `:ContextUndo`.

---

## 🧪 Testes Automatizados (TDD)

O plugin é desenvolvido estritamente sob TDD e mantido sob altíssima confiabilidade (atualmente com **105 testes de unidade e integração (100% Passing)**) garantindo resiliência total na arquitetura usando `plenary.nvim`.
```bash
make test_agregate_results
```

---

## 📜 Licença

Desenvolvido para hackers e entusiastas do Neovim. Licenciado sob a **MIT License**.
