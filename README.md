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
| 🛑 | **Job Control (Pânico)** | Pressione `<C-x>` a qualquer momento para assassinar a conexão com a API via `jobstop`. |

---

## 🔌 Provedores Suportados (Zero Dependências)
O plugin possui uma camada nativa de transporte HTTP (`curl`) super otimizada, com suporte nativo e tratamento rigoroso de formato para:
- **Anthropic** (Claude 3.5 Sonnet) - *Com suporte nativo a Strict Role Enforcement & Prompt Caching*
- **OpenAI** (GPT-4o / o1)
- **DeepSeek** (Coder V2 / V3)
- **Google Gemini**
- **Cloudflare AI**

---

## 🛠️ Criando suas Próprias Skills (Extensibilidade)
Você pode ensinar qualquer coisa à IA localmente. Basta ir ao Painel de Controle (`:ContextControls`), expandir a seção de Skills e clicar em `[ + Criar Nova Skill ]`. O plugin gera o boilerplate automaticamente. Os arquivos ficam salvos em `~/.config/nvim/mctx_skills/`

Exemplo de uma skill `banco_de_dados.lua`:
```lua
return {
    name = "consulta_sql",
    description = "Executa uma query no banco local do projeto",
    parameters = {
        { name = "query", type = "string", required = true, desc = "Comando SQL" }
    },
    execute = function(args)
        -- O plugin delega esta execução silenciosamente e retorna para a IA
        return vim.fn.system("sqlite3 database.db '" .. args.query .. "'")
    end
}
```
A IA aprenderá a usar essa ferramenta instantaneamente. Use o comando `:ContextReloadSkills` se fizer alterações externas com o Neovim aberto.

---

## 📦 Instalação e Bootstrapping

O MultiContext possui **Auto-Setup**. Ao rodar pela primeira vez, ele criará todos os arquivos base de configuração na sua pasta `~/.config/nvim/` sem tocar no código-fonte original.

### 1. Instalando com `lazy.nvim`

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

### 2. Instalando com `vim-plug`

Adicione no seu `init.vim` ou gerenciador de plugins:
```vim
Plug 'seu-usuario/multi_context_plugin'
```

Rode `:PlugInstall` e adicione o *setup*:

```lua
require('multi_context').setup({
  user_name = "SeuNome", -- Seu nome no chat
})
```

---

## 🎮 Comandos (Modo Normal e Visual)

| Comando | Descrição |
|---|---|
| `:ContextChatFull` | Abre o chat vazio ou retoma o workspace ativo. |
| `:Context` | *(Normal/Visual)* Envia o buffer ou as linhas selecionadas para o chat. |
| `:ContextFolder` | Inicia a sessão enviando os arquivos do diretório atual. |
| `:ContextRepo` | Inicia a sessão mapeando todo o projeto do Git. |
| `:ContextGit` | Envia as alterações não commitadas (`git diff`). |
| `:ContextBuffers`| Envia todos os buffers de código carregados no Neovim. |
| `:ContextControls` | ⚙️ **Abre o Painel Virtual Unificado para gerenciar APIs, Swarms, Compressão, Skills e Permissões IAM.** |
| `:ContextTree` | Desenha a árvore do projeto no prompt. |
| `:ContextReloadSkills`| Recarrega imediatamente sua pasta local de habilidades. |
| `:ContextToggle` | Abre ou esconde a janela flutuante principal. |
| `:ContextUndo` | Desfaz a última destruição/compressão do chat feita pelo `@archivist`. |

---

## ⌨️ UX e Atalhos do Chat e Painel

### Atalhos do Chat Principal
| Atalho | Modo | Ação |
|---|---|---|
| **`<CR>` / `<C-CR>` / `<S-CR>`** | Insert/Normal | Envia a mensagem e invoca a IA. |
| **`@`** | Insert | Abre o menu flutuante para invocar um Agente (`@coder`, `@qa`) ou um Esquadrão. |
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

## 🧪 Testes Automatizados (TDD)

O plugin é mantido sob alta confiabilidade (atualmente com **87 de 87 testes passando sem falhas**) usando `plenary.nvim`, garantindo que as lógicas de extração, rede, parser, interface virtual, permissões e resiliência de buffers funcionem perfeitamente em ambientes assíncronos.
```bash
make test_agregate_results
```

---

## 📜 Licença

Desenvolvido para hackers e entusiastas do Neovim. Licenciado sob a **MIT License**.
