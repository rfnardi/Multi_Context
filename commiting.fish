#!/bin/fish

gitgo '
feat(cli): implementa modo Headless Autônomo e wrapper shell (Fase 50)

Introduz o adaptador CLI DevOps Mode, permitindo o acionamento de toda a 
inteligência do MultiContext diretamente do terminal do SO, sem a abertura 
de janelas do Neovim, habilitando o uso da IA em pipelines de CI/CD.

Detalhes Arquiteturais:
- EventBus Hijacking: Criação do `cli.lua` atuando como um parasita no
  barramento de eventos. Oculta a UI e redireciona os payloads de 
  `UI_APPEND_CHUNK` e `UI_APPEND_LINES` para o `io.stdout` do Linux.
- Phantom UI (Shadow Buffer): Bypass do orquestrador instanciando um
  buffer invisível (`nvim_create_buf(false, true)`), permitindo que a AST,
  os parsers de flags (--queue, --moa) e o Swarm rodem inalterados.
- OS Lifecycle Management: Intercepta `UI_TERMINATE_TURN` para injetar o
  comando `cquit 0`, mantendo o Event Loop vivo pelas Promises assíncronas
  e devolvendo o Exit Code correto para o SO ao finalizar.
- Memória Persistente: Implementação de Sessões Efêmeras (default) e 
  Sessões Persistentes, remontando o Ledger XML com `sync_from_lines` 
  e ativando Auto-Save assíncrono para arquivos `.mctx`.
- DX Terminal Wrapper: Criação do executável `mctx.sh`, abstraindo a sintaxe
  do Neovim. Aceita flags (`-f`) e agrupa argumentos (`$@`) para isentar
  o usuário do uso de aspas. Emprega strings multilinhas Lua (`[=[ ]=]`) 
  para neutralizar quebras de escaping.
- TDD Absolute Zero-Bleeding: Suite `cli_spec.lua` adicionada interceptando
  funções nativas (io.write, vim.cmd) assegurando execução sem vazamento 
  de interface gráfica (100% GREEN).
'

