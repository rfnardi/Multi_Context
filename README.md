# 🤖 MultiContext AI - Neovim Plugin

![Neovim](https://img.shields.io/badge/Neovim-0.8+-green.svg?style=for-the-badge&logo=neovim)
![Lua](https://img.shields.io/badge/Lua-100%25-blue.svg?style=for-the-badge&logo=lua)
![License](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)

## 📖 Visão Geral

**MultiContext AI** é um plugin nativo, assíncrono e de alto desempenho para Neovim que integra assistentes de Inteligência Artificial **autônomos** diretamente no editor (inspirado no paradigma do *Claude Code* e *Devin*). 

Diferente de plugins convencionais de autocompletar, o MultiContext atua como um engenheiro de software: ele navega no sistema, edita arquivos em background, roda testes no terminal, delega tarefas para enxames (Swarms) em abas paralelas e se auto-corrige usando um motor de raciocínio ReAct (Reasoning and Acting).

> **Objetivo:** Acelerar o fluxo de trabalho permitindo que a IA construa, teste e valide código de ponta a ponta, com consumo extremamente otimizado de tokens de contexto, governança de custos e alta resiliência a falhas de rede.

---

## 🚀 Funcionalidades Principais

| Ícone | Funcionalidade | Descrição |
|:---:|---|---|
| 🎛️ | **Virtual UI Engine & IAM** | Painel centralizado e interativo estilo React (Virtual DOM) para orquestrar APIs, Fallbacks, Watchdog e Skills. Permite **Drill-down** para expandir agentes, **criar novas Personas/Skills dinamicamente** e gerenciar permissões (`●`/`○`) on-the-fly. Suporta reordenação nativa (`dd`, `p`, `<Space>`, `c`, `e`). |
| 🧩 | **Context Injectors (`\`)** | Componha prompts como um lego. Digite `\` no chat para abrir um menu suspenso e injetar nativamente seus *buffers abertos*, *git diffs*, *erros de LSP* ou a *árvore de arquivos* diretamente no prompt. Totalmente extensível via scripts `.lua`. |
| 🐝 | **Swarm Architecture** | O agente `@tech_lead` invoca múltiplos sub-agentes (Coder, QA) para trabalharem paralelamente num carrossel dinâmico de abas em background. |
| 🧠 | **Cognitive Routing (MoA)** | O sistema distribui tarefas avaliando o custo/benefício (High/Medium/Low), roteando tasks simples para APIs baratas e caras para complexas. |
| 🛡️ | **Context Watchdog 2.0** | Um rastreador preditivo (EMA) monitora a janela do chat. Se ameaçar estourar, invoca o `@archivist` usando 3 motores de compressão configuráveis (**Semântico, Percentual ou Fixo**) encapsulando a memória no formato Quadripartite. |
| 🎖️ | **Esquadrões (Squads)** | Invoque equipes inteiras mencionando `@squad_nome` (ex: `@squad_dev`). O sistema compila e dispara o enxame mascarando o JSON complexo. |
| 🔀 | **Pipelines & Coreografia** | IAs podem montar esteiras de produção (`chain`) ou repassar o controle do corpo e do código para outros especialistas *on-the-fly* (`switch_agent`). |
| 📉 | **Token Leak Prevention** | Sub-agentes isolam seus raciocínios caóticos, devolvendo ao Tech Lead apenas um `<final_report>` limpo, economizando milhares de tokens. |
| 🔌 | **Extensibilidade Pluggável** | Crie scripts Lua locais (`mctx_skills/`) e ensine instantaneamente habilidades customizadas para a IA (ex: Jira, SQL) sem tocar no core do plugin. |
| 💾 | **Workspace Stateful** | Feche o Neovim a qualquer momento. O plugin empacota sua fila assíncrona, respostas em andamento em disco (`.mctx`) e reabre todas as abas onde você parou. |
| 🥷 | **Arquitetura de Permissões** | Agentes seguem o Princípio do Menor Privilégio. Bloqueados pelo Gatekeeper nativo, IAs sem permissão não podem usar bash, invocar outros agentes ou editar o disco. Tudo controlado visualmente pela UI Virtual. |
| 🔄 | **Fallback de APIs Inteligente** | Se a sua API principal falhar (ex: Rate Limit da OpenAI), o plugin tenta automaticamente a próxima API da sua fila de forma invisível. |

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

O MultiContext divide a personalização do usuário em duas frentes: **Habilidades de Ação (Skills)** e **Macros de Contexto (Injectors)**.

### 1. Criando Skills (Ferramentas para a IA)
Acesse `:ContextControls` e crie uma nova skill. Ela será salva em `~/.config/nvim/mctx_skills/`.
```lua
return {
    name = "consulta_sql",
    description = "Executa uma query no banco local do projeto",
    parameters = { { name = "query", type = "string", required = true } },
    execute = function(args) return vim.fn.system("sqlite3 db.db '" .. args.query .. "'") end
}
```

### 2. Criando Context Injectors (Macros para você)
Você pode criar blocos de texto dinâmicos para injetar nos seus prompts usando a tecla `\`. Crie scripts `.lua` na pasta `~/.config/nvim/mctx_injectors/`.
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
| **`@`** | Insert | Abre o menu flutuante para invocar um Agente (`@coder`, `@qa`) ou um Esquadrão. |
| **`\`** *(Barra Invertida)* | Insert | Abre o menu de **Context Injectors** para colar dados vivos no seu prompt. |
| **`<Tab>` / `<S-Tab>`** | Normal | Navega pelo carrossel dinâmico do Enxame (Swarms) rodando em background. |
| **`<C-x>`** | Insert/Normal | 🛑 **Botão de Pânico:** Corta a conexão HTTP e interrompe o stream. |
| **`<A-b>`** | Insert/Normal | Copia o último bloco de código para a área de transferência. |
| **`k` / `<C-u>`** | Normal | Pausa o Auto-Scroll direcionalmente para ler histórico. |

### Atalhos do Painel Virtual (`:ContextControls`)
| Atalho | Ação |
|---|---|
| **`<CR>`** | Expande categorias, faz Drill-down em agentes ou invoca criação de entidades `[+]`. |
| **`<Space>`**| Altera Toggles (`●`/`○`) de permissões, troca APIs ativas ou cicla modos. |
| **`c`** | Edita/Muda um valor numérico ou textual (Limites, Nível Cognitivo, Nome). |
| **`e`** | Abre instantaneamente o arquivo `.lua` para edição expressa de uma Skill Customizada. |
| **`dd` / `p`** | Corta e cola APIs e opções para reordenar hierarquias e filas de prioridade. |

---

## 🎮 Comandos Legados (Modo Normal e Visual)
A maioria das injeções de contexto agora pode ser feita mais rápido com o atalho `\` dentro do próprio chat, mas os comandos globais antigos ainda funcionam:
`:ContextChatFull`, `:Context`, `:ContextFolder`, `:ContextRepo`, `:ContextGit`, `:ContextBuffers`, `:ContextTree`.

---

## 🧪 Testes Automatizados (TDD)

O plugin é mantido sob alta confiabilidade (atualmente com **92 de 92 testes passando sem falhas**) usando `plenary.nvim`.
```bash
make test_agregate_results
```

---

## 📜 Licença

Desenvolvido para hackers e entusiastas do Neovim. Licenciado sob a **MIT License**.
