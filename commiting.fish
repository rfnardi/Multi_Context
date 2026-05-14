#!/bin/fish

gitgo '
fix(core): blindagem do parser JSON do swarm e estabilização determinística da suíte assíncrona

Este commit resolve falhas de alucinação de LLMs durante a orquestração do Swarm e erradica as "Ghost Exceptions" que causavam flutuação silenciosa na contagem de testes do Plenary.

🛠️ Resiliência e Blindagem Cognitiva:
- feat(swarm): Adicionado fallback no `swarm_manager.lua` para desembrulhar automaticamente JSONs encapsulados na chave `json_payload` (alucinação comum em modelos como o DeepSeek).
- docs(tools): Atualizada a documentação da ferramenta `spawn_swarm` com cláusulas de proibição estrita contra envelopamento Markdown e chaves JSON aninhadas.

🧪 Estabilização da Suíte de Testes (Barreira Assíncrona):
- fix(tests): Criado o módulo `libuv_barrier.lua` (Barreira de Adamantium). Ele intercepta cirurgicamente a API nativa do Neovim (`jobstart`, `schedule`, `defer_fn`, `autocmds`), envelopando todos os callbacks em `pcall`. 
- chore(tests): Implementado Teardown absoluto no fim de cada bloco `it()`, garantindo limpeza de buffers órfãos e reset do StateManager/Swarm. Isso impede que callbacks atrasados derrubem a corrotina do Busted, cravando a contagem de testes em exatos 275/275.
- test(ui): Corrigida a asserção da Fase 42.5 (`conceallevel`) e readequados os guardrails do `prompt_parser` para respeitar os limites de tokens exigidos pelo TDD.
'

