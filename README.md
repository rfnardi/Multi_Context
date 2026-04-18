# 🤖 MultiContext AI - Neovim Plugin

![Neovim](https://img.shields.io/badge/Neovim-0.8+-green.svg?style=for-the-badge&logo=neovim)
![Lua](https://img.shields.io/badge/Lua-100%25-blue.svg?style=for-the-badge&logo=lua)
![License](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)

## 📖 Visão Geral

**MultiContext AI** é um plugin nativo, assíncrono e de alto desempenho para Neovim que integra assistentes de Inteligência Artificial **autônomos** diretamente no editor (inspirado no paradigma do *Claude Code* e *Devin*). 

Diferente de plugins convencionais de autocompletar, o MultiContext atua como um engenheiro de software na sua máquina: ele navega pelo sistema de arquivos, lê, analisa erros do LSP, edita arquivos em background, executa testes no terminal e se auto-corrige usando um motor de raciocínio ReAct (Reasoning and Acting).

> **Objetivo:** Acelerar o fluxo de trabalho permitindo que a IA construa, teste e valide código de ponta a ponta, enquanto você supervisiona o processo com total controle sobre o fluxo de requisições.

---

## 🚀 Funcionalidades Principais

| ✅ | Funcionalidade | Descrição |
|:---:|---|---|
| 🤖 | **Agentes Especializados** | Invoque personas persistentes (`@arquiteto`, `@coder`, `@qa`) com instruções modulares em JSON. |
| 🔄 | **Motor Autônomo (ReAct)** | A IA encadeia ferramentas sozinha (flag `--auto`) com um *Circuit Breaker* de segurança de 15 iterações. |
| ⚡ | **Prompt Caching Nativo** | Cache de contexto em servidores (Anthropic, DeepSeek, OpenAI) economizando até 90% de tokens e reduzindo latência. |
| 🔍 | **LSP Smart Push (Auto-LSP)** | Se a IA edita um arquivo e quebra a sintaxe, o plugin captura o erro do LSP e força a IA a ler o erro e consertar imediatamente no mesmo turno. |
| 📜 | **Smart Auto-Scroll** | O texto acompanha a IA digitando, mas **pausa automaticamente** se você mover o cursor para cima para ler o histórico, retomando apenas quando você descer. |
| 🛑 | **Job Control (Botão de Pânico)** | Pressione `<C-x>` a qualquer momento para assassinar a conexão com a API caso a IA comece a alucinar. |
| 🧠 | **Memória de Longo Prazo** | O arquivo `CONTEXT.md` atualiza e persiste as decisões de arquitetura e atua como "cérebro" do projeto. |
| 🛠️ | **Ferramentas Nativas** | A IA usa `read_file`, `edit_file`, `replace_lines`, `search_code` e `run_shell` simulando um desenvolvedor real. |
| 🗑️ | **Garbage Collection Ativa** | O agente *Engenheiro de Prompt* comprime buffers gigantes jogando fora logs inúteis para salvar memória (`:ContextUndo` suportado). |

---

## 📦 Instalação (Padrão vim-plug)

O MultiContext é leve e não possui dependências complexas.

### Requisitos do Sistema
- **Neovim 0.8+** (Necessário para a API de diagnósticos `vim.diagnostic` e janelas flutuantes).
- `curl` (para requisições HTTP assíncronas não-bloqueantes).
- `git` e `tree` (para extração de contexto de repositório e busca nativa).

### Instalando com `vim-plug` (Recomendado)

Adicione a linha abaixo no seu `init.vim` ou bloco de plugins do `init.lua`.

Se você já subiu o plugin para o seu GitHub:
```vim
Plug 'seu-usuario/multi_context.nvim'
```

*Dica para Desenvolvimento:* Se o plugin estiver apenas na sua máquina local, você pode instalá-lo apontando para a pasta:
```vim
Plug '~/.config/nvim/lua/multi_context' " Ajuste para o caminho real da sua pasta
```

Depois, rode `:PlugInstall` no Neovim. E adicione a configuração:

```lua
-- Em seu init.lua ou arquivo de config de plugins
require('multi_context').setup({
  user_name = "Nardi",                           -- Seu nome no chat
  config_path = "~/.config/nvim/context_apis.json",  -- Caminho do JSON de APIs
  api_keys_path = "~/.config/nvim/api_keys.json",    -- Caminho seguro das chaves
})
```

*(Outros gerenciadores como `lazy.nvim` e `packer` também são suportados via chamada `setup()`).*

---

## ⚙️ Configuração de Provedores e APIs

O plugin gerencia suas chaves e modelos de forma isolada em arquivos JSON para máxima segurança e portabilidade.

**1. Gerenciamento de Chaves (`api_keys.json`):**
```json
{
  "openai": "sk-proj-...",
  "kimi-k2": "sk-ant-...",
  "deepseek": "sk-..."
}
```

**2. Arquivo de Provedores (`context_apis.json`):**
Você pode cadastrar infinitos modelos (Gemini 2.5, GPT-4o, Claude 3.5, etc) e usar o comando visual `:ContextApis` para alternar entre eles em menos de 1 segundo de dentro do Neovim.

---

## 🎮 Comandos (Modo Normal e Visual)

Os comandos do MultiContext extraem contexto da sua máquina instantaneamente e abrem a interface de chat.

| Comando | Descrição |
|---|---|
| `:ContextChatFull` | Abre o chat de IA vazio ou retoma o workspace ativo. |
| `:'<,'>Context` | *(Modo Visual)* Envia as linhas de código selecionadas para o chat. |
| `:ContextFolder` | Inicia a sessão mapeando todos os arquivos do diretório atual. |
| `:ContextRepo` | Inicia lendo todo o projeto rastreado pelo Git. |
| `:ContextGit` | Envia as alterações não commitadas (`git diff`) para code review. |
| `:ContextBuffers`| Envia o texto de todos os buffers carregados no momento. |
| `:ContextTree` | Desenha a árvore de diretórios (nível 2) no prompt. |
| `:ContextUndo` | Restaura o buffer de chat para o estado anterior a uma compressão. |
| `:ContextToggle` | Abre ou esconde a janela flutuante sem perder a conversa. |

---

## ⌨️ UX e Atalhos do Chat

Quando a janela flutuante estiver aberta, o comportamento do Neovim é otimizado para interação com a IA:

| Atalho | Modo | Ação |
|---|---|---|
| **`<CR>` / `<C-CR>`** | Insert/Normal | Envia a mensagem para a IA. |
| **`@`** | Insert | Abre o menu flutuante para seleção rápida de Agentes. |
| **`<C-x>`** | Insert/Normal | 🛑 **Botão de Pânico / Abort:** Corta a conexão HTTP e para a IA de escrever instantaneamente. |
| **`<A-b>`** | Insert/Normal | Copia automaticamente o último bloco de código (\`\`\`) para o clipboard. |
| **`k` / `<C-u>`** | Normal | Pausa o Auto-Scroll. A IA continua escrevendo embaixo enquanto você lê o histórico. |
| **`G`** | Normal | Vai para a última linha e religa o Auto-Scroll. |

> **Aprovação de Tarefas (Modo Manual):** O plugin detecta automaticamente quando a IA sugere uma ferramenta de edição ou terminal. Se a flag `--auto` não foi usada, uma caixa de confirmação `[Sim/Não/Todos/Cancelar]` aparecerá naturalmente na sua tela, sem necessidade de atalhos extras.

---

## 🔐 Arquitetura de Segurança e Auto-Halt

O modo autônomo (flag `--auto`) do MultiContext é protegido por uma engenharia de resiliência e validação:

1. **Auto-Halt em Mutações:** Se a IA edita um código ou roda um shell script, o plugin **corta a geração de texto** no exato milissegundo em que a tag é fechada. Isso impede a IA de encadear ferramentas baseada em alucinações antes de ver o resultado real no disco.
2. **LSP Smart Push:** Ao pausar após uma edição, o plugin rastreia o buffer de código. Se houverem erros (variáveis não declaradas, falta de vírgula), o plugin concatena o erro do LSP na resposta do Neovim. A IA acorda no turno seguinte já ciente de que o código quebrou e tenta consertar.
3. **Isolamento Funcional:** O parser de XML foi desacoplado da UI. Ele é imune a fechamentos corrompidos de tags Markdown, ignorando lixo textual e prevenindo travamentos.
4. **Alerta de Perigo:** Padrões Bash destrutivos (`rm -rf`, `mkfs`, `sudo`) contornam a flag `--auto` e sempre forçam uma popup `[Sim/Não]` humana.

---

## 🏗️ Estrutura de Módulos (Design Desacoplado)

```text
lua/multi_context/
├── init.lua              # Orquestrador de UI e hooks de stream live
├── api_client.lua        # Cliente HTTP Assíncrono com injeção de Job_ID
├── prompt_parser.lua     # Extrator de intenções puras (@agentes, --auto)
├── tool_parser.lua       # Sanitizador matemático Anti-Alucinação XML
├── tool_runner.lua       # Executor de Shell, FileSystem e injetor de LSP
├── react_loop.lua        # Gerente de Sessão, Circuit Breaker e Abort de Jobs
├── tools.lua             # APIs de integração nativa do Neovim
└── ui/
    ├── scroller.lua      # Smart Auto-Scroll direcional (concorrência de leitura)
    └── popup.lua         # Manipulação de janela e highlights
```

---

## 🧪 Testes Automatizados (TDD)

O plugin é testado usando `plenary.nvim`. Parsers, manipuladores de estado de scroll e roteamento de requisições são blindados contra regressões.

Para rodar a suíte de testes localmente:
```bash
make test
```

---

## 🌐 Provedores e Modelos Recomendados

O sistema funciona com qualquer endpoint que obedeça os padrões estruturais abaixo:

| Provedor | Modelo Sugerido | Funciona com ReAct (--auto)? | Caching Integrado |
|----------|-----------------|:---:|:---:|
| **Anthropic** | `claude-3-5-sonnet` | ✅ Excelente | ✅ |
| **OpenAI** | `gpt-4o` | ✅ Excelente | ✅ |
| **DeepSeek** | `deepseek-coder` | ✅ Muito Bom | ✅ |
| **Google** | `gemini-2.5-pro` | ✅ Bom | ❌ |
| **Local (Ollama)** | `codellama`, `qwen2.5-coder` | ⚠️ Básico | ❌ |

---

## 📅 Roadmap

-[x] Motor Autônomo ReAct e I/O de Sistema de Arquivos
- [x] Prompt Caching e Engenharia de Prompt (Memória via `CONTEXT.md`)
- [x] Integração LSP — Auto-LSP e Smart Push (Fase 2)
- [x] Job Control (`<C-x>`) e Smart Auto-Scroll 
- [ ] Padronização DRY no construtor de conexões HTTP (`api_handlers.lua`)
- [ ] Central de download para injetar Agentes Externos Open-Source.

---

## 📜 Licença

Desenvolvido para hackers e entusiastas do Neovim. Licenciado sob a **MIT License** – veja o arquivo `LICENSE` para detalhes.
