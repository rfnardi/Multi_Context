# 🤖 MultiContext AI - Neovim Plugin

![Neovim](https://img.shields.io/badge/Neovim-0.8+-green.svg?style=for-the-badge&logo=neovim)
![Lua](https://img.shields.io/badge/Lua-100%25-blue.svg?style=for-the-badge&logo=lua)
![License](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)

## 📖 Visão Geral

**MultiContext AI** é um plugin nativo, assíncrono e de alto desempenho para Neovim que integra assistentes de Inteligência Artificial **autônomos** diretamente no editor (inspirado no paradigma do *Claude Code* e *Devin*). 

Diferente de plugins convencionais de autocompletar, o MultiContext atua como um engenheiro de software: ele navega no sistema, edita arquivos em background, roda testes no terminal, delega tarefas para enxames (Swarms) em abas paralelas e se auto-corrige usando um motor de raciocínio ReAct (Reasoning and Acting).

> **Objetivo:** Acelerar o fluxo de trabalho permitindo que a IA construa, teste e valide código de ponta a ponta, com consumo extremamente otimizado de tokens de contexto e alta resiliência a falhas de rede.

---

## 🚀 Funcionalidades Principais

| ✅ | Funcionalidade | Descrição |
|:---:|---|---|
| 🐝 | **Swarm Architecture** | O agente `@tech_lead` pode invocar múltiplos sub-agentes (ex: Coder, QA) para trabalharem paralelamente em background num carrossel dinâmico. |
| 🔌 | **Extensibilidade Pluggável** | Crie scripts Lua locais e ensine instantaneamente habilidades para a IA (ex: consultar Jira, SQL) sem precisar modificar o código-fonte do plugin! |
| 💾 | **Workspace Stateful** | Feche o Neovim a qualquer momento. O plugin empacota sua fila assíncrona, respostas em andamento e reabre todas as abas onde você parou. |
| 🥷 | **Arquitetura de Skills** | Agentes seguem o Princípio do Menor Privilégio. O `@arquiteto` não consegue acidentalmente rodar o bash, bloqueado pelo Gatekeeper nativo. |
| 🛡️ | **Parser Anti-Alucinação** | Novo motor XML tolerante a falhas. Se a IA esquecer de fechar uma tag, o plugin faz o "fechamento implícito" salvando a execução. |
| 🔀 | **Fallback de APIs Inteligente** | Se a sua API principal falhar (ex: Rate Limit da OpenAI), o plugin tenta automaticamente a próxima API da sua fila de forma invisível. |
| 🔄 | **Motor Autônomo (ReAct)** | A IA encadeia ferramentas sozinha (flag `--auto`) com um *Circuit Breaker* de segurança e auto-corte de requisições desnecessárias. |
| 🔍 | **LSP Smart Push** | Se a IA quebrar a sintaxe, o plugin lê o erro do Neovim em background e força a IA a consertar imediatamente na mesma iteração. |
| 🛑 | **Job Control (Pânico)** | Pressione `<C-x>` a qualquer momento para assassinar a conexão com a API via `jobstop`. |

---

## 🔌 Provedores Suportados (Zero Dependências)
O plugin possui uma camada nativa de transporte HTTP (`curl`) super otimizada, com suporte nativo e tratamento rigoroso de formato para:
- **Anthropic** (Claude 3.5 Sonnet) - *Com suporte nativo a Strict Role Enforcement*
- **OpenAI** (GPT-4o)
- **DeepSeek** (Coder V2 / V3)
- **Google Gemini**
- **Cloudflare AI**

---

## 🛠️ Criando suas Próprias Skills (Extensibilidade)
Você pode ensinar qualquer coisa à IA localmente. Basta criar um script `.lua` na sua pasta de configuração: `~/.config/nvim/mctx_skills/`

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
A IA aprenderá a usar essa ferramenta instantaneamente. Use o comando `:ContextReloadSkills` se fizer alterações com o Neovim aberto.

---

## 📦 Instalação e Bootstrapping

O MultiContext possui **Auto-Setup**. Ao rodar pela primeira vez, ele criará todos os arquivos base de configuração na sua pasta `~/.config/nvim/` sem tocar no código-fonte original.

### Instalando com `vim-plug` (Recomendado)

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
| `:'<,'>Context` | *(Visual)* Envia as linhas selecionadas para o chat. |
| `:ContextFolder` | Inicia a sessão enviando os arquivos do diretório atual. |
| `:ContextRepo` | Inicia a sessão mapeando todo o projeto do Git. |
| `:ContextGit` | Envia as alterações não commitadas (`git diff`). |
| `:ContextBuffers`| Envia todos os buffers de código carregados no Neovim. |
| `:ContextApis` | ⚙️ **Abre o menu interativo para trocar rapidamente de IA base.** |
| `:ContextTree` | Desenha a árvore do projeto no prompt. |
| `:ContextReloadSkills`| Recarrega imediatamente sua pasta local de habilidades (`~/.config/nvim/mctx_skills`). |
| `:ContextToggle` | Abre ou esconde a janela flutuante. |

---

## ⌨️ UX e Atalhos do Chat

| Atalho | Modo | Ação |
|---|---|---|
| **`<CR>` / `<C-CR>`** | Insert/Normal | Envia a mensagem e invoca a IA. |
| **`@`** | Insert | Abre o menu flutuante para invocar um Agente (`@coder`, `@qa`). |
| **`<Tab>` / `<S-Tab>`** | Normal | Navega pelo carrossel dinâmico do Enxame (Swarms) rodando em background. |
| **`<C-x>`** | Insert/Normal | 🛑 **Botão de Pânico:** Corta a conexão HTTP e interrompe o stream. |
| **`<A-b>`** | Insert/Normal | Copia o último bloco de código para a área de transferência. |
| **`k` / `<C-u>`** | Normal | Pausa o Auto-Scroll direcionalmente para ler histórico. |

---

## 🧪 Testes Automatizados (TDD)

O plugin é mantido sob alta confiabilidade com dezenas de testes usando `plenary.nvim`, garantindo que as lógicas de extração, rede e parser funcionem perfeitamente.
```bash
make test_all
```

---

## 📜 Licença

Desenvolvido para hackers e entusiastas do Neovim. Licenciado sob a **MIT License**.
