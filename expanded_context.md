Aabaixo está o contexto do meu projeto de Plugin do neovim.
Vamos operar da seguinte forma dentro da perspectiva TDD: você escreverá/atualizará ao longo do trabalho apenas 3 arquivos: create_tests.sh, collect_info.sh e refactorate.sh que rodarei de dentro do terminal do neovim na raíz do projeto. 

Quanto ao collect_info.sh, ele deverá coletar a informação desejada e jogar no stdout pois vou rodá-lo com :bash % | xclip -selection clipboard .

Quanto aos outros dois scripts, eles devem criar os testes e editar os arquivos diretamente, e não construírem outros scripts que editam arquivos que precisam ser executado para só então termos os arquivos editados. Eles devem usar diretamente cat << 'EOF' > arquivo_a_ser_substituído ou comandos sed, etc para fazer a edição DIRETA dos arquivos.
# Árvore de arquivos:
[01;34m.[0m
├── collect_info.sh
├── CONTEXT.md
├── [01;32mcreate_tests.sh[0m
├── expanded_context.md
├── get_context_human_written.fish
├── [01;34mlua[0m
│   └── [01;34mmulti_context[0m
│       ├── [01;34magents[0m
│       │   └── agents.json
│       ├── agents.lua
│       ├── api_client.lua
│       ├── api_handlers.lua
│       ├── api_selector.lua
│       ├── commands.lua
│       ├── config.lua
│       ├── context_builders.lua
│       ├── conversation.lua
│       ├── init.lua
│       ├── memory_tracker.lua
│       ├── prompt_parser.lua
│       ├── [01;32mqueue_editor.lua[0m
│       ├── react_loop.lua
│       ├── refactorate.sh
│       ├── [01;34mskills[0m
│       │   ├── [01;34mdocs[0m
│       │   │   ├── apply_diff.md
│       │   │   ├── edit_file.md
│       │   │   ├── get_diagnostics.md
│       │   │   ├── list_files.md
│       │   │   ├── read_file.md
│       │   │   ├── replace_lines.md
│       │   │   ├── rewrite_chat_buffer.md
│       │   │   ├── run_shell.md
│       │   │   ├── search_code.md
│       │   │   ├── spawn_swarm.md
│       │   │   └── switch_agent.md
│       │   └── [01;32mregistry.lua[0m
│       ├── skills_manager.lua
│       ├── squads.lua
│       ├── swarm_manager.lua
│       ├── [01;34mtests[0m
│       │   ├── abstraction_level_spec.lua
│       │   ├── [01;32mapi_handlers_spec.lua[0m
│       │   ├── archivist_spec.lua
│       │   ├── config_spec.lua
│       │   ├── context_builders_spec.lua
│       │   ├── conversation_spec.lua
│       │   ├── diagnostics_spec.lua
│       │   ├── init_tracker_spec.lua
│       │   ├── memory_tracker_spec.lua
│       │   ├── minimal_init.lua
│       │   ├── [01;32mprompt_optimization_spec.lua[0m
│       │   ├── prompt_parser_spec.lua
│       │   ├── [01;32mprompt_squads_spec.lua[0m
│       │   ├── [01;32mqueue_editor_spec.lua[0m
│       │   ├── react_loop_spec.lua
│       │   ├── scroller_spec.lua
│       │   ├── session_spec.lua
│       │   ├── skills_manager_spec.lua
│       │   ├── squads_spec.lua
│       │   ├── swarm_etapa1_spec.lua
│       │   ├── swarm_etapa2_spec.lua
│       │   ├── swarm_etapa3_spec.lua
│       │   ├── swarm_etapa4_spec.lua
│       │   ├── swarm_etapa5_spec.lua
│       │   ├── swarm_phase21_spec.lua
│       │   ├── swarm_routing_spec.lua
│       │   ├── tool_parser_spec.lua
│       │   ├── [01;32mtools_diff_spec.lua[0m
│       │   ├── tools_spec.lua
│       │   ├── utils_spec.lua
│       │   └── watchdog_spec.lua
│       ├── tool_parser.lua
│       ├── [01;32mtool_runner.lua[0m
│       ├── tools.lua
│       ├── transport.lua
│       ├── [01;34mui[0m
│       │   ├── highlights.lua
│       │   ├── popup.lua
│       │   └── scroller.lua
│       └── utils.lua
├── Makefile
├── README.md
├── refactorate.sh
└── [01;32mrun_tests.sh[0m

7 directories, 78 files
======= Context.md (arquivo que resume o estado do projeto)=======
# MultiContext AI - Plugin Neovim

## Visão Geral
MultiContext AI é um plugin nativo para Neovim que integra assistentes de IA com capacidades autônomas (estilo Devin/Claude Code). O plugin permite interação com múltiplos agentes especializados através de uma interface de chat, com acesso direto ao sistema de arquivos, execução de terminal, loops autônomos de raciocínio (ReAct) e gerenciamento ativo de janela de contexto. Na sua versão mais recente, suporta **Swarm Architecture** (Enxames de IA com MoA - Mixture of Agents), persistência assíncrona de estado (Stateful Workspace), **Meta-Agentes (Squads)**, **Memória Quadripartite (Watchdog Preditivo)** e um **Ecossistema de Skills Pluggáveis** que permite aos usuários expandirem as habilidades da IA localmente.

## Arquitetura Técnica

### Tecnologias Principais
- **Linguagem**: Lua (integração nativa com Neovim)
- **Framework de Testes**: `plenary.nvim` (busted) - **79/79 Passando Absolutamente**.
- **Operações Assíncronas e Rede**: `vim.fn.jobstart` / `vim.fn.jobstop` abstraídos via módulo de transporte customizado (`curl` não-bloqueante).
- **Processamento de XML**: Parser funcional tolerante a falhas, com auto-fechamento implícito de tags contra alucinações.
- **Concorrência**: Implementação de *Worker Pool* nativo gerenciando Promises assíncronas do `curl` sem travar a thread principal de UI do Neovim.
- **Serialização de Estado**: Metadata Envelope e injeção de JSON em XML para salvar e recuperar as sessões do enxame sem perder legibilidade do arquivo original.

### Estrutura de Diretórios
```text
lua/multi_context/
├── init.lua              # Orquestrador principal, monitoramento live de stream e hooks
├── config.lua            # Configurações, Bootstrapping de Usuário e Auto-Setup
├── agents.lua            # Inicializador do mctx_agents.json do usuário
├── api_client.lua        # Roteador de filas e fallbacks de API
├── transport.lua         # Motor de HTTP (curl), streams e cleanup de temp files
├── prompt_parser.lua     # Parser de intenções e Montador Dinâmico de Prompts e Skills
├── tool_parser.lua       # Extrator funcional e sanitizador de tags XML (Auto-close)
├── tool_runner.lua       # Gatekeeper de Permissões, executor nativo e roteador de plugins
├── swarm_manager.lua     # Cérebro do Enxame: filas, workers, ReAct, MoA, Pipelines e Coreografia
├── squads.lua            # Loader e resolvedor de Esquadrões Meta-Agentes (Fase 23)
├── skills_manager.lua    # Loader assíncrono e validador de código externo (Hot-Reload)
├── react_loop.lua        # Gerenciador de estado de sessão e Circuit Breaker
├── memory_tracker.lua    # Watchdog Preditivo com cálculo de Média Móvel (EMA) (Fase 22)
├── context_builders.lua  # Extratores de contexto injetando numeração de linhas estrita (1 | code)
├── queue_editor.lua      # Interface interativa visual (UI) para gerenciar APIs e permissões de Swarm
├── tools.lua             # Ferramentas nativas (leitura, edição, bash, LSP, Unified Diff)
├── utils.lua             # Ferramentas de cálculo de token e serialização de Workspace
├── ui/
│   ├── popup.lua         # Lógica da janela flutuante, carrossel de buffers e atalhos
│   ├── scroller.lua      # Smart Auto-Scroll silencioso e rastreador direcional
│   └── highlights.lua    # Highlights sintáticos customizados
└── tests/                # Suíte de testes automatizados (TDD/Plenary) - 79/79 Passando
```

## Funcionalidades e Capacidades Implementadas

### 1. Swarm Architecture Avançada (MoA, Pipelines e Coreografia)
- **Delegação via Tech Lead (Lazy Delegator)**: A persona `@tech_lead` orquestra a divisão de trabalho através da tool `spawn_swarm`, passando um payload JSON com as tarefas. O Tech Lead é orientado a não programar, mas sim projetar e repassar o trabalho.
- **Roteamento Cognitivo (Mixture of Agents - MoA)**: APIs e Agentes possuem um `abstraction_level` (high, medium, low). O `swarm_manager` distribui as tarefas priorizando APIs mais baratas (medium/low) que deem conta do recado, subindo para APIs caras (high) apenas como *Fallback Direcional*.
- **Pipelines Declarativos (Esteiras de Produção)**: Suporte à diretiva `"chain":["coder", "qa"]`. Quando o Coder termina, a tarefa não é encerrada: ela "reencarna" na fila para o QA, acumulando o contexto do agente anterior.
- **Coreografia (Ping-Pong Autônomo)**: Sub-agentes autorizados via `"allow_switch"` podem usar a tool `switch_agent` para transferir o controle da aba e da tarefa em tempo real para outro agente (ex: chamar o DBA). O sistema injeta o novo System Prompt *in-flight* sem fechar o motor ReAct.
- **Carrossel de Buffers (UI)**: Sub-agentes rodam em abas invisíveis (`nofile`) dentro do mesmo *popup*. O usuário navega em tempo real com `<Tab>` e `<S-Tab>`.

### 2. Prevenção Extrema de Token Leak (Fase 20)
- **Extração Cirúrgica (`<final_report>`)**: Em vez de retornar todo o scratchpad (logs de ferramentas, raciocínios intermediários) para o Tech Lead, o Swarm extrai rigorosamente apenas o que está dentro da tag `<final_report>`. Isso salva milhares de tokens a cada turno.

### 3. Persistência de Workspace Stateful (Fase 18.5)
- **Metadata Envelope (`<mctx_session>`)**: Cada sessão salva em disco recebe um ID e timestamps. Isso evita a duplicação de arquivos e mantém rastreabilidade.
- **JSON-in-XML**: Todo o estado volátil das tarefas do enxame (`M.state.queue`, buffers inativos e `reports`) é empacotado e salvo em uma tag oculta `<swarm_state>`. Quando o usuário reabre o Neovim e invoca o log, todo o Swarm ressuscita perfeitamente.

### 4. Sistema Pluggável de Skills (Fase 19)
- **Extensibilidade Local**: O `skills_manager` varre a pasta `~/.config/nvim/mctx_skills/` em busca de novos scripts `.lua`.
- **Injeção de Prompt**: O plugin gera os manuais em formato XML das funções do usuário dinamicamente e ensina a IA a utilizá-las.
- **Roteamento Seguro**: O `tool_runner` roda a ferramenta do usuário através de um `pcall` (Proteção contra crashes por código mal formatado).
- **Hot-Reload Automático**: A qualquer momento a ram é limpa e atualizada via `:ContextReloadSkills`.

### 5. O Guardião Preditivo e a Compressão Quadripartite (Fase 22)
- **Watchdog via EMA**: Um rastreador analisa o tamanho histórico de tokens por turno usando uma Média Móvel Exponencial. Antes de despachar, o plugin projeta o tamanho futuro da requisição.
- **A Persona `@archivist`**: Se a janela segura (Cognitive Horizon) estiver ameaçada, o sistema sequestra a requisição do usuário, invoca o Arquivista invisivelmente, extrai a Memória Quadripartite (`<genesis>`, `<journey>`, `<now>`, `<plan>`), destrói a prolixidade do chat em tela e injeta essa memória hiper-compacta, restaurando o contexto antes de prosseguir com a requisição original.

### 6. Esquadrões Meta-Agentes (Squads - Fase 23)
- **Compilação Transparente de Intents**: O usuário pode chamar equipes pré-definidas no chat (ex: `@squad_dev`). O `prompt_parser` detecta o Squad, anexa a intent do usuário e transpila isso para um Payload JSON rígido encabeçado pelo `@tech_lead`, ativando Swarms complexos com fluidez de linguagem natural.

### 7. Unified Diff e Ferramentas Estritas (Fase 24)
- **Binário Nativo `patch`**: Implementação da skill `apply_diff`, focada em edições cirúrgicas em arquivos de milhares de linhas utilizando a arquitetura Universal Diff, prevenindo a temida alucinação do *"resto do código inalterado aqui..."* das LLMs.
- **Otimização Extrema de Prompts**: O manual do sistema base injetado na LLM foi emagrecido ao limite absoluto, garantindo a economia de centenas de tokens a cada requisição enviada.

### 8. Sistema de Agentes Estritos e Resiliência
- **Gatekeeper e Menor Privilégio**: Bloqueio de alucinações de agentes não autorizados usando ferramentas críticas (ex: Arquiteto rodando bash).
- **Parser de Tags**: O `tool_parser.lua` força o fechamento implícito de `<tool_call>` corrompidas.
- **Fallback Automático**: O `api_client` tenta automaticamente a próxima API da fila se a primária falhar por instabilidade ou Rate Limit.

---

## Decisões Técnicas Críticas
1. **Desacoplamento de UI e Background**: O motor Swarm distribui a carga via `curl` assíncrono e `vim.schedule()` mantendo a navegação do usuário fluida.
2. **Injeção Dinâmica de System Prompt**: Para permitir a troca de agentes na mesma aba (Coreografia), a primeira posição do array `messages` é reescrita *on-the-fly* dentro do próprio `tool_runner`/`swarm_manager`, enganando a LLM para assumir a nova persona sem perder o fluxo de consciência da tarefa.
3. **Delegation vs Execution (Skills)**: Isolamento das skills do usuário via `loadfile` e `pcall`.
4. **Queue Editor Interativo (`queue_editor.lua`)**: Em vez de editar JSON bruto, manipulamos buffers `acwrite` renderizando opções virtuais (`[x]`) para alternar a flag `allow_spawn` em tempo real na interface do editor.
5. **Uso de Ferramentas UNIX Nativas**: A escolha pelo utilitário `patch --force` garante operações de Unified Diff robustas a nível de Kernel sem reinventar a roda ou prender a *thread* com prompts de terminal interativos.

---

## Estado Atual do Desenvolvimento

### ✅ Implementado, Estável e Testado (Fases 1 a 24)
O core do produto alcançou o padrão de motor de orquestração industrial pesado.
- Arquitetura Swarm Avançada com Roteamento Cognitivo (MoA), Pipelines e Coreografia.
- Guardião Preditivo com compressão baseada no formato Quadripartite.
- Suporte a Squads (Esquadrões) fluindo por linguagem natural.
- Prevenção de Token Leak com `<final_report>`.
- Persistência de Workspace e Ressurreição de Estado (`.mctx`).
- Injeção e motor de execução de custom skills (Plugins), incluindo a skill pesada `apply_diff`.
- Refinamento de UI para gestão de APIs (Queue Editor).
- **Cobertura Testes Plenary:** 79 de 79 Sucessos absolutos (0 Falhas).

### 🔄 Próximos Passos (Fase Opcional e Comunidade)
Com a fundação tecnológica da V1 totalmente concluída e testada:
1. **Catalogar Exemplos de Skills**: Criar um repositório ou pasta `examples/` contendo scripts avançados de skills prontas (ex: `read_jira.lua`, `sql_inspector.lua`, `run_pytest.lua`).
2. **Distribuição via Lazy.nvim**: Preparar releases com *tags* (ex: `v1.0.0`) para garantir setups fluídos via gerenciadores de pacotes.

---
*Última atualização: 23 de Abril de 2026 - Preditividade de Contexto (Watchdog), Squads e Unified Diff consolidados.*

 # Conteúdo de todos os arquivos lua do projeto:
======== ./lua/multi_context/commands.lua ========
-- commands.lua
-- Handlers dos comandos expostos pelo plugin.
-- Conecta :Context*, :ContextGit, etc. aos context_builders e ao popup.
local M = {}

-- Abre o popup com um conteúdo inicial e entra em modo de inserção.
local function open_with(content)
    local buf, win = require('multi_context.ui.popup').create_popup(content)
    if buf and win then vim.cmd("startinsert!") end
end

M.ContextChatHandler = function(line1, line2)
    local ctx = require('multi_context.context_builders')
    -- Chamado com range explícito (comando -range ou vnoremap)
    if line1 and line2 and tonumber(line1) ~= tonumber(line2) then
        open_with(ctx.get_visual_selection(line1, line2))
        return
    end
    -- Chamado sem range: detecta modo visual ou usa buffer inteiro
    local mode = vim.api.nvim_get_mode().mode
    if mode == 'v' or mode == 'V' then
        open_with(ctx.get_visual_selection())
    else
        open_with(ctx.get_current_buffer())
    end
end

M.ContextChatFull = function() open_with("") end

-- :ContextFolder -> APENAS a pasta onde o nvim foi aberto
M.ContextChatFolder = function()
    open_with(require('multi_context.context_builders').get_folder_context())
end

-- :ContextTree -> Árvore (tree) + Conteúdo (maxdepth 2)
M.ContextTree = function()
    open_with(require('multi_context.context_builders').get_tree_context())
end

-- :ContextRepo -> Todos os arquivos do repositório Git
M.ContextChatRepo = function()
    open_with(require('multi_context.context_builders').get_repo_context())
end

-- :ContextGit -> Diff de alterações não commitadas (git diff)
M.ContextChatGit = function()
    open_with(require('multi_context.context_builders').get_git_diff())
end

M.ContextApis = function()
    require('multi_context.api_selector').open_api_selector()
end

M.ContextBuffers  = function()
    open_with(require('multi_context.context_builders').get_all_buffers_content())
end

M.TogglePopup = function()
    local popup = require('multi_context.ui.popup')

    -- Se a janela já está aberta na tela, nós a escondemos e saímos
    if popup.popup_win and vim.api.nvim_win_is_valid(popup.popup_win) then
        vim.api.nvim_win_hide(popup.popup_win)
        vim.cmd("stopinsert")
        return
    end

    -- Se a janela está escondida, mas o buffer da conversa ainda existe na memória, reabre ele
    if popup.popup_buf and vim.api.nvim_buf_is_valid(popup.popup_buf) then
        open_with(popup.popup_buf)
    else
        -- Se for a primeira vez abrindo na sessão, inicia vazio
        open_with("")
    end
end

return M




======== ./lua/multi_context/skills/registry.lua ========
local M = {}

local function get_plugin_base_path()
    local source = debug.getinfo(1, "S").source:sub(2)
    if not source then return nil end
    local base = vim.fn.fnamemodify(source, ":p:h:h:h")
    if vim.fn.fnamemodify(base, ":t") == "lua" then
        return vim.fn.fnamemodify(base, ":h")
    end
    return base
end

M.get_skill_doc = function(skill_name)
    local base_path = get_plugin_base_path()
    if not base_path then return nil end
    
    local skill_file = vim.fn.join({ base_path, "lua", "multi_context", "skills", "docs", skill_name .. ".md" }, "/")
    
    if vim.fn.filereadable(skill_file) == 0 then
        local curr_file = debug.getinfo(1, "S").source:sub(2)
        local fallback_dir = vim.fn.fnamemodify(curr_file, ":h") .. "/docs/"
        skill_file = fallback_dir .. skill_name .. ".md"
    end
    
    if vim.fn.filereadable(skill_file) == 1 then
        return table.concat(vim.fn.readfile(skill_file), "\n")
    end
    return nil
end

M.build_manual_for_skills = function(skills_array)
    if not skills_array or #skills_array == 0 then return "" end
    -- Cabeçalho Hiper-Sintético
    local manual = [[=== FERRAMENTAS DO SISTEMA ===
Use ESTRITAMENTE tags XML para invocar ferramentas. JSON PROIBIDO.
Auto-LSP ativo: edições injetam erros. NÃO CHAME get_diagnostics após editar.
=== SKILLS ATIVAS ===]]

    for _, skill in ipairs(skills_array) do
        local doc = M.get_skill_doc(skill)
        if doc then
            manual = manual .. "\n" .. doc .. "\n"
        end
    end
    return manual
end

return M




======== ./lua/multi_context/react_loop.lua ========
-- lua/multi_context/react_loop.lua
local M = {}

M.state = {
    is_autonomous = false,
    auto_loop_count = 0,
    active_agent = nil,
    queued_tasks = nil,
    last_backup = nil,
    active_job_id = nil,
    user_aborted = false,
}

M.reset_turn = function()
    M.state.is_autonomous = false
    M.state.auto_loop_count = 0
    M.state.active_job_id = nil
    M.state.user_aborted = false
end

M.check_circuit_breaker = function()
    M.state.auto_loop_count = M.state.auto_loop_count + 1
    if M.state.auto_loop_count >= 15 then
        vim.notify("Limite de 15 loops atingido. Pausando por segurança.", vim.log.levels.WARN)
        return true
    end
    return false
end

M.abort_stream = function(is_user)
    if M.state.active_job_id then
        M.state.user_aborted = is_user or false
        pcall(vim.fn.jobstop, M.state.active_job_id)
        M.state.active_job_id = nil
    end
end

return M




======== ./lua/multi_context/prompt_parser.lua ========
local M = {}
local registry = require('multi_context.skills.registry')

M.parse_user_input = function(raw_text, agents_table)
    local parsed = {
        text_to_send = raw_text,
        agent_name = nil,
        is_autonomous = false
    }
    
    local ok_sq, squads_manager = pcall(require, 'multi_context.squads')
    local squads = ok_sq and squads_manager.load_squads() or {}
    
    local agent_match = parsed.text_to_send:match("@([%w_]+)")
    if agent_match then
        if agent_match == "reset" then
            parsed.agent_name = "reset"
            parsed.text_to_send = parsed.text_to_send:gsub("@reset%s*", "")
        elseif squads[agent_match] then
            local squad_def = squads[agent_match]
            parsed.text_to_send = parsed.text_to_send:gsub("@" .. agent_match .. "%s*", "")
            parsed.text_to_send = parsed.text_to_send:gsub("^%s*", ""):gsub("%s*$", "")
            
            local main_task = vim.deepcopy(squad_def.tasks[1] or {})
            if parsed.text_to_send ~= "" then
                main_task.instruction = (main_task.instruction or "") .. "\n\nSolicitação do Usuário:\n" .. parsed.text_to_send
            end
            
            local payload = { tasks = { main_task } }
            if squad_def.tasks then
                for i = 2, #squad_def.tasks do table.insert(payload.tasks, squad_def.tasks[i]) end
            end
            
            local ok_json, json_payload = pcall(vim.fn.json_encode, payload)
            parsed.agent_name = "tech_lead"
            parsed.text_to_send = string.format("<tool_call name=\"spawn_swarm\">\n```json\n%s\n```\n</tool_call>", json_payload)
            parsed.is_autonomous = true
        elseif agents_table[agent_match] then
            parsed.agent_name = agent_match
            parsed.text_to_send = parsed.text_to_send:gsub("@" .. agent_match .. "%s*", "")
        end
    end
    
    if parsed.text_to_send:match("%-%-auto") then
        parsed.is_autonomous = true
        parsed.text_to_send = parsed.text_to_send:gsub("%-%-auto%s*", "")
    end
    
    parsed.text_to_send = parsed.text_to_send:gsub("^%s*", ""):gsub("%s*$", "")
    return parsed
end



M.build_system_prompt = function(base_prompt, memory_context, active_agent_name, agents_table, current_tokens)
    if active_agent_name == "archivist" then
        local cfg = require('multi_context.config').options
        local wd = cfg.watchdog or { strategy = "semantic", percent = 0.3, fixed_target = 1500 }
        local prompt = "Você é o @archivist do sistema. Sua missão é estruturar a memória do chat prolixo abaixo usando EXATAMENTE 4 tags: <genesis>, <plan>, <journey> e <now>.\n"
        if wd.strategy == "percent" then
            local target = math.floor((current_tokens or 5000) * (wd.percent or 0.3))
            prompt = prompt .. "MANDATÓRIO: A compressão é baseada num teto percentual. Seu output não pode ultrapassar " .. target .. " tokens.\n"
        elseif wd.strategy == "fixed" then
            prompt = prompt .. "MANDATÓRIO: A compressão é agressiva. Seu output não pode ultrapassar " .. (wd.fixed_target or 1500) .. " tokens.\n"
        else
            prompt = prompt .. "COMPRESSÃO SEMÂNTICA: Adapte o tamanho à complexidade do conteúdo, focando na integridade da informação.\n"
        end
        prompt = prompt .. "Responda ESTRITAMENTE com o XML gerado."
        return prompt
    end
    local system_prompt = base_prompt

    if memory_context then
        system_prompt = system_prompt .. "\n\n=== ESTADO ATUAL DO PROJETO (MEMÓRIA) ===\n" .. memory_context .. "\n- Atualize o CONTEXT.md ao concluir tarefas."
    end

    if active_agent_name and active_agent_name ~= "reset" and agents_table and agents_table[active_agent_name] then
        local agent_data = agents_table[active_agent_name]
        local active_agent_prompt = "\n\n=== INSTRUÇÕES DO AGENTE: " .. string.upper(active_agent_name) .. " ===\n" .. agent_data.system_prompt
        
        -- Montador Dinâmico de Skills
        if agent_data.skills and #agent_data.skills > 0 then
            active_agent_prompt = active_agent_prompt .. "\n\n" .. registry.build_manual_for_skills(agent_data.skills)
        end
        
        system_prompt = system_prompt .. active_agent_prompt
    end

    -- INJEÇÃO FASE 19: SKILLS CUSTOMIZADAS DO USUÁRIO
    local ok, skills_manager = pcall(require, 'multi_context.skills_manager')
    if ok and skills_manager and skills_manager.get_skills then
        local user_skills = skills_manager.get_skills()
        local has_user_skills = false
        local user_skills_xml = "\n\n=== FERRAMENTAS CUSTOMIZADAS ===\nVocê tem acesso a ferramentas customizadas pelo usuário. Você pode invocá-las retornando um bloco XML no formato <tool_call name=\"nome\">\n<tools>\n"
        
        for _, skill in pairs(user_skills) do
            has_user_skills = true
            local params_xml = ""
            if skill.parameters then
                for _, p in ipairs(skill.parameters) do
                    params_xml = params_xml .. string.format('\n      <parameter name="%s" type="%s" required="%s">%s</parameter>',
                        p.name, p.type or "string", tostring(p.required ~= false), p.desc or "")
                end
            end
            user_skills_xml = user_skills_xml .. string.format([[
  <tool_definition>
    <name>%s</name>
    <description>%s</description>
    <parameters>%s
    </parameters>
  </tool_definition>]], skill.name, skill.description, params_xml)
        end
        user_skills_xml = user_skills_xml .. "\n</tools>\n"

        if has_user_skills then
            system_prompt = system_prompt .. user_skills_xml
        end
    end

    return system_prompt
end

return M




======== ./lua/multi_context/tests/utils_spec.lua ========
local utils = require('multi_context.utils')

describe("Utils Module:", function()
    it("Deve dividir strings por quebra de linha corretamente", function()
        local str = "linha1\nlinha2\nlinha3"
        local res = utils.split_lines(str)
        assert.are.same({"linha1", "linha2", "linha3"}, res)
    end)

    it("Deve estimar tokens corretamente (4 chars = 1 token)", function()
        local buf = vim.api.nvim_create_buf(false, true)
        -- Injeta 2 linhas. A lógica soma: (#linha + 1). Total: (5+1) + (5+1) = 12 chars
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"12345", "12345"})
        
        local tokens = utils.estimate_tokens(buf)
        -- 12 / 4 = 3 tokens
        assert.are.same(3, tokens)
    end)
end)




======== ./lua/multi_context/tests/api_handlers_spec.lua ========
-- lua/multi_context/tests/api_handlers_spec.lua
-- transport.lua carrega normalmente em headless nvim.
-- O único mock necessário é vim.fn.jobstart, chamado em runtime.
local handlers = require('multi_context.api_handlers')

describe("API Handlers Module (Prompt Caching)", function()
    local original_jobstart
    local intercepted_cmd
    local intercepted_opts
    local payload_content

    before_each(function()
        intercepted_cmd  = nil
        intercepted_opts = nil
        payload_content  = nil

        original_jobstart = vim.fn.jobstart
        vim.fn.jobstart = function(cmd, opts)
            intercepted_cmd  = cmd
            intercepted_opts = opts
            for _, arg in ipairs(cmd) do
                if type(arg) == "string" and arg:match("^@") then
                    local f = io.open(arg:sub(2), "r")
                    if f then payload_content = f:read("*a"); f:close() end
                end
            end
            return 1
        end
    end)

    after_each(function()
        vim.fn.jobstart = original_jobstart
    end)

    it("Deve incluir stream_options e extrair metricas de cache (OpenAI / DeepSeek)", function()
        local callback_metrics
        local callback_done = false

        handlers.openai.make_request(
            { name = "ds", url = "http://ds", model = "deepseek-coder",
              headers = { ["Content-Type"] = "application/json" } },
            { { role = "user", content = "hello" } },
            { ds = "key123" },
            nil,
            function(chunk, err, done, metrics)
                if done then callback_done = true; callback_metrics = metrics end
            end
        )

        local parsed_payload = vim.fn.json_decode(payload_content)
        assert.is_not_nil(parsed_payload.stream_options)
        assert.is_true(parsed_payload.stream_options.include_usage)

        intercepted_opts.on_stdout(1, {
            'data: {"choices":[{"delta":{"content":""}}],"usage":{"prompt_cache_hit_tokens":1280}}'
        })
        intercepted_opts.on_exit(1, 0)

        assert.is_true(callback_done)
        assert.is_not_nil(callback_metrics)
        assert.are.same(1280, callback_metrics.cache_read_input_tokens)
    end)

    it("Deve estruturar o payload Anthropic com cache_control e capturar os metadados", function()
        local callback_metrics

        handlers.anthropic.make_request(
            { name = "claude", url = "http://claude", model = "claude-3.5",
              headers = { ["Content-Type"] = "application/json" } },
            {
                { role = "system", content = "Você é um assistente dev." },
                { role = "user",   content = "hello" },
            },
            { claude = "key123" },
            nil,
            function(chunk, err, done, metrics)
                if done then callback_metrics = metrics end
            end
        )

        local has_beta_header = false
        for _, v in ipairs(intercepted_cmd) do
            if type(v) == "string" and v:match("anthropic%-beta: prompt%-caching") then
                has_beta_header = true
            end
        end
        assert.is_true(has_beta_header)

        local parsed_payload = vim.fn.json_decode(payload_content)
        assert.is_not_nil(parsed_payload.system)
        assert.are.same("Você é um assistente dev.", parsed_payload.system[1].text)
        assert.are.same("ephemeral", parsed_payload.system[1].cache_control.type)

        intercepted_opts.on_stdout(1, {
            'data: {"type":"message_start","message":{"usage":{"cache_read_input_tokens":4048}}}'
        })
        intercepted_opts.on_exit(1, 0)

        assert.is_not_nil(callback_metrics)
        assert.are.same(4048, callback_metrics.cache_read_input_tokens)
    end)
end)




======== ./lua/multi_context/tests/init_tracker_spec.lua ========
local init = require('multi_context.init')
local memory_tracker = require('multi_context.memory_tracker')
local api_client = require('multi_context.api_client')
local popup = require('multi_context.ui.popup')
local config = require('multi_context.config')
local react_loop = require('multi_context.react_loop')

describe("Fase 25 - Passo 2: Alimentando a EMA", function()
    local orig_execute, orig_defer, buf
    
    before_each(function()
        memory_tracker.reset()
        config.options.watchdog = { mode = "off" } -- Garantindo que a compressao não ative e sequestre a chamada
        
        orig_defer = vim.defer_fn
        vim.defer_fn = function(cb, ms) cb() end
        
        orig_execute = api_client.execute
        api_client.execute = function(msgs, on_start, on_chunk, on_done)
            -- Simula a IA falando 12 caracteres (aprox 3 tokens) e terminando a execucao
            on_chunk("123456789012", {model="mock"}) 
            on_done({name="mock"}, {}) 
        end

        buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "## Nardi >>", "teste" })
        popup.popup_buf = buf
    end)

    after_each(function()
        api_client.execute = orig_execute
        vim.defer_fn = orig_defer
        vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("O Motor principal deve alimentar a memoria apos a IA finalizar a resposta", function()
        -- No disparo real, a resposta vai pra tela. O motor agora precisa medir o tamanho delta.
        init.SendFromPopup()
        
        -- Pelo design, esperamos que a contagem (count) vá de 0 para 1.
        assert.are.same(1, memory_tracker.state.count, "O on_done do SendFromPopup deveria ter acionado memory_tracker.add_turn()")
        -- 12 caracteres = 3 tokens. O tracker deve ter registrado pelo menos um valor > 0.
        assert.is_true(memory_tracker.get_ema() > 0, "A EMA deveria estar abastecida com os tokens gerados")
    end)
end)




======== ./lua/multi_context/tests/tool_parser_spec.lua ========
-- lua/multi_context/tests/tool_parser_spec.lua
local tool_parser = require('multi_context.tool_parser')

describe("Tool Parser Module:", function()
    it("Deve sanitizar tags de fechamento corrompidas", function()
        local xml_sujo = "<tool_call name='run_shell'>echo 1</arg_value>tool_call>"
        local xml_limpo = tool_parser.sanitize_payload(xml_sujo)
        assert.truthy(xml_limpo:match("</tool_call>"))
        assert.falsy(xml_limpo:match("</arg_value>tool_call>"))
    end)

    it("Deve converter alucinações de tag direta em tool_call padrão", function()
        local xml_sujo = "<run_shell>ls -la</run_shell>"
        local xml_limpo = tool_parser.sanitize_payload(xml_sujo)
        assert.truthy(xml_limpo:match('<tool_call name="run_shell">'))
    end)

    it("Deve remover lixo interno (crases markdown e tags órfãs)", function()
        local inner_sujo = "```bash\n<content>echo 'oi'</content>\n```"
        local inner_limpo = tool_parser.clean_inner_content(inner_sujo, "run_shell")
        assert.are.same("echo 'oi'", inner_limpo)
    end)

    it("Deve extrair a próxima ferramenta corretamente", function()
        local payload = 'Texto antes <tool_call name="read_file" path="main.lua">local x = 1</tool_call> Texto depois'
        local parsed = tool_parser.parse_next_tool(payload, 1)
        
        assert.is_false(parsed.is_invalid)
        assert.are.same("Texto antes ", parsed.text_before)
        assert.are.same("read_file", parsed.name)
        assert.are.same("main.lua", parsed.path)
        assert.are.same("local x = 1", parsed.inner)
    end)
end)




======== ./lua/multi_context/tests/diagnostics_spec.lua ========
local tools = require('multi_context.tools')
local api = vim.api

describe("Tools Module (get_diagnostics):", function()
    local test_buf
    -- Usamos um arquivo temporário real para satisfazer a checagem 'filereadable'
    local test_path = vim.fn.tempname() .. ".lua"
    local ns = api.nvim_create_namespace("mctx_test_diag")

    before_each(function()
        -- Cria o arquivo em disco
        vim.fn.writefile({"local x = 1", "local y = 2"}, test_path)
        -- Adiciona ao Neovim
        test_buf = vim.fn.bufadd(test_path)
        vim.fn.bufload(test_buf)
    end)

    after_each(function()
        -- Limpa ambiente
        pcall(vim.diagnostic.reset, ns, test_buf)
        pcall(api.nvim_buf_delete, test_buf, { force = true })
        vim.fn.delete(test_path)
    end)

    it("Deve retornar diagnósticos para arquivo existente", function()
        -- Mock de diagnósticos via API nativa (Agora passando o namespace correto!)
        vim.diagnostic.set(ns, test_buf, {
            { lnum = 0, col = 6, severity = 1, message = "Unused variable 'x'", source = "lua_ls" },
            { lnum = 1, col = 6, severity = 2, message = "Unused variable 'y'", source = "lua_ls" },
        })

        local res = tools.get_diagnostics(test_path)
        assert.truthy(res:match("Unused variable 'x'"))
        assert.truthy(res:match("ERROR"))
        assert.truthy(res:match("WARN"))
        assert.truthy(res:match("lua_ls"))
    end)

    it("Deve retornar mensagem informativa para arquivo sem problemas ou sem LSP", function()
        local res = tools.get_diagnostics(test_path)
        -- Retorna sucesso se achar a mensagem de que não há erros ou não há LSP
        assert.truthy(res:match("Nenhum") or res:match("AVISO"))
    end)

    it("Deve truncar saída quando há muitos diagnósticos", function()
        -- Injeta 60 diagnósticos para testar limite de tokens
        local many = {}
        for i = 1, 60 do
            table.insert(many, { lnum = i, col = 0, severity = 1, message = "Error number " .. i, source = "test_lsp" })
        end
        vim.diagnostic.set(ns, test_buf, many)

        local res = tools.get_diagnostics(test_path)
        assert.truthy(res:match("TRUNCADO") or res:match("exibindo os primeiros"))
        -- Verifica se não ultrapassou o limite absurdo
        assert.truthy(#res <= 4500)
    end)

    it("Deve retornar erro para path inexistente", function()
        local res = tools.get_diagnostics("/tmp/caminho_inexistente_absurdo_12345.lua")
        assert.truthy(res:match("ERRO"))
    end)

    it("Deve retornar erro quando o path não é fornecido (regra estrita)", function()
        -- Testa se o plugin bloqueia tentativa de adivinhar arquivo
        local res_nil = tools.get_diagnostics(nil)
        assert.truthy(res_nil:match("OBRIGATÓRIO"))
        
        local res_empty = tools.get_diagnostics("")
        assert.truthy(res_empty:match("OBRIGATÓRIO"))
    end)
end)




======== ./lua/multi_context/tests/scroller_spec.lua ========
-- lua/multi_context/tests/scroller_spec.lua
local scroller = require('multi_context.ui.scroller')

describe("Scroller Module (Smart Auto-Scroll):", function()
    it("Deve ativar streaming e seguir por padrao", function()
        scroller.start_streaming(1, nil)
        assert.is_true(scroller.state.is_streaming)
        assert.is_true(scroller.state.is_following)
    end)

    it("Deve desligar streaming ao solicitar", function()
        scroller.stop_streaming(1)
        assert.is_false(scroller.state.is_streaming)
    end)
end)




======== ./lua/multi_context/tests/swarm_phase21_spec.lua ========
local swarm = require('multi_context.swarm_manager')
local api_client = require('multi_context.api_client')
local popup = require('multi_context.ui.popup')
local agents = require('multi_context.agents')

describe("Fase 21 - Pipelines e Coreografia:", function()
    local orig_execute
    local orig_create_buf
    local orig_load_agents

    before_each(function()
        swarm.reset()
        
        -- Isolamos a rede
        orig_execute = api_client.execute
        -- Isolamos a UI
        orig_create_buf = popup.create_swarm_buffer
        popup.create_swarm_buffer = function() return 999 end
        
        -- Mockamos as personas para garantir o System Prompt
        orig_load_agents = agents.load_agents
        agents.load_agents = function()
            return {
                coder = { system_prompt = "Você é o Coder.", abstraction_level = "high" },
                qa = { system_prompt = "Você é o QA.", abstraction_level = "high" }
            }
        end
    end)

    after_each(function()
        api_client.execute = orig_execute
        popup.create_swarm_buffer = orig_create_buf
        agents.load_agents = orig_load_agents
    end)

    it("Passo 1: Deve processar 'chain' e 'allow_switch' no init_swarm", function()
        local ok = swarm.init_swarm('{"tasks":[{"chain":["coder", "qa"], "instruction": "F", "allow_switch": ["dba"]}]}')
        assert.is_true(ok)
        assert.are.same("coder", swarm.state.queue[1].agent)
        assert.are.same("qa", swarm.state.queue[1].chain[2])
    end)

    it("Passo 2: Deve reencarnar a tarefa na fila caso haja agentes restantes na chain", function()
        api_client.execute = function(msgs, start, chunk, done, err, cfg)
            chunk("<final_report>Terminei o código</final_report>")
            done(cfg, nil)
        end
        swarm.init_swarm('{"tasks":[{"chain":["coder", "qa"], "instruction": "F"}]}')
        swarm.state.workers = { { api = { name = "mock_api", abstraction_level = "high" }, busy = false } }
        swarm.dispatch_next()
        vim.wait(100, function() return #swarm.state.queue > 0 end, 5)

        assert.are.same(1, #swarm.state.queue)
        assert.are.same(0, #swarm.state.reports)
        assert.are.same("qa", swarm.state.queue[1].agent)
    end)

    it("Passo 3: Deve permitir troca de agente na mesma aba via switch_agent", function()
        local call_count = 0
        local prompts_usados = {}
        
        api_client.execute = function(msgs, start, chunk, done, err, cfg)
            call_count = call_count + 1
            table.insert(prompts_usados, msgs[1].content) -- Grava o System Prompt injetado neste turno!
            
            if call_count == 1 then
                -- O Coder invoca a troca pro QA
                chunk('<tool_call name="switch_agent">\n  <target_agent>qa</target_agent>\n</tool_call>')
                done(cfg, nil)
            else
                -- O QA responde com o relatório final (o loop termina aqui)
                chunk('<final_report>QA testou e aprovou</final_report>')
                done(cfg, nil)
            end
        end

        local json_payload = [[
        {
            "tasks":[
                { 
                    "agent": "coder",
                    "instruction": "Faça a feature",
                    "allow_switch": ["qa"]
                }
            ]
        }
        ]]
        
        swarm.init_swarm(json_payload)
        swarm.state.workers = { { api = { name = "mock_api", abstraction_level = "high" }, busy = false } }
        
        swarm.dispatch_next()
        
        -- Aguarda as chamadas recursivas terminarem (2 turnos)
        vim.wait(200, function() return call_count >= 2 end, 5)

        assert.are.same(2, call_count, "Deveriam ocorrer exatamente 2 turnos")
        
        -- Verifica se o cérebro da operação foi modificado no meio do caminho
        assert.truthy(prompts_usados[1]:match("Você é o Coder"), "O turno 1 deveria usar o prompt do Coder")
        assert.truthy(prompts_usados[2]:match("Você é o QA"), "O turno 2 deveria ter o prompt modificado dinamicamente para o QA")
        
        -- O report final pertence a essa sessão consolidada
        assert.are.same(0, #swarm.state.queue)
        assert.are.same(1, #swarm.state.reports)
        assert.truthy(swarm.state.reports[1].result:match("QA testou e aprovou"))
    end)
end)




======== ./lua/multi_context/tests/session_spec.lua ========
local utils = require('multi_context.utils')
local swarm = require('multi_context.swarm_manager')
local popup = require('multi_context.ui.popup')

describe("Fase 18.5 - Session & State Management:", function()
    before_each(function()
        swarm.reset()
        popup.swarm_buffers = {}
    end)

    it("Deve gerar tag de sessao e injetar o swarm_state", function()
        -- Simulando um estado complexo no enxame
        swarm.state.queue = { { agent = "qa", instruction = "teste unitario" } }
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"## User >>", "Oi, IA"})
        popup.popup_buf = buf
        
        local filename, exported_text = utils.build_workspace_content(buf, nil)
        
        assert.truthy(exported_text:match("<mctx_session id="), "Deve conter tag de sessao no topo")
        assert.truthy(exported_text:match("<swarm_state>"), "Deve conter tag de estado do enxame no final")
        assert.truthy(exported_text:match("qa"), "Deve conter os dados da fila exportados em JSON")
        assert.truthy(filename:match("%.mctx$"), "Deve gerar o nome do arquivo corretamente")
    end)
    
    it("Deve desserializar e reconstruir o enxame ao carregar o chat", function()
        local payload = [[
<mctx_session id="999" created="2026-04-21T00:00:00" updated="2026-04-21T00:00:00" />
## User >>
Teste
<swarm_state>
{"queue":[{"agent":"coder","instruction":"faz_algo"}], "buffers":[{"name":"coder","lines":["## IA >>","Codando..."]}]}
</swarm_state>
]]
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(payload, "\n", {plain=true}))
        
        -- Simulando Aba Main na UI
        popup.swarm_buffers = { { buf = buf, name = "Main" } }
        
        utils.load_workspace_state(buf)
        
        -- Afirmações de Ressurreição de Estado
        assert.are.same(1, #swarm.state.queue, "A fila devera ter voltado a vida")
        assert.are.same("coder", swarm.state.queue[1].agent)
        assert.truthy(#popup.swarm_buffers > 1, "Deve ter recriado o buffer do worker paralelo na memoria")
        assert.are.same("coder", popup.swarm_buffers[2].name)
    end)
end)

    it("Deve orquestrar o load pelo comando ToggleWorkspaceView (init.lua)", function()
        local init = require('multi_context.init')
        local utils = require('multi_context.utils')
        
        -- Configura um buffer simulando um arquivo aberto em disco
        local buf = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_buf_set_name(buf, "/caminho/falso/chat_123.mctx")
        vim.api.nvim_set_current_buf(buf)
        
        -- Simulamos a UI limpa
        popup.popup_win = nil
        init.current_workspace_file = nil
        
        -- Adiciona payload no buffer
        local payload = {
            '<mctx_session id="123" />',
            '## User >>',
            'Contexto'
        }
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, payload)
        
        -- Mockamos as funções pesadas da UI para não travar o ambiente Headless
        local orig_create_popup = popup.create_popup
        local was_popup_called = false
        popup.create_popup = function(b) 
            was_popup_called = true
            popup.popup_buf = b
        end
        
        -- Ação E2E: Usuário digita o comando para carregar a sessão!
        init.ToggleWorkspaceView()
        
        -- Asserts: O core do plugin tem que entender que isso é um load
        assert.truthy(init.current_workspace_file:match("chat_123%.mctx"), "O arquivo de workspace atual não foi setado!")
        assert.is_true(was_popup_called, "A janela flutuante não foi invocada pelo init.lua!")
        
        -- Cleanup
        popup.create_popup = orig_create_popup
    end)




======== ./lua/multi_context/tests/swarm_etapa5_spec.lua ========
-- lua/multi_context/tests/swarm_etapa5_spec.lua
local swarm = require('multi_context.swarm_manager')
local popup = require('multi_context.ui.popup')
local api_client = require('multi_context.api_client')
local config = require('multi_context.config')
local agents = require('multi_context.agents')

describe("Swarm Etapa 5 - Resiliência e UI Dinâmica:", function()
    local orig_execute

    before_each(function()
        orig_execute = api_client.execute
        swarm.reset()

        -- Garante ambiente limpo de janelas
        if popup.popup_win and vim.api.nvim_win_is_valid(popup.popup_win) then
            vim.api.nvim_win_close(popup.popup_win, true)
        end
        popup.swarm_buffers = {}
        popup.current_swarm_index = 1
        
        -- Mock de Config para 1 Worker
        config.get_spawn_apis = function()
            return {{ name = "mock_api", model = "mock_model", allow_spawn = true, abstraction_level = "high" }}
        end
    end)

    after_each(function()
        api_client.execute = orig_execute
    end)

    it("Deve realizar retry de uma tarefa se a API retornar string vazia", function()
        -- Mock da API para simular falha silenciosa (retorna vazio)
        api_client.execute = function(messages, on_start, on_chunk, on_done, on_error, force_api)
            -- Chama o on_done imediatamente sem chamar on_chunk (simulando texto vazio)
            on_done(force_api, nil)
        end

        swarm.init_swarm('{"tasks":[{"agent":"qa","instruction":"teste"}]}')
        swarm.dispatch_next()

        -- O worker terminou, identificou vazio, e DEVE ter devolvido a tarefa pra fila
        assert.are.same(1, #swarm.state.queue, "A tarefa deve voltar para a fila")
        assert.are.same(1, swarm.state.queue[1].retries, "O contador de retries deve ser 1")

        -- Dispara de novo, a API falha de novo (segunda tentativa vazia)
        swarm.dispatch_next()
        assert.are.same(1, #swarm.state.queue)
        assert.are.same(2, swarm.state.queue[1].retries, "O contador de retries deve ser 2")

        -- Dispara de novo (excedeu limite de retries)
        swarm.dispatch_next()
        assert.are.same(0, #swarm.state.queue, "Fila deve zerar após esgotar retries")
        assert.are.same(1, #swarm.state.reports)
        assert.truthy(swarm.state.reports[1].result:match("FALHA: A API falhou repetidas vezes"))
    end)

    it("Deve realizar retry de uma tarefa se a API retornar erro HTTP (Rate Limit)", function()
        -- Mock da API para simular Erro Bruto
        api_client.execute = function(messages, on_start, on_chunk, on_done, on_error, force_api)
            on_error("Rate Limit Exceeded")
        end

        swarm.init_swarm('{"tasks":[{"agent":"coder","instruction":"teste"}]}')
        swarm.dispatch_next()

        assert.are.same(1, #swarm.state.queue, "A tarefa deve voltar para a fila apos erro")
        assert.are.same(1, swarm.state.queue[1].retries)

        -- Simula segunda falha
        swarm.dispatch_next()
        assert.are.same(1, #swarm.state.queue)
        assert.are.same(2, swarm.state.queue[1].retries)

        -- Esgota limite
        swarm.dispatch_next()
        assert.are.same(0, #swarm.state.queue)
        assert.truthy(swarm.state.reports[1].result:match("ERRO FATAL APÓS TENTATIVAS"))
    end)

    it("Deve atualizar o titulo do Carrossel e calcular tokens dinamicamente", function()
        -- Cria a janela flutuante real (no ambiente headless)
        local main_buf, win = popup.create_popup("Buffer Principal")
        
        -- Cria o sub buffer do worker
        local sub_buf = popup.create_swarm_buffer("qa", "Instrucao teste", "api_teste")
        
        -- Força a atualização do título estando no Main (índice 1)
        popup.current_swarm_index = 1
        popup.update_title()
        
        local conf_main = vim.api.nvim_win_get_config(win)
        local title_main = type(conf_main.title) == "table" and conf_main.title[1][1] or conf_main.title or ""
        -- Verifica se o asterisco está no Main
        assert.truthy(title_main:match("%*%[1:Main%]"), "Deve destacar a aba Main")
        assert.truthy(title_main:match("%[2:qa%]"), "Não deve destacar a aba QA")
        assert.truthy(title_main:match("tokens"), "Deve conter a palavra tokens")

        -- Alterna para o buffer do Worker (índice 2)
        popup.cycle_swarm_buffer(1)
        
        local conf_sub = vim.api.nvim_win_get_config(win)
        local title_sub = type(conf_sub.title) == "table" and conf_sub.title[1][1] or conf_sub.title or ""
        assert.truthy(title_sub:match("%[1:Main%]"), "Não deve destacar a aba Main")
        assert.truthy(title_sub:match("%*%[2:qa%]"), "Deve destacar a aba QA")
    end)
    
    it("Deve confirmar a presença do agente @qa no acervo", function()
        local loaded = agents.load_agents()
        assert.is_not_nil(loaded["qa"], "O agente QA deve existir")
        assert.truthy(loaded["qa"].description:match("Qualidade"), "A descrição deve corresponder a um QA")
    end)

end)




======== ./lua/multi_context/tests/conversation_spec.lua ========
local conv = require('multi_context.conversation')
local config = require('multi_context.config')

describe("Conversation Module:", function()
    before_each(function()
        config.options.user_name = "Nardi"
    end)

    it("Deve encontrar a última linha de comando do usuário", function()
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
            "## Nardi >> primeirao",
            "## IA >> resposta",
            "## Nardi >> ultimo comando"
        })
        
        local idx, line = conv.find_last_user_line(buf)
        assert.are.same(2, idx) -- Neovim usa indexação 0-based via API
        assert.are.same("## Nardi >> ultimo comando", line)
    end)

    it("Deve ignorar mensagens de [Sistema] na hora de ler o último comando", function()
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
            "## Nardi >> faça algo",
            "## IA >> <tool_call...",
            "## Nardi >> [Sistema]: Ferramentas executadas"
        })
        -- O parser precisa enxergar a linha do sistema também, pois ela é a retroalimentação.
        local idx, line = conv.find_last_user_line(buf)
        assert.are.same(2, idx)
        assert.truthy(line:match("%[Sistema%]"))
    end)
end)

    it("Deve construir o array de mensagens (build_history) perfeitamente", function()
        local buf = vim.api.nvim_create_buf(false, true)
        
        -- Simulando um chat complexo com várias quebras de linha e rodapés
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
            "## Nardi >> Primeiro comando",
            "Detalhes do comando",
            "",
            "## IA (gpt-4) >>",
            "Resposta da IA",
            "Mais texto da IA",
            "",
            "## API atual: groq", -- Isso DEVE ser ignorado pelo parser
            "## Nardi >> Segundo comando"
        })
        
        local msgs = conv.build_history(buf)
        
        -- Verifica se gerou exatamente 3 blocos lógicos
        assert.are.same(3, #msgs)
        
        -- Bloco 1 (User)
        assert.are.same("user", msgs[1].role)
        assert.are.same("Primeiro comando\nDetalhes do comando", msgs[1].content)
        
        -- Bloco 2 (Assistant)
        assert.are.same("assistant", msgs[2].role)
        assert.are.same("Resposta da IA\nMais texto da IA", msgs[2].content)
        
        -- Bloco 3 (User)
        assert.are.same("user", msgs[3].role)
        assert.are.same("Segundo comando", msgs[3].content)
    end)




======== ./lua/multi_context/tests/prompt_parser_spec.lua ========
-- Stub do registry para o teste isolado
package.loaded['multi_context.skills.registry'] = {
    build_manual_for_skills = function(skills) return "=== SKILLS ===" end
}

local prompt_parser = require('multi_context.prompt_parser')
local config = require('multi_context.config')

describe("Fase 25 - Passo 2: O System Agent @archivist", function()
    local mock_agents = { 
        coder = { system_prompt = "Você programa." } 
    }

    before_each(function()
        config.options.watchdog = { mode = "auto", strategy = "semantic", fixed_target = 1500, percent = 0.3 }
    end)

    it("Deve carregar o System Prompt de Compressao com limite Semântico", function()
        config.options.watchdog.strategy = "semantic"
        
        -- O archivist não existe no mock_agents propositalmente
        local final_prompt = prompt_parser.build_system_prompt("Base", "Mem", "archivist", mock_agents, 5000)

        assert.truthy(final_prompt:match("Você é o @archivist do sistema"), "O Megaprompt deve ser ativado nativamente")
        assert.truthy(final_prompt:match("COMPRESSÃO SEMÂNTICA"), "O limite semântico deve estar presente no prompt")
    end)

    it("Deve injetar o valor exato no prompt caso a estrategia seja Percentual", function()
        config.options.watchdog.strategy = "percent"
        
        -- Simulando um chat com 5000 tokens e alvo de 30%
        local final_prompt = prompt_parser.build_system_prompt("Base", "Mem", "archivist", mock_agents, 5000)
        
        -- 30% de 5000 = 1500 tokens
        assert.truthy(final_prompt:match("MANDATÓRIO: A compressão é baseada num teto percentual"), "Estrategia percentual")
        assert.truthy(final_prompt:match("1500 tokens"), "O cálculo percentual exato (1500) deve estar hardcoded no prompt")
    end)

    it("Deve injetar o limite restrito caso a estrategia seja Fixo", function()
        config.options.watchdog.strategy = "fixed"
        config.options.watchdog.fixed_target = 999
        
        local final_prompt = prompt_parser.build_system_prompt("Base", "Mem", "archivist", mock_agents, 5000)
        
        assert.truthy(final_prompt:match("MANDATÓRIO: A compressão é agressiva"), "Estrategia fixa")
        assert.truthy(final_prompt:match("999 tokens"), "O valor alvo fixo deve ser imposto")
    end)
end)




======== ./lua/multi_context/tests/swarm_etapa1_spec.lua ========
local tool_parser = require('multi_context.tool_parser')
local config = require('multi_context.config')
local agents = require('multi_context.agents')

describe("Swarm Etapa 1 - Modelagem e Parser:", function()

    it("Deve extrair e decodificar corretamente o JSON rigoroso da tool spawn_swarm", function()
        local ticks = string.rep("`", 3)
        local payload = "Algum texto antes\n" ..
            "<tool_call name=\"spawn_swarm\">\n" ..
            ticks .. "json\n" ..
            [[
            {
              "tasks":[
                {
                  "agent": "coder",
                  "context":["src/login.lua"],
                  "instruction": "Implemente a rota"
                }
              ]
            }
            ]] .. "\n" .. ticks .. "\n" ..
            "</tool_call>\n" ..
            "Algum texto depois"

        local parsed = tool_parser.parse_next_tool(payload, 1)
        assert.is_not_nil(parsed)
        assert.are.same("spawn_swarm", parsed.name)
        
        local ok, decoded = pcall(vim.fn.json_decode, vim.trim(parsed.inner))
        assert.is_true(ok)
        assert.are.same("coder", decoded.tasks[1].agent)
    end)

    it("Deve identificar e retornar corretamente APIs disponíveis como workers", function()
        local mock_cfg = { 
            default_api = "api_principal", 
            apis = { 
                { name = "api_principal", url = "http..." },
                { name = "worker_1", url = "http...", allow_spawn = true },
                { name = "worker_2", url = "http...", allow_spawn = true }
            } 
        }
        
        local tmp_json = os.tmpname()
        local f = io.open(tmp_json, "w")
        f:write(vim.fn.json_encode(mock_cfg))
        f:close()

        config.options.config_path = tmp_json
        
        local spawn_workers = config.get_spawn_apis()
        assert.is_not_nil(spawn_workers)
        assert.are.same(2, #spawn_workers)
        assert.are.same("worker_1", spawn_workers[1].name)
        assert.are.same("worker_2", spawn_workers[2].name)
        
        os.remove(tmp_json)
    end)

    it("Deve garantir que a persona @tech_lead exista com a skill correta", function()
        local loaded_agents = agents.load_agents()
        assert.is_not_nil(loaded_agents["tech_lead"])
        
        local has_spawn_skill = false
        if loaded_agents["tech_lead"] and loaded_agents["tech_lead"].skills then
            for _, skill in ipairs(loaded_agents["tech_lead"].skills) do
                if skill == "spawn_swarm" then has_spawn_skill = true end
            end
        end
        assert.is_true(has_spawn_skill)
    end)
end)




======== ./lua/multi_context/tests/config_spec.lua ========
 -- lua/multi_context/tests/config_spec.lua -- Nota: O require foi movido para dentro dos blocos para respeitar a ordem de inicialização do minimal_init.lua

describe("Config Module:", function()
  local config

  before_each(function()
    -- Limpa o cache para garantir que o setup() do minimal_init seja respeitado
    package.loaded['multi_context.config'] = nil
    config = require('multi_context.config')
  end)

  it("Deve carregar as opções default corretamente", function()
    -- O minimal_init.lua já chamou setup({ user_name = "Nardi" })
    -- Mas como limpamos o cache, vamos garantir que o setup rode com o valor esperado
    config.setup({ user_name = "Nardi" })
    assert.are.same("Nardi", config.options.user_name)
  end)

  it("Deve mesclar opções do usuário usando setup() sem perder os defaults", function()
    config.options = vim.deepcopy(config.defaults)
    config.setup({ user_name = "NovoUsuario", appearance = { width = 0.9 } })

    -- Alterou o que foi pedido
    assert.are.same("NovoUsuario", config.options.user_name)
    assert.are.same(0.9, config.options.appearance.width)
    -- Manteve o que NÃO foi pedido (Deep Merge)
    assert.are.same("rounded", config.options.appearance.border)
  end)
end)

describe("Config Module (Manipulacao de Arquivo JSON):", function()
  local config

  it("Deve ler e alterar APIs usando um JSON em disco", function()
    -- Garante reload limpo
    package.loaded['multi_context.config'] = nil
    config = require('multi_context.config')

    local tmp_json = os.tmpname()
    -- Simulando o arquivo JSON criado pelo usuario
    local mock_cfg = { default_api = "api_A", apis = { { name = "api_A" }, { name = "api_B" } } }
    local f = io.open(tmp_json, "w")
    f:write(vim.fn.json_encode(mock_cfg))
    f:close()

    -- Força o plugin a olhar para o nosso arquivo falso
    config.options.config_path = tmp_json

    -- Testa extração de nomes
    local names = config.get_api_names()
    assert.are.same({"api_A", "api_B"}, names)

    -- Testa buscar a default atual
    assert.are.same("api_A", config.get_current_api())

    -- Testa trocar a API via código
    config.set_selected_api("api_B")
    assert.are.same("api_B", config.get_current_api())

    os.remove(tmp_json)
  end)
end) 

describe("Fase 25 - Configurações do Guardião 2.0:", function()
  local config = require('multi_context.config')

  it("Deve carregar as opções default de Compressao e Modos", function()
    -- Garante reload limpo para pegar defaults
    package.loaded['multi_context.config'] = nil
    config = require('multi_context.config')
    config.setup()
    
    assert.is_not_nil(config.options.watchdog, "A tabela watchdog deve existir")
    assert.are.same("off", config.options.watchdog.mode, "O padrao deve ser off para nao assustar o usuario")
    assert.are.same("semantic", config.options.watchdog.strategy, "O padrao deve ser semantic")
    assert.are.same(0.3, config.options.watchdog.percent, "Percentual alvo padrao deve ser 30%")
    assert.are.same(1500, config.options.watchdog.fixed_target, "Alvo fixo padrao deve ser 1500 tokens")
  end)
end)




======== ./lua/multi_context/tests/swarm_etapa2_spec.lua ========
local popup = require('multi_context.ui.popup')
local api = vim.api

describe("Swarm Etapa 2 - Multi-Buffers e UI:", function()
    before_each(function()
        -- Limpa qualquer janela flutuante e reseta o estado antes de cada teste
        if popup.popup_win and api.nvim_win_is_valid(popup.popup_win) then
            api.nvim_win_close(popup.popup_win, true)
        end
        popup.popup_win = nil
        popup.popup_buf = nil
        popup.swarm_buffers = {}
        popup.current_swarm_index = 1
    end)

    it("Deve criar o popup principal e registrar como buffer de indice 1", function()
        local buf, win = popup.create_popup("Teste Main")
        
        assert.is_not_nil(popup.swarm_buffers)
        assert.are.same(1, #popup.swarm_buffers)
        assert.are.same(buf, popup.swarm_buffers[1].buf)
        assert.are.same("Main", popup.swarm_buffers[1].name)
    end)

    it("Deve criar sub-buffers isolados para workers", function()
        popup.create_popup("Main")
        local sub_buf = popup.create_swarm_buffer("coder", "Tarefa: refatorar")
        
        assert.are.same(2, #popup.swarm_buffers)
        assert.are.same("coder", popup.swarm_buffers[2].name)
        assert.are.same(sub_buf, popup.swarm_buffers[2].buf)
        
        -- Verifica o isolamento rígido
        assert.are.same("nofile", vim.bo[sub_buf].buftype)
        assert.are.same("hide", vim.bo[sub_buf].bufhidden)
        assert.are.same("multicontext_chat", vim.bo[sub_buf].filetype)
    end)

    it("Deve alternar entre os buffers circularmente (Tab/S-Tab)", function()
        local main_buf, win = popup.create_popup("Main")
        local b2 = popup.create_swarm_buffer("coder", "codigo")
        local b3 = popup.create_swarm_buffer("qa", "testes")

        assert.are.same(1, popup.current_swarm_index)
        assert.are.same(main_buf, api.nvim_win_get_buf(win))

        -- Avança para o 2
        popup.cycle_swarm_buffer(1)
        assert.are.same(2, popup.current_swarm_index)
        assert.are.same(b2, api.nvim_win_get_buf(win))

        -- Avança para o 3
        popup.cycle_swarm_buffer(1)
        assert.are.same(3, popup.current_swarm_index)
        assert.are.same(b3, api.nvim_win_get_buf(win))

        -- Avança para o 1 (Circular, passou do limite)
        popup.cycle_swarm_buffer(1)
        assert.are.same(1, popup.current_swarm_index)
        assert.are.same(main_buf, api.nvim_win_get_buf(win))

        -- Volta para o 3 (Circular invertido, recuou do 1)
        popup.cycle_swarm_buffer(-1)
        assert.are.same(3, popup.current_swarm_index)
        assert.are.same(b3, api.nvim_win_get_buf(win))
    end)
end)




======== ./lua/multi_context/tests/skills_manager_spec.lua ========
local skills = require('multi_context.skills_manager')
local prompt_parser = require('multi_context.prompt_parser')
local tool_runner = require('multi_context.tool_runner')

describe("Fase 19 - Sistema de Skills (Extensibilidade):", function()
    local test_dir = "/tmp/mctx_mock_skills"

    before_each(function()
        -- Usa a API nativa do Neovim para garantir que a pasta seja criada com sucesso
        vim.fn.mkdir(test_dir, "p")
        skills.reset()
    end)

    after_each(function()
        vim.fn.delete(test_dir, "rf")
    end)

    it("Deve carregar e validar uma skill customizada corretamente", function()
        local valid_skill = "return { name = 'minha_skill', description = 'Uma skill de teste', execute = function(args) return 'Executado: ' .. (args.texto or '') end }"
        local f = io.open(test_dir .. "/minha_skill.lua", "w")
        f:write(valid_skill)
        f:close()

        skills.load_skills(test_dir)
        local loaded = skills.get_skills()

        assert.is_not_nil(loaded["minha_skill"])
        assert.are.same("minha_skill", loaded["minha_skill"].name)
        assert.are.same("Executado: teste", loaded["minha_skill"].execute({texto = "teste"}))
    end)

    it("Deve ignorar arquivos que não retornam uma tabela de skill valida", function()
        local invalid_skill = "return { name = 'skill_quebrada', description = 'Falta o execute' }"
        local f = io.open(test_dir .. "/invalid.lua", "w")
        f:write(invalid_skill)
        f:close()

        local not_lua = "isso nao e codigo lua valido"
        local f2 = io.open(test_dir .. "/erro_sintaxe.lua", "w")
        f2:write(not_lua)
        f2:close()

        skills.load_skills(test_dir)
        local loaded = skills.get_skills()

        assert.is_nil(loaded["skill_quebrada"])
        local count = 0
        for _ in pairs(loaded) do count = count + 1 end
        assert.are.same(0, count)
    end)

    it("Deve injetar a definicao da skill customizada no prompt do sistema", function()
        skills.reset()
        skills.skills["calc_especial"] = {
            name = "calc_especial",
            description = "Calculo complexo customizado",
            parameters = { { name = "valor", type = "number", desc = "O valor base" } }
        }

        local full_prompt = prompt_parser.build_system_prompt("System Base", nil, nil, {})
        
        assert.truthy(full_prompt:match("calc_especial"))
        assert.truthy(full_prompt:match("Calculo complexo customizado"))
        assert.truthy(full_prompt:match('name="valor"'))
    end)

    it("Deve rotear e executar uma skill customizada atraves do tool_runner", function()
        skills.reset()
        skills.skills["echo_skill"] = {
            name = "echo_skill",
            description = "Skill que repete uma mensagem",
            parameters = { { name = "message", type = "string" } },
            execute = function(args) return "ECHOED: " .. (args.message or "vazio") end
        }

        local parsed_tag = { name = "echo_skill", inner = "\n  <message>Hello World</message>\n" }
        local approve_ref = { value = true }
        local output = tool_runner.execute(parsed_tag, true, approve_ref, nil)

        assert.truthy(output:match("ECHOED: Hello World"))
    end)

    it("Deve limpar skills apagadas e recarregar a lista (Hot-Reload)", function()
        skills.reset()
        skills.skills["skill_apagada"] = { name = "skill_apagada", description = "Old", execute = function() end }

        local valid_skill = "return { name = 'skill_nova', description = 'Nova', execute = function() return 'ok' end }"
        local f = io.open(test_dir .. "/skill_nova.lua", "w")
        f:write(valid_skill)
        f:close()

        skills.load_skills(test_dir)
        local loaded = skills.get_skills()

        assert.is_nil(loaded["skill_apagada"], "A skill antiga deve ser removida da memoria no reload")
        assert.is_not_nil(loaded["skill_nova"], "A nova skill deve ser carregada imediatamente")
    end)

end)




======== ./lua/multi_context/tests/archivist_spec.lua ========
local init = require('multi_context') -- Usando require na raiz para capturar o mesmo cache!
local popup = require('multi_context.ui.popup')
local react_loop = require('multi_context.react_loop')
local memory_tracker = require('multi_context.memory_tracker')

describe("Fase 22 - Passo 3: A Persona @archivist e a Compressao", function()
    local buf
    local orig_send, orig_defer
    local send_called = false

    before_each(function()
        send_called = false
        orig_send = init.SendFromPopup
        init.SendFromPopup = function() send_called = true end

        orig_defer = vim.defer_fn
        vim.defer_fn = function(cb, ms) cb() end

        buf = vim.api.nvim_create_buf(false, true)
        local archivist_response = {
            "## IA (archivist) >>",
            "<genesis>Criar um plugin Neovim</genesis>",
            "<plan>Refatorar init.lua</plan>",
            "<journey>- Swarm feito</journey>",
            "<now>Testando archivist</now>"
        }
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, archivist_response)
        popup.popup_buf = buf

        react_loop.state.pending_user_prompt = "Este e o meu comando original"
        react_loop.state.active_agent = "archivist"
        memory_tracker.state.count = 5 
    end)

    after_each(function()
        init.SendFromPopup = orig_send
        vim.defer_fn = orig_defer
        vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("Deve extrair o XML Quadripartite, limpar o buffer e re-anexar o prompt pendente", function()
        init.HandleArchivistCompression(1)
        
        local final_content = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
        
        assert.truthy(final_content:match("=== MEMÓRIA CONSOLIDADA %(QUADRIPARTITE%) ==="), "Deve ter o header de memoria")
        assert.truthy(final_content:match("<genesis>\nCriar um plugin Neovim\n</genesis>"), "Deve formatar genesis")
        assert.truthy(final_content:match("<plan>\nRefatorar init.lua\n</plan>"), "Deve formatar plan")
        assert.truthy(final_content:match("Este e o meu comando original"), "Deve re-injetar o prompt pendente")
        
        assert.is_nil(react_loop.state.pending_user_prompt)
        assert.is_nil(react_loop.state.active_agent)
        assert.are.same(0, memory_tracker.state.count)
        assert.is_true(send_called, "O motor de ReAct deve ter sido religado")
    end)
end)




======== ./lua/multi_context/tests/react_loop_spec.lua ========
-- lua/multi_context/tests/react_loop_spec.lua
local react_loop = require('multi_context.react_loop')

describe("ReAct Loop Module:", function()
    before_each(function()
        react_loop.reset_turn()
    end)

    it("Deve resetar o estado corretamente", function()
        react_loop.state.is_autonomous = true
        react_loop.state.auto_loop_count = 5
        
        react_loop.reset_turn()
        
        assert.is_false(react_loop.state.is_autonomous)
        assert.are.same(0, react_loop.state.auto_loop_count)
    end)

    it("Deve interromper a execução quando atingir 15 loops (Circuit Breaker)", function()
        -- Simulando 14 iterações aprovadas
        for i = 1, 14 do
            local abort = react_loop.check_circuit_breaker()
            assert.is_false(abort)
        end
        
        -- A iteração 15 deve abortar
        local final_abort = react_loop.check_circuit_breaker()
        assert.is_true(final_abort)
        assert.are.same(15, react_loop.state.auto_loop_count)
    end)
end)




======== ./lua/multi_context/tests/abstraction_level_spec.lua ========
local agents = require('multi_context.agents')
local config = require('multi_context.config')

describe("Fase 20 - Passo 1 (Abstraction Levels):", function()
    local orig_json_decode

    before_each(function()
        orig_json_decode = vim.fn.json_decode
    end)

    after_each(function()
        vim.fn.json_decode = orig_json_decode
    end)

    it("Deve definir abstraction_level='high' para agentes sem o campo configurado", function()
        vim.fn.json_decode = function(...)
            return {
                agente_antigo = { system_prompt = "Sou antigo" },
                agente_novo = { system_prompt = "Sou novo", abstraction_level = "low" }
            }
        end
        
        local loaded = agents.load_agents()
        assert.is_not_nil(loaded["agente_antigo"], "O agente_antigo deve carregar")
        assert.are.same("high", loaded["agente_antigo"].abstraction_level, "Default do agente deve ser high")
        assert.are.same("low", loaded["agente_novo"].abstraction_level, "Deve respeitar o valor definido no agente")
    end)
    
    it("Deve definir abstraction_level='medium' para APIs sem o campo configurado", function()
        vim.fn.json_decode = function(...)
            -- CORREÇÃO: O Mock agora simula a estrutura real do json com a chave 'apis'
            return {
                apis = {
                    { name = "api_antiga", model = "gpt-3.5" },
                    { name = "api_nova", model = "gpt-4", abstraction_level = "high" }
                }
            }
        end
        
        local cfg = config.load_api_config()
        assert.is_not_nil(cfg, "A configuracao de APIs deve carregar")
        
        local api_antiga_level = nil
        local api_nova_level = nil
        
        for _, api in ipairs(cfg.apis) do
            if api.name == "api_antiga" then api_antiga_level = api.abstraction_level end
            if api.name == "api_nova" then api_nova_level = api.abstraction_level end
        end
        
        assert.are.same("medium", api_antiga_level, "Default da API deve ser medium")
        assert.are.same("high", api_nova_level, "Deve respeitar o valor definido na API")
    end)
end)




======== ./lua/multi_context/tests/tools_spec.lua ========
local tools = require('multi_context.tools')

describe("Tools Module (Agentes Autônomos):", function()
    local tmp_file = os.tmpname()

    after_each(function()
        os.remove(tmp_file) -- Limpa lixo após os testes
    end)

    it("Deve criar e sobrescrever um arquivo (edit_file)", function()
        local res = tools.edit_file(tmp_file, "ola mundo\nteste")
        assert.truthy(res:match("SUCESSO"))
        
        local lines = vim.fn.readfile(tmp_file)
        assert.are.same({"ola mundo", "teste"}, lines)
    end)

    it("Deve editar cirurgicamente um arquivo mantendo as pontas (replace_lines)", function()
        -- Preparando arquivo inicial
        tools.edit_file(tmp_file, "Linha 1\nLinha 2\nLinha 3\nLinha 4")
        
        -- Substituindo as linhas 2 e 3
        local res = tools.replace_lines(tmp_file, 2, 3, "NOVA 2\nNOVA 3")
        assert.truthy(res:match("SUCESSO"))
        
        local lines = vim.fn.readfile(tmp_file)
        assert.are.same({"Linha 1", "NOVA 2", "NOVA 3", "Linha 4"}, lines)
    end)

    it("Deve limpar Markdown intruso do código fonte ao salvar arquivos", function()
        -- Simula a IA enviando ```lua\n...\n```
        local payload_sujo = "```lua\nlocal a = 1\n```"
        tools.edit_file(tmp_file, payload_sujo)
        
        local lines = vim.fn.readfile(tmp_file)
        -- O parser da ferramenta deve ter removido as crases
        assert.are.same({"local a = 1"}, lines)
    end)
end)

    it("Deve retornar erro amigavel ao ler arquivo que nao existe (read_file)", function()
        local res = tools.read_file("caminho_inexistente_alucinacao.txt")
        assert.truthy(res:match("ERRO: Arquivo não encontrado"))
    end)

    it("Deve retornar erro se a IA nao enviar o path", function()
        local res = tools.read_file(nil)
        assert.truthy(res:match("ERRO"))
        
        local res2 = tools.read_file("")
        assert.truthy(res2:match("ERRO"))
    end)

    it("Deve proteger replace_lines contra parametros invalidos", function()
        local res = tools.replace_lines("arquivo.txt", "nao_sou_numero", 15, "conteudo")
        assert.truthy(res:match("ERRO: 'start' e 'end' devem ser números"))
    end)

describe("Tools Module (Execucao de Shell):", function()
    local tools = require('multi_context.tools')

    it("Deve executar run_shell e retornar SUCESSO com a saida do terminal", function()
        local res = tools.run_shell("echo 'Testando_Terminal_123'")
        assert.truthy(res:match("SUCESSO"))
        assert.truthy(res:match("Testando_Terminal_123"))
    end)

    it("Deve retornar status de FALHA se o comando shell nao existir", function()
        local res = tools.run_shell("comando_bizarro_que_nao_existe_123")
        assert.truthy(res:match("FALHA"))
        -- O erro exato do bash varia entre sistemas, mas a tag FALHA deve estar lá.
    end)
end)




======== ./lua/multi_context/tests/squads_spec.lua ========
local squads = require('multi_context.squads')

describe("Fase 23 - Passo 1: Loader de Squads", function()
    local test_dir = "/tmp/mctx_squads_test"

    before_each(function()
        vim.fn.mkdir(test_dir, "p")
        squads.squads_file = test_dir .. "/mctx_squads.json"
    end)

    after_each(function()
        vim.fn.delete(test_dir, "rf")
    end)

    it("Deve criar o arquivo padrao caso nao exista e carregar corretamente", function()
        vim.fn.delete(squads.squads_file)
        
        local loaded = squads.load_squads()
        
        assert.is_not_nil(loaded["squad_dev"], "O squad padrao deve ser criado")
        assert.are.same("tech_lead", loaded["squad_dev"].tasks[1].agent)
        assert.are.same("coder", loaded["squad_dev"].tasks[1].chain[1])
    end)

    it("Deve extrair a lista de nomes dos squads", function()
        local mock_data = { squad_ux = {}, squad_backend = {} }
        vim.fn.writefile({vim.fn.json_encode(mock_data)}, squads.squads_file)
        
        local names = squads.get_squad_names()
        assert.are.same(2, #names)
        
        -- Garante que leu corretamente os arquivos mocados e ordenou
        assert.are.same("squad_backend", names[1])
        assert.are.same("squad_ux", names[2])
    end)
end)




======== ./lua/multi_context/tests/queue_editor_spec.lua ========
local queue_editor = require('multi_context.queue_editor')
local config = require('multi_context.config')

describe("Queue Editor Module:", function()
    local orig_load, orig_save, orig_notify
    local saved_cfg = nil

    before_each(function()
        orig_load = config.load_api_config
        orig_save = config.save_api_config
        orig_notify = vim.notify
        
        vim.notify = function() end

        -- Mock do arquivo de configuração JSON
        config.load_api_config = function()
            return {
                apis = {
                    { name = "api_principal", allow_spawn = false },
                    { name = "api_worker", allow_spawn = true }
                }
            }
        end
        
        -- Mock para interceptar o salvamento
        config.save_api_config = function(cfg)
            saved_cfg = cfg
            return true
        end
    end)

    after_each(function()
        config.load_api_config = orig_load
        config.save_api_config = orig_save
        vim.notify = orig_notify
        saved_cfg = nil
    end)

    it("Deve renderizar os marcadores allow_spawn, inverter os valores e salvar", function()
        -- Abre o editor (cria o buffer UI)
        queue_editor.open_editor()
        
        local buf = vim.api.nvim_get_current_buf()
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        
        -- Verifica renderização inicial
        assert.truthy(lines[1]:match("%[ %] api_principal"), "API Principal deve nascer desmarcada para spawn")
        assert.truthy(lines[2]:match("%[x%] api_worker"), "API Worker deve nascer marcada para spawn")
        
        -- Simulamos a edição pelo usuário (invertendo as flags e mudando a ordem)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
            "[ ] api_worker",
            "[x] api_principal"
        })
        
        -- Disparamos o evento de salvamento (comando :w)
        vim.api.nvim_exec_autocmds("BufWriteCmd", { buffer = buf })
        
        -- Verificamos se o parser processou corretamente a UI de volta para a estrutura de dados
        assert.is_not_nil(saved_cfg)
        
        -- api_worker subiu e perdeu o spawn
        assert.are.same("api_worker", saved_cfg.apis[1].name)
        assert.is_false(saved_cfg.apis[1].allow_spawn)
        
        -- api_principal desceu e ganhou o spawn
        assert.are.same("api_principal", saved_cfg.apis[2].name)
        assert.is_true(saved_cfg.apis[2].allow_spawn)
    end)
end)




======== ./lua/multi_context/tests/swarm_etapa3_spec.lua ========
-- lua/multi_context/tests/swarm_etapa3_spec.lua
local popup = require('multi_context.ui.popup')
local api_client = require('multi_context.api_client')

describe("Swarm Etapa 3 - Manager e Fila:", function()
    local swarm
    local orig_popup_create, orig_api_execute

    before_each(function()
        -- 1. Mock correto do config (preservando as options padrão)
        local config = require('multi_context.config')
        config.options = config.options or { user_name = "User" }
        config.get_spawn_apis = function()
            return {
                { name = "worker_1", abstraction_level = "high", model = "model_A", allow_spawn = true },
                { name = "worker_2", abstraction_level = "high", model = "model_B", allow_spawn = true }
            }
        end
        
        -- 2. Isolando a UI (Impede que a janela seja criada no teste de fila)
        orig_popup_create = popup.create_swarm_buffer
        popup.create_swarm_buffer = function(agent, instr) return 999 end

        -- 3. Isolando a Rede (Impede requisições HTTP falsas)
        orig_api_execute = api_client.execute
        api_client.execute = function() end

        package.loaded['multi_context.swarm_manager'] = nil
        swarm = require('multi_context.swarm_manager')
        swarm.reset()
    end)

    after_each(function()
        -- Restaurando os originais
        popup.create_swarm_buffer = orig_popup_create
        api_client.execute = orig_api_execute
    end)

    it("Deve inicializar a fila lendo o JSON do Tech Lead", function()
        local json_payload = [[
        {
            "tasks":[
                { "agent": "coder", "context":["main.lua"], "instruction": "T1" },
                { "agent": "qa", "context":["main.lua"], "instruction": "T2" }
            ]
        }
        ]]
        
        local ok = swarm.init_swarm(json_payload)
        assert.is_true(ok)
        assert.are.same(2, #swarm.state.queue)
        assert.are.same(2, #swarm.state.workers)
        assert.are.same("coder", swarm.state.queue[1].agent)
    end)

    it("Deve transferir tarefas da fila para workers respeitando o limite (Dispatch)", function()
        swarm.state.queue = {
            { agent = "a1", instruction = "1" },
            { agent = "a2", instruction = "2" },
            { agent = "a3", instruction = "3" }
        }
        
        swarm.state.workers = {
            { api = { name = "w1", abstraction_level = "high" }, busy = false },
            { api = { name = "w2", abstraction_level = "high" }, busy = false }
        }

        -- Agora pode rodar o dispatch_next com segurança sem explodir a UI
        swarm.dispatch_next()

        assert.are.same(1, #swarm.state.queue)
        
        local active_count = 0
        for _, w in ipairs(swarm.state.workers) do
            if w.busy then active_count = active_count + 1 end
        end
        assert.are.same(2, active_count)
    end)
end)




======== ./lua/multi_context/tests/prompt_optimization_spec.lua ========
local registry = require('multi_context.skills.registry')
local prompt_parser = require('multi_context.prompt_parser')

describe("Fase 24 - Otimização de System Prompt (Token Saving):", function()
    local orig_get_doc

    before_each(function()
        orig_get_doc = registry.get_skill_doc
        registry.get_skill_doc = function(name)
            return "<mock>1</mock>"
        end
    end)

    after_each(function()
        registry.get_skill_doc = orig_get_doc
    end)

    it("O cabeçalho do manual de habilidades deve ser altamente sintetizado", function()
        local manual = registry.build_manual_for_skills({"mock_skill"})
        
        -- Garante que as palavras chaves existam para os testes antigos continuarem passando
        assert.truthy(manual:match("FERRAMENTAS DO SISTEMA"), "Deve conter FERRAMENTAS DO SISTEMA")
        assert.truthy(manual:match("XML"), "Deve reforçar XML")
        assert.truthy(manual:match("get_diagnostics"), "Deve avisar sobre o auto-LSP")
        
        -- A grande verificação de economia: o texto original tinha ~660 caracteres. 
        -- Vamos forçar o tamanho do cabeçalho + mock a ser menor que 280 chars
        assert.is_true(#manual < 280, "O manual base deve ser hiper-sintético para economizar tokens. Tamanho atual: " .. #manual)
    end)
    
    it("O system prompt base deve ser limpo e não possuir gorduras", function()
        local prompt = prompt_parser.build_system_prompt("Base", "Mem", "coder", {coder = {system_prompt="sys", skills={}}})
        
        -- Verifica as palavras chave dos testes antigos
        assert.truthy(prompt:match("ESTADO ATUAL DO PROJETO"))
        assert.truthy(prompt:match("INSTRUÇÕES DO AGENTE:"))
        
        -- Proíbe prolixidade (estas palavras estavam no antigo prompt de parser e gastavam tokens)
        assert.falsy(prompt:match("sempre que finalizar uma tarefa para não perder a memória"), "Retire explicações longas sobre o CONTEXT.md")
    end)
end)




======== ./lua/multi_context/tests/watchdog_spec.lua ========
local init = require('multi_context')
local memory_tracker = require('multi_context.memory_tracker')
local api_client = require('multi_context.api_client')
local popup = require('multi_context.ui.popup')
local config = require('multi_context.config')
local react_loop = require('multi_context.react_loop')

describe("Fase 22 - Passo 2: O Interceptador do Watchdog", function()
    local orig_execute, orig_predict, orig_defer
    local captured_requests = {}
    local buf

    before_each(function()
        captured_requests = {}
        react_loop.state.pending_user_prompt = nil
        react_loop.state.active_agent = nil
        
        config.options.cognitive_horizon = 2000
        config.options.user_tolerance = 1.0
        
        orig_defer = vim.defer_fn
        vim.defer_fn = function(cb, ms) cb() end
        
        orig_execute = api_client.execute
        api_client.execute = function(msgs, on_start, on_chunk, on_done)
            table.insert(captured_requests, msgs)
            if on_start then on_start(999) end
            if on_done then on_done({name="mock"}, {}) end
        end

        buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "## Nardi >>", "Faça uma refatoração enorme." })
        popup.popup_buf = buf
        
        orig_predict = memory_tracker.predict_next_total
    end)

    after_each(function()
        api_client.execute = orig_execute
        memory_tracker.predict_next_total = orig_predict
        vim.defer_fn = orig_defer
        vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("Deve INTERCEPTAR a requisicao e injetar o modelo Quadripartite se estourar, e depois religar sozinho", function()
        local call_count = 0
        memory_tracker.predict_next_total = function() 
            call_count = call_count + 1
            if call_count == 1 then return 2500 else return 1000 end
        end
        
        init.SendFromPopup()
        
        assert.are.same(2, #captured_requests, "O Motor deve ter feito a chamada do Guardiao E religado automaticamente depois!")
        
        local arquivista_msg = captured_requests[1][#captured_requests[1]].content
        assert.truthy(arquivista_msg:match("Quadripartite"))
        assert.truthy(arquivista_msg:match("<plan>"))
        
        local user_restored_msg = captured_requests[2][#captured_requests[2]].content
        assert.truthy(user_restored_msg:match("Faça uma refatoração enorme"), "A segunda requisicao deve ser a restauracao do user")
    end)
end)




======== ./lua/multi_context/tests/context_builders_spec.lua ========
local ctx = require('multi_context.context_builders')

describe("Context Builders Module:", function()
    it("Deve extrair o contexto do buffer atual corretamente", function()
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"linhaA", "linhaB"})
        vim.api.nvim_set_current_buf(buf)
        
        local res = ctx.get_current_buffer()
        assert.truthy(res:match("=== BUFFER ATUAL ==="))
        assert.truthy(res:match("linhaA"))
        assert.truthy(res:match("linhaB"))
    end)

    it("Deve extrair apenas as linhas da selecao visual (com range)", function()
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"L1", "L2", "L3", "L4"})
        vim.api.nvim_set_current_buf(buf)
        
        local res = ctx.get_visual_selection(2, 3)
        assert.truthy(res:match("SELEÇÃO %(linhas 2%-3%)"))
        assert.truthy(res:match("L2"))
        assert.truthy(res:match("L3"))
        assert.falsy(res:match("L1"))
        assert.falsy(res:match("L4"))
    end)
    
    it("Deve corrigir a ordem se o range for passado invertido (baixo pra cima)", function()
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"A", "B", "C"})
        vim.api.nvim_set_current_buf(buf)
        
        -- Selecionou da linha 3 até a 1
        local res = ctx.get_visual_selection(3, 1)
        assert.truthy(res:match("SELEÇÃO %(linhas 1%-3%)"))
    end)
end)




======== ./lua/multi_context/tests/prompt_squads_spec.lua ========
local prompt_parser = require('multi_context.prompt_parser')

-- Substitui dependência em disco por um mock em memória
package.loaded['multi_context.squads'] = {
    load_squads = function()
        return {
            squad_ux = {
                tasks = {
                    { agent = "tech_lead", instruction = "UX Design", chain = {"frontend"} }
                }
            }
        }
    end
}

describe("Fase 23 - Passo 2: O Compilador de Meta-Agentes", function()
    it("Deve detectar a invocacao de um squad e transpilar para spawn_swarm JSON", function()
        -- Simulando menção a squad_ux no chat
        local raw = "Gere uma tela de login @squad_ux"
        local mock_agents = { tech_lead = {} } -- agentes não importam aqui
        
        -- Garante que o parser seja re-requisitado para pegar o mock de squads
        package.loaded['multi_context.prompt_parser'] = nil
        local parser = require('multi_context.prompt_parser')
        
        local parsed = parser.parse_user_input(raw, mock_agents)
        
        -- Ao invés de mandar um texto cru, deve ter envelopado como tech_lead rodando spawn_swarm
        assert.are.same("tech_lead", parsed.agent_name)
        assert.truthy(parsed.text_to_send:match("<tool_call name=\"spawn_swarm\">"), "Deve engatilhar o spawn_swarm")
        
        -- CORREÇÃO AQUI: Tolerância a espaçamentos na conversão JSON (ex: {"agent": "tech_lead"})
        assert.truthy(parsed.text_to_send:match('"agent"%s*:%s*"tech_lead"'), "JSON do squad deve estar injetado")
        
        assert.truthy(parsed.text_to_send:match("UX Design"), "A instrução original do squad deve estar no JSON")
        assert.truthy(parsed.text_to_send:match("Gere uma tela de login"), "A intent do usuario foi apensada a instrucao")
    end)
end)




======== ./lua/multi_context/tests/swarm_etapa4_spec.lua ========
-- lua/multi_context/tests/swarm_etapa4_spec.lua
local swarm = require('multi_context.swarm_manager')
local popup = require('multi_context.ui.popup')
local api_client = require('multi_context.api_client')

describe("Swarm Etapa 4 - Execucao Assincrona e Merge:", function()
    local original_create_buf, original_execute
    local executed_tasks = {}
    local final_summary = nil

    before_each(function()
        executed_tasks = {}
        final_summary = nil
        swarm.reset()

        -- Mock da UI (não queremos criar janelas de verdade no teste)
        original_create_buf = popup.create_swarm_buffer
        popup.create_swarm_buffer = function(agent, instr)
            return 999 -- ID fake de buffer
        end

        -- Mock da API (intercepta a chamada HTTP para simular sucesso imediato)
        original_execute = api_client.execute
        api_client.execute = function(messages, on_start, on_chunk, on_done, on_error, force_api_cfg)
            table.insert(executed_tasks, { api = force_api_cfg.name, msgs = messages })
        end

        -- Mock do Callback Final (interceptamos o relatório do Tech Lead)
        swarm.on_swarm_complete = function(summary)
            final_summary = summary
        end
        
        -- Injetando 1 worker ocioso diretamente no estado
        swarm.state.workers = {
            { api = { name = "worker_1", abstraction_level = "high", api_type = "openai" }, busy = false, current_task = nil }
        }
    end)

    after_each(function()
        popup.create_swarm_buffer = original_create_buf
        api_client.execute = original_execute
    end)

    it("Deve criar o buffer visual, montar o prompt e disparar a API correta", function()
        swarm.state.queue = { { agent = "coder", instruction = "Crie a funcao", context = {"mock.lua"} } }
        
        swarm.dispatch_next()
        
        assert.are.same(1, #executed_tasks, "O worker deveria ter acionado a API")
        assert.are.same("worker_1", executed_tasks[1].api, "O dispatcher deve usar a API atrelada ao worker")
        assert.is_true(swarm.state.workers[1].busy, "O worker deve ser marcado como ocupado")
    end)

    it("Deve processar a conclusao (on_done), liberar o worker e disparar o merge final", function()
        swarm.state.queue = { { agent = "qa", instruction = "Testes", context = {} } }
        
        -- Sobrescrevemos o mock para acionar imediatamente o callback on_done (como se a requisição terminasse na hora)
        api_client.execute = function(msgs, start, chunk, done, err, force_api_cfg)
            -- Simulando a IA terminando de digitar
            done(force_api_cfg, nil) 
        end

        swarm.dispatch_next()

        -- Espera até 100ms para o vim.schedule(M.dispatch_next) processar
        vim.wait(100, function() return final_summary ~= nil end, 5)

        assert.is_false(swarm.state.workers[1].busy, "O worker deve voltar a ficar livre apos o on_done")
        assert.is_not_nil(final_summary, "Como a fila esvaziou, o relatorio final deve ter sido gerado")
        assert.truthy(final_summary:match("qa"), "O resumo deve conter a tarefa do agente qa")
    end)
end)




======== ./lua/multi_context/tests/memory_tracker_spec.lua ========
local memory_tracker = require('multi_context.memory_tracker')

describe("Fase 25 - Passo 1: O Guardião Preditivo 2.0 (Fundações):", function()
    before_each(function()
        memory_tracker.reset()
    end)

    it("Deve inicializar a EMA perfeitamente com o primeiro valor", function()
        memory_tracker.add_turn(100)
        assert.are.same(100, memory_tracker.get_ema())
    end)

    it("Deve calcular a EMA absorvendo picos sem enviesar totalmente", function()
        memory_tracker.add_turn(100)  -- O normal
        memory_tracker.add_turn(5000) -- O pico
        
        local ema_after_peak = memory_tracker.get_ema()
        assert.is_true(ema_after_peak > 1000 and ema_after_peak < 2000, "EMA deveria ter amortecido o pico")

        memory_tracker.add_turn(150)  -- Voltou ao normal
        local ema_after_drop = memory_tracker.get_ema()
        
        assert.is_true(ema_after_drop < ema_after_peak, "EMA deve começar a descer")
    end)
    
    it("Deve prever os tokens ignorando a dupla contagem do prompt", function()
        memory_tracker.add_turn(100)
        
        -- Agora passamos APENAS o tamanho do buffer atual. 
        -- O prompt recém-digitado já está colado nele pela UI, então não devemos somar duas vezes.
        local prediction = memory_tracker.predict_next_total(500)
        
        -- 500 (Buffer com prompt) + 100 (EMA)
        assert.are.same(600, prediction, "A predição deve ser apenas Buffer Atual + EMA")
    end)

    it("Deve garantir Imunidade de Primeiro Turno (Cold Start)", function()
        -- Histórico Zerado
        assert.is_true(memory_tracker.is_immune(), "Deve ser imune no Big Bang (0 turnos)")
        
        -- Após o primeiro turno
        memory_tracker.add_turn(1500)
        assert.is_true(memory_tracker.is_immune(), "Ainda deve ser imune antes de disparar o segundo turno")
        
        -- Após o segundo turno
        memory_tracker.add_turn(200)
        assert.is_false(memory_tracker.is_immune(), "A partir do segundo turno concluído, o Guardião passa a vigiar")
    end)
end)




======== ./lua/multi_context/tests/tools_diff_spec.lua ========
local tools = require('multi_context.tools')

describe("Tools Module (Unified Diff):", function()
    local tmp_file = os.tmpname()

    after_each(function()
        os.remove(tmp_file)
        -- Limpa possíveis resíduos gerados pelo binário 'patch' (.rej ou .orig)
        os.remove(tmp_file .. ".orig")
        os.remove(tmp_file .. ".rej")
    end)

    it("Deve aplicar um Unified Diff a um arquivo (apply_diff)", function()
        tools.edit_file(tmp_file, "L1\nL2\nL3")
        
        -- Diff Unificado simulando alteração da L2 para L2_Nova
        local patch_content = [[
--- a/arquivo
+++ b/arquivo
@@ -1,3 +1,3 @@
 L1
-L2
+L2_Nova
 L3
]]
        
        local res = tools.apply_diff(tmp_file, patch_content)
        assert.truthy(res:match("SUCESSO"), "Deveria retornar SUCESSO ao aplicar diff válido")
        
        local lines = vim.fn.readfile(tmp_file)
        assert.are.same({"L1", "L2_Nova", "L3"}, lines)
    end)

    it("Deve lidar com falhas graciosamente (patch rejeitado)", function()
        tools.edit_file(tmp_file, "Arquivo totalmente diferente\nSem nada a ver")
        
        local patch_content = [[
--- a/arquivo
+++ b/arquivo
@@ -1,3 +1,3 @@
 L1
-L2
+L2_Nova
 L3
]]
        local res = tools.apply_diff(tmp_file, patch_content)
        assert.truthy(res:match("FALHA") or res:match("ERRO"), "Deveria retornar FALHA/ERRO se o patch for rejeitado por contexto inválido")
    end)
end)




======== ./lua/multi_context/tests/minimal_init.lua ========
vim.cmd([[set runtimepath+=. ]])

-- Tenta adicionar Plenary via vim-plug silenciosamente, se existir
local plenary_dir = vim.fn.expand("~/.local/share/nvim/plugged/plenary.nvim")
if vim.fn.isdirectory(plenary_dir) == 1 then
    vim.cmd("set runtimepath+=" .. plenary_dir)
end

require('multi_context.config').setup({ user_name = "Nardi" })




======== ./lua/multi_context/tests/swarm_routing_spec.lua ========
local swarm = require('multi_context.swarm_manager')
local agents = require('multi_context.agents')
local api_client = require('multi_context.api_client')

describe("Fase 20 - Passo 2 (Fallback Direcional):", function()
    local orig_load_agents
    local orig_execute

    before_each(function()
        swarm.reset()
        
        -- Mockamos os agentes com seus níveis cognitivos
        orig_load_agents = agents.load_agents
        agents.load_agents = function()
            return {
                agente_low = { system_prompt = "low", abstraction_level = "low" },
                agente_med = { system_prompt = "med", abstraction_level = "medium" },
                agente_high = { system_prompt = "high", abstraction_level = "high" }
            }
        end
        
        -- Interceptamos o disparo real da rede para o teste ser síncrono
        orig_execute = api_client.execute
        api_client.execute = function(msgs, on_start, on_chunk, on_done, on_error, force_api_cfg)
            -- Finge que iniciou o job
        end
    end)

    after_each(function()
        agents.load_agents = orig_load_agents
        api_client.execute = orig_execute
    end)

    it("Deve bloquear a tarefa se não houver API com capacidade suficiente (Starvation)", function()
        swarm.state.queue = { { agent = "agente_med", instruction = "teste" } }
        swarm.state.workers = {
            { api = { name = "api_fraca", abstraction_level = "low" }, busy = false }
        }
        
        swarm.dispatch_next()
        
        -- A tarefa DEVE continuar na fila (1), pois a API ociosa é muito fraca para ela
        assert.are.same(1, #swarm.state.queue, "A tarefa nao deveria ter sido alocada")
        assert.is_false(swarm.state.workers[1].busy, "O worker de baixo nivel nao deve ter sido usado")
    end)

    it("Deve permitir que uma API poderosa resolva uma tarefa simples (Fallback Direcional)", function()
        swarm.state.queue = { { agent = "agente_low", instruction = "teste" } }
        swarm.state.workers = {
            { api = { name = "api_forte", abstraction_level = "high" }, busy = false }
        }
        
        swarm.dispatch_next()
        
        -- A API é overqualified, então ela engole a tarefa
        assert.are.same(0, #swarm.state.queue, "A tarefa deve ser consumida pela API overqualified")
        assert.is_true(swarm.state.workers[1].busy, "O worker forte deve assumir o trabalho")
    end)
end)




======== ./lua/multi_context/queue_editor.lua ========
-- lua/multi_context/queue_editor.lua
-- Buffer interativo para reordenar a fila de APIs e alternar allow_spawn (dd/p para mover, <Space> para alternar, :w para salvar).
local api = vim.api
local M   = {}

M.open_editor = function()
    local config = require('multi_context.config')
    local cfg    = config.load_api_config()
    if not cfg then
        vim.notify("Configuração não encontrada.", vim.log.levels.ERROR)
        return
    end

    local lines_out = {}
    for _, a in ipairs(cfg.apis) do
        local box = a.allow_spawn and "[x]" or "[ ]"
        table.insert(lines_out, box .. " " .. a.name)
    end

    local buf = api.nvim_create_buf(false, true)
    api.nvim_buf_set_lines(buf, 0, -1, false, lines_out)

    -- buftype 'acwrite' permite :w sem arquivo físico (evita E32)
    vim.bo[buf].buftype = 'acwrite'
    api.nvim_buf_set_name(buf, "MultiContext_Queue_Editor")

    local height = math.min(#lines_out + 2, 20)
    local win    = api.nvim_open_win(buf, true, {
        relative  = 'editor',
        width     = 58,
        height    = height,
        row       = 5,
        col       = 10,
        border    = 'rounded',
        title     = ' Ordenar Fila (<Space> spawn · dd/p mover · :w salvar) ',
        title_pos = 'center',
    })

    api.nvim_create_autocmd("BufWriteCmd", {
        buffer   = buf,
        callback = function()
            local lines     = api.nvim_buf_get_lines(buf, 0, -1, false)
            local reordered = {}
            for _, line in ipairs(lines) do
                local is_spawn = line:match("%[x%]") ~= nil
                local name = line:match("%[%s*x?%s*%]%s*(.*)")
                
                if name then
                    name = vim.trim(name)
                    for _, a in ipairs(cfg.apis) do
                        if a.name == name then
                            local new_a = vim.deepcopy(a)
                            new_a.allow_spawn = is_spawn
                            table.insert(reordered, new_a)
                            break
                        end
                    end
                end
            end
            
            cfg.apis = reordered
            if config.save_api_config(cfg) then
                vim.notify("Fila salva!", vim.log.levels.INFO)
                vim.bo[buf].modified = false
                api.nvim_win_close(win, true)
            else
                vim.notify("Erro ao salvar.", vim.log.levels.ERROR)
            end
        end,
    })

    api.nvim_buf_set_keymap(buf, "n", "q", ":q!<CR>", { noremap = true, silent = true })
    api.nvim_buf_set_keymap(buf, "n", "<Space>", "<Cmd>lua require('multi_context.queue_editor').toggle_spawn()<CR>", { noremap = true, silent = true })
end

M.toggle_spawn = function()
    local buf = api.nvim_get_current_buf()
    local row = api.nvim_win_get_cursor(0)[1] - 1
    local line = api.nvim_buf_get_lines(buf, row, row + 1, false)[1]
    
    if not line then return end

    if line:match("%[x%]") then
        line = line:gsub("%[x%]", "[ ]", 1)
    elseif line:match("%[%s*%]") then
        line = line:gsub("%[%s*%]", "[x]", 1)
    end

    api.nvim_buf_set_lines(buf, row, row + 1, false, { line })
end

return M




======== ./lua/multi_context/skills_manager.lua ========
local M = {}

-- Memória onde as skills carregadas vão ficar
M.skills = {}

M.reset = function()
    M.skills = {}
end

M.load_skills = function(dir_path)
    M.reset()
    -- Se o usuário não passar uma pasta, usamos o padrão ~/.config/nvim/mctx_skills
    if not dir_path then
        dir_path = vim.fn.stdpath("config") .. "/mctx_skills"
    end

    -- Se a pasta não existe, não faz nada
    if vim.fn.isdirectory(dir_path) == 0 then
        return
    end

    -- Encontra todos os arquivos .lua na pasta
    local files = vim.fn.globpath(dir_path, "*.lua", false, true)
    
    for _, file in ipairs(files) do
        -- loadfile compila o arquivo, mas não o executa. Evita crash de sintaxe.
        local chunk, err = loadfile(file)
        if chunk then
            -- pcall executa o arquivo com segurança.
            local ok, result = pcall(chunk)
            
            -- Validação estrita da estrutura da Skill
            if ok and type(result) == "table" then
                if type(result.name) == "string" and result.name ~= "" and type(result.execute) == "function" then
                    M.skills[result.name] = result
                end
            end
        end
    end
end

M.get_skills = function()
    return M.skills
end

return M




======== ./lua/multi_context/tool_parser.lua ========
-- lua/multi_context/tool_parser.lua
local M = {}

local valid_tools_list = {
    "list_files", "read_file", "search_code", "edit_file", 
    "run_shell", "replace_lines", "apply_diff", "rewrite_chat_buffer", "get_diagnostics", "spawn_swarm", "switch_agent"
}

-- 1. SANITIZADOR ANTI-ALUCINAÇÃO DE SINTAXE
M.sanitize_payload = function(content)
    local c = content
    -- Corrigido para [^<]* para que ele engula o ">" do </arg_value>tool_call>
    c = c:gsub("</[^<]*tool_call%s*>", "</tool_call>")
    c = c:gsub("<tool_call>%s*([a-zA-Z_]+)%s*>", '<tool_call name="%1">')
    for _, tool in ipairs(valid_tools_list) do
        c = c:gsub("<" .. tool .. "%s*>", '<tool_call name="' .. tool .. '">')
        c = c:gsub("<" .. tool .. "%s+([^>]+)>", '<tool_call name="' .. tool .. '" %1>')
        c = c:gsub("</" .. tool .. "%s*>", "</tool_call>")
    end
    return c
end
local function get_attr(attrs, n) 
    if not attrs then return nil end
    return attrs:match(n .. '%s*=%s*["\']([^"\']+)["\']') 
end

-- 2. LIMPEZA PROFUNDA DE LIXO INTERNO (Crases e tags aninhadas)
M.clean_inner_content = function(inner, name)
    local clean = inner
    if not name or name == "" or name == "nil" then return clean end

    local h_tags = {"content", "code", "command", "arg_value", "argument", "parameters", "text", "source", "tool_call"}
    local changed = true
    while changed do
        changed = false
        local before_md = clean
        clean = clean:gsub("^%s*```[%w_]*\n", ""):gsub("\n%s*```%s*$", "")
        if before_md ~= clean then changed = true end
        
        for _, tag in ipairs(h_tags) do
            local pat_full = "^%s*<" .. tag .. ">%s*(.-)%s*</" .. tag .. ">%s*$"
            local val = clean:match(pat_full)
            if val then clean = val; changed = true end
            
            local pat_end = "%s*</" .. tag .. ">%s*$"
            if clean:match(pat_end) then clean = clean:gsub(pat_end, ""); changed = true end
            
            local pat_start = "^%s*<" .. tag .. ">%s*"
            if clean:match(pat_start) then clean = clean:gsub(pat_start, ""); changed = true end
        end
    end
    return clean
end

-- 3. EXTRATOR ITERATIVO (Acha a próxima tag a partir do cursor)
M.parse_next_tool = function(content_to_process, cursor)
    local tag_start, tag_end = content_to_process:find("<tool_call[^>]*>", cursor)
    if not tag_start then return nil end

    local text_before = content_to_process:sub(cursor, tag_start - 1)
    local _, tick_count = text_before:gsub("```", "")
    
    local tag_str = content_to_process:sub(tag_start, tag_end)
    local is_self_closing = tag_str:match("/%s*>$")
    local close_start, close_end, inner

    if is_self_closing then
        inner = ""
        close_start = tag_end + 1
        close_end = tag_end
    else
        close_start, close_end = content_to_process:find("</tool_call%s*>", tag_end + 1)
        local next_open = content_to_process:find("<tool_call", tag_end + 1)
        
        if next_open and (not close_start or next_open < close_start) then
            close_start = next_open
            close_end = next_open - 1
            inner = content_to_process:sub(tag_end + 1, close_start - 1)
        elseif not close_start then 
            inner = content_to_process:sub(tag_end + 1)
            close_end = #content_to_process
        else 
            inner = content_to_process:sub(tag_end + 1, close_start - 1) 
        end
    end

    -- Se for impar, é block de código markdown falando SOBRE a tag, ignoramos
    if tick_count % 2 ~= 0 then
        return { is_invalid = true, text_before = text_before, raw_tag = tag_str, inner = inner, close_end = close_end, close_start = close_start }
    end

    local name = get_attr(tag_str, "name")
    local path = get_attr(tag_str, "path")
    local query = get_attr(tag_str, "query")
    local start_line = get_attr(tag_str, "start")
    local end_line = get_attr(tag_str, "end")

    -- Fallback se a IA mandou como JSON dentro do XML
    if not name or name == "" then
        local ok, json = pcall(vim.fn.json_decode, vim.trim(inner))
        if ok and type(json) == "table" then
            name = json.name
            if type(json.arguments) == "table" then
                path = json.arguments.path; query = json.arguments.query
                start_line = json.arguments.start or json.arguments.start_line
                end_line = json.arguments["end"] or json.arguments.end_line
                inner = json.arguments.command or json.arguments.content or json.arguments.code or inner
            end
        end
    end

    local clean_inner = M.clean_inner_content(inner, name)

    return {
        is_invalid = false,
        text_before = text_before,
        raw_tag = tag_str,
        name = name,
        path = path,
        query = query,
        start_line = start_line,
        end_line = end_line,
        inner = clean_inner,
        close_start = close_start,
        close_end = close_end
    }
end

return M




======== ./lua/multi_context/config.lua ========
-- lua/multi_context/config.lua
local M = {}

M.defaults = {
    user_name     = "User",
    config_path   = vim.fn.stdpath("config") .. "/context_apis.json",
    api_keys_path = vim.fn.stdpath("config") .. "/api_keys.json",
    default_api   = nil,
    cognitive_horizon = 4000,
    user_tolerance = 1.0,
    watchdog      = {
        mode         = "off",
        strategy     = "semantic",
        percent      = 0.3,
        fixed_target = 1500
    },
    appearance    = {
        border = "rounded",
        width  = 0.7,
        height = 0.7,
        title  = " 🤖 MultiContext AI ",
    },
}

M.options = vim.deepcopy(M.defaults)

M.bootstrap = function()
    -- 1. Cria chaves padrão se não existir
    if vim.fn.filereadable(M.options.api_keys_path) == 0 then
        local default_keys = {
            openai = "sk-...",
            anthropic = "sk-ant-...",
            gemini = "AIzaSy..."
        }
        local f = io.open(M.options.api_keys_path, "w")
        if f then
            f:write(vim.fn.json_encode(default_keys))
            f:close()
            vim.notify("\n[MultiContext] Bem-vindo! Criamos o arquivo api_keys.json. Por favor, insira suas chaves.", vim.log.levels.INFO)
        end
    end

    -- 2. Cria config de provedores padrão se não existir
    if vim.fn.filereadable(M.options.config_path) == 0 then
        local default_apis = {
            default_api = "openai",
            fallback_mode = true,
            apis = {
                {
                    name = "openai",
                    model = "gpt-4o",
                    api_type = "openai",
                    url = "https://api.openai.com/v1/chat/completions",
                    headers = {
                        ["Content-Type"] = "application/json",
                        Authorization = "Bearer {API_KEY}"
                    },
                    num_tries = 3,["include_in_fall-back_mode"] = true
                }
            }
        }
        local f = io.open(M.options.config_path, "w")
        if f then
            local raw = vim.fn.json_encode(default_apis)
            f:write(raw)
            f:close()
            pcall(function() vim.fn.system(string.format("echo %s | jq . > %s", vim.fn.shellescape(raw), M.options.config_path)) end)
            vim.notify("[MultiContext] Arquivo context_apis.json criado com configurações padrão.", vim.log.levels.INFO)
        end
    end
end

function M.setup(user_opts)
    M.options = vim.tbl_deep_extend("force", M.defaults, user_opts or {})
    if M.options.config_path then M.options.config_path = vim.fn.expand(M.options.config_path) end
    if M.options.api_keys_path then M.options.api_keys_path = vim.fn.expand(M.options.api_keys_path) end
    
    -- 3. MIGRAÇÃO DE AGENTES (Personas -> Skills)
    local agents_file = vim.fn.stdpath("config") .. "/mctx_agents.json"
    if vim.fn.filereadable(agents_file) == 1 then
        local lines = vim.fn.readfile(agents_file)
        local ok, parsed = pcall(vim.fn.json_decode, table.concat(lines, "\n"))
        if ok and type(parsed) == "table" then
            local changed = false
            for _, v in pairs(parsed) do
                if v.use_tools ~= nil then
                    if v.use_tools == true then
                        v.skills = {"list_files", "search_code", "read_file", "replace_lines", "apply_diff", "edit_file", "run_shell", "rewrite_chat_buffer", "get_diagnostics"}
                    else
                        v.skills = {}
                    end
                    v.use_tools = nil
                    changed = true
                end
            end
            if changed then vim.fn.writefile({vim.fn.json_encode(parsed)}, agents_file); vim.notify("[MultiContext] Agentes migrados para o novo formato de Skills!", vim.log.levels.INFO) end
        end
    end

    -- Chama a auto-configuração no start do plugin
    M.bootstrap()
end

M.load_api_config = function()
    local f = io.open(M.options.config_path, 'r')
    if not f then return nil end
    local content = f:read('*a'); f:close()
    local ok, parsed = pcall(vim.fn.json_decode, content)
        if ok and parsed and parsed.apis then
        for _, api in ipairs(parsed.apis) do
            if not api.abstraction_level then
                api.abstraction_level = "medium"
            end
        end
    end
    return ok and parsed or nil

end

M.load_api_keys = function()
    local f = io.open(M.options.api_keys_path, 'r')
    if not f then return {} end
    local content = f:read('*a'); f:close()
    local ok, parsed = pcall(vim.fn.json_decode, content)
    return ok and parsed or {}
end

M.save_api_config = function(cfg)
    local raw = vim.fn.json_encode(cfg)
    local formatted = vim.fn.system(string.format("echo %s | jq .", vim.fn.shellescape(raw)))
    if vim.v.shell_error ~= 0 then formatted = raw end
    local f = io.open(M.options.config_path, 'w')
    if not f then return false end
    f:write(formatted); f:close()
    return true
end

M.set_selected_api = function(api_name)
    local cfg = M.load_api_config()
    if not cfg then return false end
    cfg.default_api = api_name
    return M.save_api_config(cfg)
end

M.get_api_names = function()
    local cfg = M.load_api_config()
    if not cfg then return {} end
    local names = {}
    for _, a in ipairs(cfg.apis) do table.insert(names, a.name) end
    return names
end

M.get_current_api = function()
    local cfg = M.load_api_config()
    if not cfg then return "" end
    return cfg.default_api or ""
end

M.get_spawn_apis = function()
    local cfg = M.load_api_config()
    if not cfg or not cfg.apis then return {} end
    local spawn_apis = {}
    for _, a in ipairs(cfg.apis) do
        if a.allow_spawn then table.insert(spawn_apis, a) end
    end
    return spawn_apis
end

return M




======== ./lua/multi_context/api_handlers.lua ========
-- lua/multi_context/api_handlers.lua
local M = {}
local transport = require('multi_context.transport')

M.gemini = {
    make_request = function(api_config, messages, api_keys, _, callback)
        local api_key = api_keys[api_config.name] or ""
        if api_key == "" then
            callback("\n[ERRO]: Chave não encontrada.", nil, false)
            callback(nil, nil, true)
            return
        end
        local contents = {}; local system_instruction = nil
        for _, msg in ipairs(messages) do
            if msg.role == "system" then
                system_instruction = { parts = { { text = msg.content } } }
            else
                table.insert(contents, {
                    role = (msg.role == "user") and "user" or "model",
                    parts = { { text = msg.content } }
                })
            end
        end
        local payload = { contents = contents }
        if system_instruction then payload.systemInstruction = system_instruction end
        local tmp_file = transport.write_payload_to_tmp(payload)
        local cmd = transport.build_curl_cmd(api_config, api_key, tmp_file, true)
        transport.run_http_stream(cmd, tmp_file,
            function(data, ctx, cb)
                ctx.buffer = ctx.buffer .. table.concat(data, "\n")
                local chunks, rest = transport.extract_text_chunks(ctx.buffer)
                for _, txt in ipairs(chunks) do cb(txt, nil, false) end
                ctx.buffer = rest
            end,
            function(full_res)
                if full_res:match('"error"') then
                    local ok, dec = pcall(vim.fn.json_decode, full_res)
                    if ok and dec.error and dec.error.message then
                        return "**[ERRO GEMINI]:** " .. dec.error.message
                    end
                end
            end,
            callback)
    end
}

M.openai = {
    make_request = function(api_config, messages, api_keys, _, callback)
        local api_key = api_keys[api_config.name] or ""
        local payload = {
            model = api_config.model,
            messages = messages,
            stream = true,
            stream_options = { include_usage = true }
        }
        local tmp_file = transport.write_payload_to_tmp(payload)
        local cmd = transport.build_curl_cmd(api_config, api_key, tmp_file, true)
        transport.run_http_stream(cmd, tmp_file,
            function(data, ctx, cb)
                for _, line in ipairs(data) do
                    if line:match("^data: ") and not line:match("%[DONE%]") then
                        local ok, dec = pcall(vim.fn.json_decode, line:sub(7))
                        if ok then
                            if dec.choices and dec.choices[1] and dec.choices[1].delta
                                and type(dec.choices[1].delta.content) == "string" then
                                cb(dec.choices[1].delta.content, nil, false)
                            end
                            if type(dec.usage) == "table" then
                                ctx.metrics = ctx.metrics or {}
                                ctx.metrics.cache_read_input_tokens =
                                    (type(dec.usage.prompt_tokens_details) == "table"
                                        and dec.usage.prompt_tokens_details.cached_tokens)
                                    or dec.usage.prompt_cache_hit_tokens or 0
                            end
                        end
                    end
                end
            end,
            function(full_res)
                if full_res:match('"error"') and not full_res:match('"content"') then
                    local ok, dec = pcall(vim.fn.json_decode, full_res)
                    if ok and dec.error and dec.error.message then
                        return "**[ERRO OPENAI]:** " .. dec.error.message
                    end
                end
            end,
            callback)
    end
}

M.anthropic = {
    make_request = function(api_config, messages, api_keys, _, callback)
        local api_key = api_keys[api_config.name] or ""
        local system_text = ""; local anthropic_msgs = {}
        for _, msg in ipairs(messages) do
            if msg.role == "system" then
                system_text = system_text .. msg.content .. "\n"
            else
                table.insert(anthropic_msgs, { role = msg.role, content = msg.content })
            end
        end
        local payload = {
            model = api_config.model,
            messages = anthropic_msgs,
            system = { {
                type = "text",
                text = vim.trim(system_text),
                cache_control = { type = "ephemeral" }
            } },
            stream = true,
            max_tokens = 4096
        }
        local tmp_file = transport.write_payload_to_tmp(payload)
        local cmd = transport.build_curl_cmd(api_config, api_key, tmp_file, true)
        table.insert(cmd, "-H"); table.insert(cmd, "anthropic-version: 2023-06-01")
        table.insert(cmd, "-H"); table.insert(cmd, "anthropic-beta: prompt-caching-2024-07-31")
        transport.run_http_stream(cmd, tmp_file,
            function(data, ctx, cb)
                for _, line in ipairs(data) do
                    if line:match("^data: ") then
                        local ok, dec = pcall(vim.fn.json_decode, line:sub(7))
                        if ok then
                            if dec.type == "content_block_delta" and dec.delta and dec.delta.text then
                                cb(dec.delta.text, nil, false)
                            elseif dec.type == "message_start"
                                and type(dec.message) == "table"
                                and type(dec.message.usage) == "table" then
                                ctx.metrics = ctx.metrics or {}
                                ctx.metrics.cache_read_input_tokens =
                                    dec.message.usage.cache_read_input_tokens or 0
                            end
                        end
                    end
                end
            end,
            function(full_res)
                if full_res:match('"error"') and not full_res:match('"type": "message_start"') then
                    local ok, dec = pcall(vim.fn.json_decode, full_res)
                    if ok and dec.error and dec.error.message then
                        return "**[ERRO ANTHROPIC]:** " .. dec.error.message
                    end
                end
            end,
            callback)
    end
}

M.cloudflare = {
    make_request = function(api_config, messages, api_keys, _, callback)
        local api_key = api_keys[api_config.name] or ""
        local tmp_file = transport.write_payload_to_tmp({ messages = messages })
        if not api_config.headers then api_config.headers = {} end
        if not api_config.headers["Authorization"] then
            api_config.headers["Authorization"] = "Bearer {API_KEY}"
        end
        local cmd = transport.build_curl_cmd(api_config, api_key, tmp_file, false)
        transport.run_http_stream(cmd, tmp_file,
            function(data, ctx)
                ctx.buffer = ctx.buffer .. table.concat(data, "\n")
            end,
            function(full_res, ctx, cb)
                local ok, dec = pcall(vim.fn.json_decode, ctx.buffer)
                if ok and dec and dec.result and dec.result.response then
                    cb(dec.result.response, nil, false)
                elseif ctx.buffer:match('"errors"') then
                    return "**[ERRO CLOUDFLARE]:** Falha na API"
                end
            end,
            callback)
    end
}

return M




======== ./lua/multi_context/transport.lua ========
-- lua/multi_context/transport.lua
local M = {}

_G.MultiContextTempFiles = _G.MultiContextTempFiles or {}

local function decode_json_string(s)
    s = s:gsub("\\n", "\n"):gsub("\\t", "\t"):gsub("\\r", "\r"):gsub('\\"', '"')
    s = s:gsub("\\u(%x%x%x%x)", function(hex) return vim.fn.nr2char(tonumber(hex, 16)) end)
    return s:gsub("\\\\", "\\")
end

local function extract_text_chunks(buffer)
    local results = {}; local remaining = buffer
    while true do
        local pos_start, pos_end = remaining:find('"text"%s*:%s*"')
        if not pos_start then break end
        local str_start = pos_end + 1
        local str_end = nil; local i = str_start
        while i <= #remaining do
            local ch = remaining:sub(i, i)
            if ch == '\\' then i = i + 2
            elseif ch == '"' then str_end = i; break
            else i = i + 1 end
        end
        if not str_end then break end
        local inner_str = remaining:sub(str_start, str_end - 1)
        local ok, decoded = pcall(vim.fn.json_decode, '"' .. inner_str .. '"')
        if ok and type(decoded) == "string" then table.insert(results, decoded)
        else table.insert(results, decode_json_string(inner_str)) end
        remaining = remaining:sub(str_end + 1)
    end
    return results, remaining
end

local function build_curl_cmd(api_config, api_key, tmp_file, stream)
    local cmd = { "curl", "-s", "-L", "-X", "POST" }
    if stream then table.insert(cmd, "-N") end
    local url = api_config.url
    if api_config.api_type == "gemini" and stream then
        url = url:gsub(":generateContent", ":streamGenerateContent") .. "?key=" .. api_key
    end
    table.insert(cmd, url)
    for k, v in pairs(api_config.headers or {}) do
        table.insert(cmd, "-H")
        table.insert(cmd, k .. ": " .. v:gsub("{API_KEY}", api_key))
    end
    table.insert(cmd, "-d")
    table.insert(cmd, "@" .. tmp_file)
    return cmd
end

local function write_payload_to_tmp(payload)
    local tmp_file = os.tmpname()
    table.insert(_G.MultiContextTempFiles, tmp_file)
    local f = io.open(tmp_file, "w")
    if f then f:write(vim.fn.json_encode(payload)); f:close() end
    return tmp_file
end

M.run_http_stream = function(cmd, tmp_file, process_stdout, extract_error, callback)
    local full_response = ""
    local context = { buffer = "", metrics = nil }
    local job_id = vim.fn.jobstart(cmd, {
        on_stdout = function(_, data)
            if not data then return end
            for _, line in ipairs(data) do full_response = full_response .. line .. "\n" end
            if process_stdout then process_stdout(data, context, callback) end
        end,
        on_exit = function()
            pcall(os.remove, tmp_file)
            local err_msg = extract_error(full_response, context, callback)
            if err_msg then callback("\n\n" .. err_msg .. "\n", nil, false) end
            callback(nil, nil, true, context.metrics)
        end
    })
    callback(nil, nil, false, nil, job_id)
end

M.extract_text_chunks = extract_text_chunks
M.write_payload_to_tmp = write_payload_to_tmp
M.build_curl_cmd = build_curl_cmd

return M




======== ./lua/multi_context/api_selector.lua ========
-- api_selector.lua
-- Popup flutuante para selecionar a API padrão.
-- Usa config para leitura/escrita e ui/highlights para visuais.
local api = vim.api
local M   = {}

M.selector_buf      = nil
M.selector_win      = nil
M.api_list          = {}
M.current_selection = 1

M.open_api_selector = function()
    local config = require('multi_context.config')
    M.api_list   = config.get_api_names()
    if #M.api_list == 0 then
        vim.notify("Nenhuma API configurada.", vim.log.levels.WARN)
        return
    end

    local current = config.get_current_api()
    M.current_selection = 1
    for i, name in ipairs(M.api_list) do
        if name == current then M.current_selection = i; break end
    end

    M.selector_buf = api.nvim_create_buf(false, true)

    local width  = 60
    local height = math.min(#M.api_list + 5, 22)
    local row    = math.floor((vim.o.lines   - height) / 2)
    local col    = math.floor((vim.o.columns - width)  / 2)

    M.selector_win = api.nvim_open_win(M.selector_buf, true, {
        relative  = "editor",
        width     = width,
        height    = height,
        row       = row,
        col       = col,
        style     = "minimal",
        border    = "rounded",
        title     = " Selecionar API ",
        title_pos = "center",
    })

    vim.bo[M.selector_buf].buftype    = "nofile"
    vim.bo[M.selector_buf].modifiable = true

    M._render()
    M._keymaps()
end

M._render = function()
    if not M.selector_buf or not api.nvim_buf_is_valid(M.selector_buf) then return end

    local config  = require('multi_context.config')
    local hl      = require('multi_context.ui.highlights')
    local current = config.get_current_api()

    local lines = {
        "Selecione a API para usar nas requisições:",
        "  j/k navegar   Enter selecionar   q sair",
        "",
    }
    for i, name in ipairs(M.api_list) do
        local cursor = (i == M.current_selection) and "❯ " or "  "
        local tag    = (name == current)           and " (selecionada)" or ""
        table.insert(lines, cursor .. name .. tag)
    end
    table.insert(lines, "")
    table.insert(lines, "  API atual: " .. current)

    vim.bo[M.selector_buf].modifiable = true
    api.nvim_buf_set_lines(M.selector_buf, 0, -1, false, lines)
    hl.apply_selector(M.selector_buf, M.api_list)
end

M._keymaps = function()
    if not M.selector_buf or not api.nvim_buf_is_valid(M.selector_buf) then return end
    local function mk(k, fn)
        api.nvim_buf_set_keymap(M.selector_buf, "n", k, "",
            { callback = fn, noremap = true, silent = true })
    end
    mk("j",     function() M._move(1)  end)
    mk("k",     function() M._move(-1) end)
    mk("<CR>",  M._select)
    mk("q",     M._close)
    mk("<Esc>", M._close)
end

M._move = function(dir)
    local n = M.current_selection + dir
    if n >= 1 and n <= #M.api_list then
        M.current_selection = n
        M._render()
    end
end

M._select = function()
    local config = require('multi_context.config')
    local name   = M.api_list[M.current_selection]
    if config.set_selected_api(name) then
        vim.notify("API selecionada: " .. name, vim.log.levels.INFO)
        require('multi_context.ui.popup').update_title()
        M._close()
    else
        vim.notify("Erro ao selecionar: " .. name, vim.log.levels.ERROR)
    end
end

M._close = function()
    if M.selector_win and api.nvim_win_is_valid(M.selector_win) then
        api.nvim_win_close(M.selector_win, true)
    end
    M.selector_buf      = nil
    M.selector_win      = nil
    M.api_list          = {}
    M.current_selection = 1
end

return M




======== ./lua/multi_context/utils.lua ========
-- lua/multi_context/utils.lua
local M   = {}
local api = vim.api

M.estimate_tokens = function(buf)
    if not buf or not api.nvim_buf_is_valid(buf) then return 0 end
    local lines = api.nvim_buf_get_lines(buf, 0, -1, false)
    local char_count = 0
    for _, line in ipairs(lines) do
        char_count = char_count + #line + 1
    end
    return math.floor(char_count / 4)
end


M.build_workspace_content = function(buf, existing_filename)
    local lines = api.nvim_buf_get_lines(buf, 0, -1, false)
    local content = table.concat(lines, "\n")
    
    local session_id = existing_filename and string.match(existing_filename, "chat_(d+_d+).mctx")
    local created_at = os.date("Y-m-dTH:M:S")
    local updated_at = os.date("Y-m-dTH:M:S")

    -- Se já for uma sessão antiga, extraímos o ID/Creation e removemos a tag suja
    local existing_session = content:match("<mctx_session(.-)/>")
    if existing_session then
        local old_id = existing_session:match('id="([^"]+)"')
        local old_created = existing_session:match('created="([^"]+)"')
        if old_id then session_id = old_id end
        if old_created then created_at = old_created end
        content = content:gsub("<mctx_session.-/>s*", "")
    end
    
    if not session_id then session_id = os.date("Ymd_HMS") end
    
    -- Limpa estado do swarm antigo e substitui
    content = content:gsub("<swarm_state>.-</swarm_state>s*", "")
    
    local swarm = require('multi_context.swarm_manager')
    local popup = require('multi_context.ui.popup')
    
    local state_data = { queue = swarm.state.queue or {}, reports = swarm.state.reports or {}, buffers = {} }
    
    if popup.swarm_buffers then
        for i, sb in ipairs(popup.swarm_buffers) do
            if i > 1 and sb.buf and api.nvim_buf_is_valid(sb.buf) then
                local b_lines = api.nvim_buf_get_lines(sb.buf, 0, -1, false)
                table.insert(state_data.buffers, { name = sb.name, status = sb.status, lines = b_lines })
            end
        end
    end
    
    local ok, json_state = pcall(vim.fn.json_encode, state_data)
    local swarm_xml = ""
    if ok and json_state and json_state ~= "{}" then
        swarm_xml = "\n<swarm_state>\n" .. json_state .. "\n</swarm_state>"
    end
    
    local header = string.format('<mctx_session id="s" created="s" updated="s" />\n', session_id, created_at, updated_at)
    local new_content = header .. vim.trim(content) .. "\n" .. swarm_xml
    
    local new_filename = existing_filename
    if not new_filename then
        local root = vim.fn.system("git rev-parse --show-toplevel")
        if vim.v.shell_error == 0 then root = root:gsub("\n", "") else root = vim.fn.getcwd() end
        local chat_dir = root .. "/.mctx_chats"
        new_filename = chat_dir .. "/chat_" .. session_id .. ".mctx"
    end
    
    return new_filename, new_content
end

M.load_workspace_state = function(buf)
    local lines = api.nvim_buf_get_lines(buf, 0, -1, false)
    local content = table.concat(lines, "\n")
    
    local swarm_state_str = content:match("<swarm_state>s*(.-)s*</swarm_state>")
    if swarm_state_str then
        local ok, parsed = pcall(vim.fn.json_decode, swarm_state_str)
        if ok and type(parsed) == "table" then
            local swarm = require('multi_context.swarm_manager')
            local popup = require('multi_context.ui.popup')
            
            swarm.state.queue = parsed.queue or {}
            swarm.state.reports = parsed.reports or {}
            
            if parsed.buffers then
                for _, bdata in ipairs(parsed.buffers) do
                    local exists = false
                    if popup.swarm_buffers then
                        for _, sb in ipairs(popup.swarm_buffers) do
                            if sb.name == bdata.name then exists = true; break end
                        end
                    end
                    if not exists then
                        local new_buf = api.nvim_create_buf(false, true)
                        vim.bo[new_buf].buftype   = 'nofile'
                        vim.bo[new_buf].bufhidden = 'hide'
                        vim.bo[new_buf].swapfile  = false
                        vim.bo[new_buf].filetype  = 'multicontext_chat'
                        api.nvim_buf_set_lines(new_buf, 0, -1, false, bdata.lines or {})
                        
                        if not popup.swarm_buffers then popup.swarm_buffers = {} end
                        table.insert(popup.swarm_buffers, { buf = new_buf, name = bdata.name, status = bdata.status or "Restaurado" })
                        require('multi_context.ui.highlights').apply_chat(new_buf)
                        popup.create_folds(new_buf)
                    end
                end
            end
        end
    end
end

M.export_to_workspace = function(content, existing_filename)
    local filename = existing_filename
    if not filename then
        local timestamp = os.date("%Y%m%d_%H%M%S")
        
        -- MÁGICA: Busca a raiz do projeto atual
        local root = vim.fn.system("git rev-parse --show-toplevel")
        if vim.v.shell_error == 0 then
            root = root:gsub("\n", "")
        else
            root = vim.fn.getcwd() -- Fallback caso não seja repositório git
        end
        
        local chat_dir = root .. "/.mctx_chats"
        
        if vim.fn.isdirectory(chat_dir) == 0 then
            vim.fn.mkdir(chat_dir, "p")
        end
        filename = chat_dir .. "/chat_" .. timestamp .. ".mctx"
    end
    
    vim.cmd("edit " .. filename)
    
    local new_buf = vim.api.nvim_get_current_buf()
    vim.bo[new_buf].filetype = "multicontext_chat"
    
    local lines = M.split_lines(content)
    vim.api.nvim_buf_set_lines(new_buf, 0, -1, false, lines)
    vim.bo[new_buf].modified = true
    
    local last_line = vim.api.nvim_buf_line_count(new_buf)
    vim.api.nvim_win_set_cursor(0, { last_line, 0 })
    vim.cmd("stopinsert")
    
    require('multi_context.ui.highlights').apply_chat(new_buf)
    require('multi_context.ui.popup').create_folds(new_buf)
    
    local km = { noremap = true, silent = true }
    vim.api.nvim_buf_set_keymap(new_buf, "i", "@", "@<Esc><Cmd>lua require('multi_context.agents').open_agent_selector()<CR>", km)
    vim.api.nvim_buf_set_keymap(new_buf, "n", "<A-x>", "<Cmd>lua require('multi_context').ExecuteTools()<CR>", km)
    vim.api.nvim_buf_set_keymap(new_buf, "i", "<A-x>", "<Esc><Cmd>lua require('multi_context').ExecuteTools()<CR>", km)

    return filename
end

M.split_lines = function(s)
    if not s or s == "" then return {} end
    -- Usa a API nativa e otimizada do Neovim (não gera arrays com posições vazias fantasmas)
    return vim.split(s, "\n", { plain = true })
end

M.insert_after = function(buf, line_idx, lines)
    local target = (line_idx == -1) and api.nvim_buf_line_count(buf) or line_idx
    api.nvim_buf_set_lines(buf, target, target, false, lines)
end

M.copy_code_block = function()
    local buf    = api.nvim_get_current_buf()
    local cursor = api.nvim_win_get_cursor(0)[1]
    local lines  = api.nvim_buf_get_lines(buf, 0, -1, false)
    local s, e   = nil, nil
    for i = cursor, 1, -1 do
        if lines[i] and lines[i]:match("^```") then s = i; break end
    end
    for i = cursor, #lines do
        if lines[i] and lines[i]:match("^```") and i ~= s then e = i; break end
    end
    if s and e then
        vim.fn.setreg('+', table.concat(api.nvim_buf_get_lines(buf, s, e - 1, false), "\n"))
        vim.notify("Código copiado!")
    else
        vim.notify("Nenhum bloco de código encontrado.", vim.log.levels.WARN)
    end
end

M.apply_highlights        = function(b) require('multi_context.ui.highlights').apply_chat(b) end
M.get_git_diff            = function()  return require('multi_context.context_builders').get_git_diff() end
M.get_tree_context        = function()  return require('multi_context.context_builders').get_tree_context() end
M.get_all_buffers_content = function()  return require('multi_context.context_builders').get_all_buffers_content() end
M.find_last_user_line     = function(b) return require('multi_context.conversation').find_last_user_line(b) end
M.load_api_config         = function()  return require('multi_context.config').load_api_config() end
M.load_api_keys           = function()  return require('multi_context.config').load_api_keys() end
M.set_selected_api        = function(n) return require('multi_context.config').set_selected_api(n) end
M.get_api_names           = function()  return require('multi_context.config').get_api_names() end
M.get_current_api         = function()  return require('multi_context.config').get_current_api() end

return M




======== ./lua/multi_context/squads.lua ========
local M = {}
M.squads_file = vim.fn.stdpath("config") .. "/mctx_squads.json"

M.load_squads = function()
    if vim.fn.filereadable(M.squads_file) == 0 then
        local default_squads = {
            squad_dev = {
                description = "Esquadrão padrao de desenvolvimento e qualidade",
                tasks = {
                    {
                        agent = "tech_lead",
                        instruction = "Analise o pedido do usuario e orquestre o desenvolvimento.",
                        chain = {"coder", "qa"},
                        allow_switch = {}
                    }
                }
            }
        }
        vim.fn.writefile({vim.fn.json_encode(default_squads)}, M.squads_file)
    end

    local file = io.open(M.squads_file, 'r')
    if not file then return {} end
    local content = file:read('*a')
    file:close()
    local ok, parsed = pcall(vim.fn.json_decode, content)
    return ok and parsed or {}
end

M.get_squad_names = function()
    local squads = M.load_squads()
    local names = {}
    for name, _ in pairs(squads) do table.insert(names, name) end
    table.sort(names)
    return names
end

return M




======== ./lua/multi_context/memory_tracker.lua ========
local M = {}
M.state = { ema = 0, count = 0 }

M.reset = function() M.state.ema = 0; M.state.count = 0 end

M.add_turn = function(tokens)
    if M.state.count == 0 then M.state.ema = tokens
    else M.state.ema = math.floor((tokens * 0.3) + (M.state.ema * 0.7)) end
    M.state.count = M.state.count + 1
end

M.get_ema = function() return M.state.ema end

-- BUG 2 CORRIGIDO: Apenas buffer + ema. O prompt colado pelo user já está no buffer.
M.predict_next_total = function(current_tokens)
    return current_tokens + M.state.ema
end

-- BUG 1 CORRIGIDO: Imunidade do Primeiro Turno
M.is_immune = function()
    -- Se o tracker tem menos de 2 turnos gravados, estamos na aurora do chat. Bloqueio total.
    return M.state.count < 2
end

return M




======== ./lua/multi_context/context_builders.lua ========
local M = {}
local api = vim.api

local function strip_ansi(s) return s:gsub("\27%[[%d;]*m", ""):gsub("\27%[[%d;]*[A-Za-z]", "") end

-- FASE 1: Validação Rigorosa de Arquivo (Tamanho e Binário)
local function read_file_safe(filepath)
    local stat = vim.loop.fs_stat(filepath)
    if not stat then return nil end
    
    -- Ignora > 100KB
    if stat.size > 100 * 1024 then
        return { "=== AVISO: ARQUIVO IGNORADO (Maior que 100KB) ===" }
    end
    
    -- Heurística simples para detectar binários: checa NULL bytes no começo
    local fd = vim.loop.fs_open(filepath, "r", 438)
    if fd then
        local chunk = vim.loop.fs_read(fd, 1024, 0)
        vim.loop.fs_close(fd)
        if chunk and chunk:find("\0") then
            return { "=== AVISO: ARQUIVO BINÁRIO IGNORADO ===" }
        end
    end
    
    local lines = vim.fn.readfile(filepath)
    local numbered = {}
    for i, l in ipairs(lines) do
        table.insert(numbered, string.format("%d | %s", i, l))
    end
    return numbered
end

M.get_git_diff = function()
    vim.fn.system("git rev-parse --show-toplevel")
    if vim.v.shell_error ~= 0 then return "=== Não é um repositório Git ===" end
    local diff = vim.fn.system("git -c color.ui=never -c color.diff=never diff HEAD")
    return "=== GIT DIFF ===\n" .. strip_ansi(diff)
end

M.get_tree_context = function()
    local dir   = vim.fn.expand('%:p:h')
    local tree  = strip_ansi(vim.fn.system("tree -f --noreport " .. vim.fn.shellescape(dir)))
    local ctx   = { "=== TREE E CONTEÚDO ===", tree }
    local found = vim.fn.split(vim.fn.system("find " .. vim.fn.shellescape(dir) .. " -maxdepth 2 -type f"), "\n")
    for _, f in ipairs(found) do
        if not f:match("/%.git/") and f ~= "" then
            table.insert(ctx, ""); table.insert(ctx, "== Arquivo: " .. f .. " ==")
            local lines = read_file_safe(f)
            if lines then for _, l in ipairs(lines) do table.insert(ctx, l) end end
        end
    end
    return table.concat(ctx, "\n")
end

M.get_all_buffers_content = function()
    local result = {}
    for _, bufnr in ipairs(api.nvim_list_bufs()) do
        if api.nvim_buf_is_loaded(bufnr) then
            local name = api.nvim_buf_get_name(bufnr)
            local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
            if #lines > 0 and name ~= "" then
                table.insert(result, "=== Buffer: " .. name .. " ===")
                for i, l in ipairs(lines) do
                    table.insert(result, string.format("%d | %s", i, l))
                end
                table.insert(result, "")
            end
        end
    end
    return table.concat(result, "\n")
end

M.get_current_buffer = function()
    local buf = api.nvim_get_current_buf()
    local lines = api.nvim_buf_get_lines(buf, 0, -1, false)
    local numbered = {}
    for i, l in ipairs(lines) do 
        table.insert(numbered, string.format("%d | %s", i, l)) 
    end
    return "=== BUFFER ATUAL ===\n" .. table.concat(numbered, "\n")
end

M.get_visual_selection = function(line1, line2)
    local buf = api.nvim_get_current_buf()
    local s = tonumber(line1) or vim.fn.getpos("'<")[2]
    local e = tonumber(line2) or vim.fn.getpos("'>")[2]
    if s > e then s, e = e, s end
    
    local lines = api.nvim_buf_get_lines(buf, s - 1, e, false)
    local numbered = {}
    for i, l in ipairs(lines) do 
        table.insert(numbered, string.format("%d | %s", s + i - 1, l)) 
    end
    
    return "=== SELEÇÃO (linhas " .. s .. "-" .. e .. ") ===\n" .. table.concat(numbered, "\n")
end

M.get_folder_context = function()
    local dir = vim.fn.getcwd()
    local found = vim.fn.split(vim.fn.system("find " .. vim.fn.shellescape(dir) .. " -maxdepth 1 -type f"), "\n")
    local ctx = { "=== CONTEÚDO DA PASTA ATUAL (" .. dir .. ") ===" }
    for _, f in ipairs(found) do
        if not f:match("/%.git/") and f ~= "" then
            table.insert(ctx, ""); table.insert(ctx, "== Arquivo: " .. f .. " ==")
            local lines = read_file_safe(f)
            if lines then for _, l in ipairs(lines) do table.insert(ctx, l) end end
        end
    end
    return table.concat(ctx, "\n")
end

M.get_repo_context = function()
    vim.fn.system("git rev-parse --show-toplevel")
    if vim.v.shell_error ~= 0 then return "=== Não é um repositório Git ===" end
    local root = vim.fn.system("git rev-parse --show-toplevel"):gsub("\n", "")
    local tracked_files = vim.fn.split(vim.fn.system("git -C " .. vim.fn.shellescape(root) .. " ls-files"), "\n")
    local ctx = { "=== CONTEÚDO DE TODO O REPOSITÓRIO GIT ===" }
    for _, f in ipairs(tracked_files) do
        if f ~= "" then
            local full_path = root .. "/" .. f
            table.insert(ctx, ""); table.insert(ctx, "== Arquivo: " .. f .. " ==")
            local lines = read_file_safe(full_path)
            if lines then for _, l in ipairs(lines) do table.insert(ctx, l) end end
        end
    end
    return table.concat(ctx, "\n")
end

return M




======== ./lua/multi_context/ui/highlights.lua ========
local api = vim.api
local M = {}

M.define_groups = function()
    vim.cmd("highlight default ContextSelectorTitle    gui=bold guifg=#FFA500 guibg=NONE")
    vim.cmd("highlight default ContextSelectorCurrent  gui=bold guifg=#B22222 guibg=NONE")
    vim.cmd("highlight default ContextSelectorSelected gui=bold guifg=#FFFF00 guibg=NONE")
    vim.cmd("highlight default ContextHeader gui=bold guifg=#FF4500 guibg=NONE")
    vim.cmd("highlight default ContextUserAI gui=bold guifg=#0000CD guibg=NONE")
    vim.cmd("highlight default ContextUser gui=bold guifg=#B22222 guibg=NONE")
    vim.cmd("highlight default ContextCurrentBuffer gui=bold guifg=#FFA500 guibg=NONE")
    vim.cmd("highlight default ContextUpdateMessages gui=bold guifg=#FFA500 guibg=NONE")
    vim.cmd("highlight default ContextBoldText gui=bold guifg=#FFA500 guibg=NONE")
    vim.cmd("highlight default ContextApiInfo gui=bold guifg=#FFA500 guibg=NONE")
end

M.apply_chat = function(buf)
    if not api.nvim_buf_is_valid(buf) then return end
    
    vim.api.nvim_buf_call(buf, function()
        M.define_groups()
        
        vim.cmd("syntax match ContextHeader '^===.*'")
        vim.cmd("syntax match ContextHeader '^== Arquivo:.*'")
        vim.cmd("syntax match ContextCurrentBuffer '^## buffer atual ##'")
        vim.cmd("syntax match ContextUpdateMessages '\\[mensagem enviada\\]'")
        vim.cmd("syntax match ContextUpdateMessages '\\[Enviando requisição.*\\]'")
        
        -- CORREÇÃO: Usando o Regex nativo do Vim (.*)
        -- 1. Pinta QUALQUER cabecalho "## QualquerNome >>" de Vermelho
        vim.cmd("syntax match ContextUser '^## .* >>.*'")
        
        -- 2. Sobrescreve com Azul especificamente se for "## IA"
        vim.cmd("syntax match ContextUserAI '^## IA.*'")
        
        vim.cmd("syntax match ContextApiInfo '^## API atual:.*'")
        
        vim.cmd("syntax region ContextBold matchgroup=ContextBoldText start='\\*\\*' end='\\*\\*'")
        vim.cmd("syntax region ContextCodeBlock start='^```' end='^```'")
        vim.cmd("highlight default link ContextCodeBlock String")
        vim.cmd("highlight default link ContextBold ContextBoldText")
    end)
end

M.apply_selector = function(buf, api_list)
    if not api.nvim_buf_is_valid(buf) then return end
    M.define_groups()
    api.nvim_buf_add_highlight(buf, -1, "ContextSelectorTitle", 0, 0, -1)
    api.nvim_buf_add_highlight(buf, -1, "ContextSelectorTitle", 1, 0, -1)

    for i = 3, 3 + #api_list - 1 do
        local line = api.nvim_buf_get_lines(buf, i, i + 1, false)[1]
        if line then
            if line:match("^❯") then api.nvim_buf_add_highlight(buf, -1, "ContextSelectorCurrent", i, 0, -1) end
            if line:match("%(selecionada%)$") then api.nvim_buf_add_highlight(buf, -1, "ContextSelectorSelected", i, 0, -1) end
        end
    end

    local total = api.nvim_buf_line_count(buf)
    if total >= 2 then api.nvim_buf_add_highlight(buf, -1, "ContextSelectorTitle", total - 2, 0, -1) end
end

return M




======== ./lua/multi_context/ui/scroller.lua ========
-- lua/multi_context/ui/scroller.lua
local api = vim.api
local M = {}

M.state = {
    is_streaming = false,
    is_following = true,
    last_row = 0,
    augroup = api.nvim_create_augroup("MultiContextScroller", { clear = true })
}

M.start_streaming = function(buf, win)
    M.state.is_streaming = true
    M.state.is_following = true
    M.state.last_row = 0

    if win and api.nvim_win_is_valid(win) and buf and api.nvim_buf_is_valid(buf) then
        local lines = api.nvim_buf_line_count(buf)
        pcall(api.nvim_win_set_cursor, win, {lines, 0})
        M.state.last_row = lines
    end

    api.nvim_clear_autocmds({ group = M.state.augroup, buffer = buf })
    api.nvim_create_autocmd("CursorMoved", {
        group = M.state.augroup,
        buffer = buf,
        callback = function()
            if not M.state.is_streaming then return end
            if not api.nvim_win_is_valid(win) then return end
            
            local cursor_row = api.nvim_win_get_cursor(win)[1]
            local total_lines = api.nvim_buf_line_count(buf)
            
            -- A SUA LÓGICA: Tem que estar estritamente na última linha para seguir!
            if cursor_row == total_lines then
                M.state.is_following = true
            -- Qualquer subida real (mesmo que apenas 1 k) vai ser menor que a last_row
            elseif cursor_row < M.state.last_row then
                M.state.is_following = false
            end
            
            M.state.last_row = cursor_row
        end
    })
end

M.on_chunk_received = function(buf, win)
    if not M.state.is_streaming then return end
    
    if M.state.is_following then
        if win and api.nvim_win_is_valid(win) and buf and api.nvim_buf_is_valid(buf) then
            local lines = api.nvim_buf_line_count(buf)
            pcall(api.nvim_win_set_cursor, win, {lines, 0})
            vim.api.nvim_win_call(win, function()
                vim.cmd("normal! G")
            end)
        end
    end
end

M.stop_streaming = function(buf)
    M.state.is_streaming = false
    M.state.is_following = true
    M.state.last_row = 0
    pcall(api.nvim_clear_autocmds, { group = M.state.augroup, buffer = buf })
end

return M




======== ./lua/multi_context/ui/popup.lua ========
local api = vim.api
local M   = {}

M.popup_buf = nil
M.popup_win = nil
M.code_buf_before_popup = nil
M.swarm_buffers = {}
M.current_swarm_index = 1

function M.create_popup(initial_content_or_bufnr)
    -- RASTREAMENTO: Salva o buffer de código ativo antes do popup roubar o foco
    if not (M.popup_win and api.nvim_win_is_valid(M.popup_win)) then
        local cur = api.nvim_get_current_buf()
        if vim.bo[cur].buftype == "" then
            M.code_buf_before_popup = cur
        end
    end

    if M.popup_win and api.nvim_win_is_valid(M.popup_win) then
    end

    local config = require('multi_context.config')
    local hl     = require('multi_context.ui.highlights')
    
    local buf
    
    if type(initial_content_or_bufnr) == "number" and api.nvim_buf_is_valid(initial_content_or_bufnr) then
        buf = initial_content_or_bufnr
    else
        buf = api.nvim_create_buf(false, true)
        
        vim.bo[buf].buftype   = 'nofile'
        vim.bo[buf].bufhidden = 'hide'
        vim.bo[buf].swapfile  = false
        
        local user_prefix = "## " .. config.options.user_name .. " >> "
        if type(initial_content_or_bufnr) == "string" and initial_content_or_bufnr ~= "" then
            local init_lines = vim.split(initial_content_or_bufnr, "\n", { plain = true })
            api.nvim_buf_set_lines(buf, 0, -1, false, init_lines)
            
            local has_prompt = false
            for i = #init_lines, 1, -1 do
                if init_lines[i] ~= "" then
                    if init_lines[i]:match("^## " .. config.options.user_name .. " >>") then
                        has_prompt = true
                    end
                    break
                end
            end
            
            if not has_prompt then
                api.nvim_buf_set_lines(buf, -1, -1, false, { "", user_prefix })
            end
        else
            api.nvim_buf_set_lines(buf, 0, -1, false, { user_prefix })
        end
    end

    M.popup_buf = buf
    if not M.swarm_buffers or #M.swarm_buffers == 0 or M.swarm_buffers[1].buf ~= buf then
        M.swarm_buffers = { { buf = buf, name = "Main" } }
        M.current_swarm_index = 1
    end
    vim.bo[buf].filetype  = 'multicontext_chat'

    local km = { noremap = true, silent = true }
    api.nvim_buf_set_keymap(buf, "n", "<CR>", "<Cmd>lua require('multi_context').SendFromPopup()<CR>", km)
    api.nvim_buf_set_keymap(buf, "i", "<C-CR>", "<Esc><Cmd>lua require('multi_context').SendFromPopup()<CR>", km)
    api.nvim_buf_set_keymap(buf, "n", "<C-CR>", "<Cmd>lua require('multi_context').SendFromPopup()<CR>", km)
    api.nvim_buf_set_keymap(buf, "i", "<S-CR>", "<Esc><Cmd>lua require('multi_context').SendFromPopup()<CR>", km)
    api.nvim_buf_set_keymap(buf, "n", "<S-CR>", "<Cmd>lua require('multi_context').SendFromPopup()<CR>", km)
    api.nvim_buf_set_keymap(buf, "n", "<A-b>", "<Cmd>lua require('multi_context.utils').copy_code_block()<CR>", km)
    api.nvim_buf_set_keymap(buf, "i", "<A-b>", "<Esc><Cmd>lua require('multi_context.utils').copy_code_block()<CR>a", km)
        api.nvim_buf_set_keymap(buf, "n", "q", "<Cmd>q<CR>", km)
    api.nvim_buf_set_keymap(buf, "n", "<Tab>", "<Cmd>lua require('multi_context.ui.popup').cycle_swarm_buffer(1)<CR>", km)
    api.nvim_buf_set_keymap(buf, "n", "<S-Tab>", "<Cmd>lua require('multi_context.ui.popup').cycle_swarm_buffer(-1)<CR>", km)
    
    api.nvim_buf_set_keymap(buf, "n", "<C-x>", "<Cmd>lua require('multi_context.react_loop').abort_stream(true)<CR>", km)
    api.nvim_buf_set_keymap(buf, "i", "<C-x>", "<Esc><Cmd>lua require('multi_context.react_loop').abort_stream(true)<CR>", km)
    api.nvim_buf_set_keymap(buf, "n", "<C-x>", "<Cmd>lua require('multi_context.react_loop').abort_stream(true)<CR>", km)
    api.nvim_buf_set_keymap(buf, "i", "<C-x>", "<Esc><Cmd>lua require('multi_context.react_loop').abort_stream(true)<CR>", km)

    api.nvim_buf_set_keymap(buf, "i", "@", "@<Esc><Cmd>lua require('multi_context.agents').open_agent_selector()<CR>", km)

    api.nvim_buf_set_keymap(buf, "n", "<A-x>", "<Cmd>lua require('multi_context').ExecuteTools()<CR>", km)
    api.nvim_buf_set_keymap(buf, "i", "<A-x>", "<Esc><Cmd>lua require('multi_context').ExecuteTools()<CR>", km)

    local width  = math.ceil(vim.o.columns * 0.8)
    local height = math.ceil(vim.o.lines   * 0.8)
    local row    = math.ceil((vim.o.lines   - height) / 2)
    local col    = math.ceil((vim.o.columns - width)  / 2)

    local win = api.nvim_open_win(buf, true, {
        relative  = 'editor',
        width     = width,
        height    = height,
        row       = row,
        col       = col,
        style     = 'minimal',
        border    = 'rounded',
        title     = " Multi_Context_Chat | ~0 tokens ",
        title_pos = 'center',
    })
    M.popup_win = win

    -- =======================================================
    -- ATUALIZADOR AO VIVO: Modificado pelo usuário
    -- =======================================================
    api.nvim_create_autocmd({"TextChanged", "TextChangedI", "TextChangedP"}, {
        buffer = buf,
        callback = function()
            require('multi_context.ui.popup').update_title()
        end
    })

    api.nvim_create_autocmd("WinClosed", {
        pattern  = tostring(win),
        once     = true,
        callback = function() M.popup_win = nil end,
    })

    local last_ln  = api.nvim_buf_line_count(buf)
    local last_txt = api.nvim_buf_get_lines(buf, last_ln - 1, last_ln, false)[1] or ""
    api.nvim_win_set_cursor(win, { last_ln, #last_txt })

    hl.apply_chat(buf)
    M.create_folds(buf)
    
    M.update_title()

    return buf, win
end

function M.fold_text()
    local lines_count = vim.v.foldend - vim.v.foldstart + 1
    local preview = ""
    for i = vim.v.foldstart, vim.v.foldend do
        local l = vim.fn.getline(i)
        if l:match("%S") then
            preview = vim.trim(l)
            break
        end
    end
    return "    ↳ ⋯ [" .. lines_count .. " linhas ocultas] ⋯  " .. preview
end

function M.create_folds(buf)
    if not buf or not api.nvim_buf_is_valid(buf) then return end

    local config = require('multi_context.config')
    local user_name = config.options.user_name or "User"

    vim.schedule(function()
        if not api.nvim_buf_is_valid(buf) then return end

        local windows = vim.fn.win_findbuf(buf)
        for _, win in ipairs(windows) do
            if api.nvim_win_is_valid(win) then
                vim.api.nvim_win_call(win, function()
                    vim.cmd("setlocal foldmethod=manual")
                    vim.cmd("setlocal foldexpr=")
                    vim.cmd("setlocal foldtext=v:lua.require('multi_context.ui.popup').fold_text()")
                    pcall(vim.cmd, 'normal! zE')

                    local total_lines = vim.api.nvim_buf_line_count(buf)
                    local headers = {}

                    for lnum = 1, total_lines do
                        local line = vim.api.nvim_buf_get_lines(buf, lnum - 1, lnum, false)[1]
                        if line and (line:match("^===") or line:match("^== Arquivo:") or 
                            line:match("^## " .. user_name .. " >>") or line:match("^## IA")) then
                            table.insert(headers, lnum)
                        end
                    end

                    for idx, h_lnum in ipairs(headers) do
                        local header_text = vim.api.nvim_buf_get_lines(buf, h_lnum - 1, h_lnum, false)[1]

                        if not header_text:match("^## " .. user_name) then
                            local start_fold = h_lnum + 1
                            local end_fold = total_lines

                            if idx < #headers then
                                end_fold = headers[idx + 1] - 1
                            end

                            if end_fold >= start_fold then
                                pcall(vim.cmd, string.format("%d,%dfold", start_fold, end_fold))
                                pcall(vim.cmd, string.format("%dfoldclose", start_fold))
                            end
                        end
                    end

                    for i = #headers, 1, -1 do
                        local h_lnum = headers[i]
                        local l = vim.api.nvim_buf_get_lines(buf, h_lnum - 1, h_lnum, false)[1]
                        if l and l:match("^## IA") then
                            pcall(vim.cmd, string.format("silent! %dfoldopen!", h_lnum + 1))
                            break
                        end
                    end

                    local win_height = vim.api.nvim_win_get_height(win)
                    local target_scrolloff = math.floor(win_height / 3)
                    local current_so = vim.wo.scrolloff

                    vim.wo.scrolloff = target_scrolloff
                    pcall(vim.cmd, "normal! zb")
                    vim.wo.scrolloff = current_so
                end)
            end
        end
    end)
end

-- =======================================================
-- MÁGICA VISUAL: Altera o Título da Janela Dinamicamente
-- =======================================================
function M.update_title()
    if not M.popup_win or not vim.api.nvim_win_is_valid(M.popup_win) then return end
    
    local ok, conf = pcall(vim.api.nvim_win_get_config, M.popup_win)
    if ok and conf.relative and conf.relative ~= "" then
        local utils = require('multi_context.utils')
        
        -- Descobre qual buffer está na tela agora
        local active_buf = M.popup_buf
        if M.swarm_buffers and #M.swarm_buffers > 0 and M.current_swarm_index then
            local sb = M.swarm_buffers[M.current_swarm_index]
            if sb and sb.buf and vim.api.nvim_buf_is_valid(sb.buf) then
                active_buf = sb.buf
            end
        end
        
        -- Calcula os tokens do buffer que o usuário está olhando
        local tokens = utils.estimate_tokens(active_buf)
        
        local new_title = ""
        if M.swarm_buffers and #M.swarm_buffers > 1 then
            local parts = {}
            for i, sb in ipairs(M.swarm_buffers) do
                local prefix = (i == M.current_swarm_index) and "*" or ""
                table.insert(parts, string.format("%s[%d:%s]", prefix, i, sb.name))
            end
            new_title = " " .. table.concat(parts, " | ") .. string.format(" | ~%d tokens ", tokens) .. " "
        else
            new_title = string.format(" Multi_Context_Chat | ~%d tokens ", tokens)
        end
        
        pcall(vim.api.nvim_win_set_config, M.popup_win, { title = new_title, title_pos = 'center' })
    end
end


function M.create_swarm_buffer(agent_name, initial_instruction, api_name)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].buftype   = 'nofile'
    vim.bo[buf].bufhidden = 'hide'
    vim.bo[buf].swapfile  = false
    vim.bo[buf].filetype  = 'multicontext_chat'

    local lines = { "=== SWARM WORKER ===", "Agente: @" .. agent_name, "API: " .. (api_name or "Desconhecida"), "", initial_instruction or "", "" }
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    if not M.swarm_buffers then M.swarm_buffers = {} end
    table.insert(M.swarm_buffers, { buf = buf, name = agent_name, status = "Rodando" })

    local km = { noremap = true, silent = true }
    vim.api.nvim_buf_set_keymap(buf, "n", "q", "<Cmd>q<CR>", km)
    vim.api.nvim_buf_set_keymap(buf, "n", "<Tab>", "<Cmd>lua require('multi_context.ui.popup').cycle_swarm_buffer(1)<CR>", km)
    vim.api.nvim_buf_set_keymap(buf, "n", "<S-Tab>", "<Cmd>lua require('multi_context.ui.popup').cycle_swarm_buffer(-1)<CR>", km)
    
    require('multi_context.ui.highlights').apply_chat(buf)
    M.create_folds(buf)
    
    return buf
end

function M.cycle_swarm_buffer(dir)
    if not M.swarm_buffers or #M.swarm_buffers < 2 then return end
    M.current_swarm_index = M.current_swarm_index + dir
    if M.current_swarm_index > #M.swarm_buffers then M.current_swarm_index = 1 end
    if M.current_swarm_index < 1 then M.current_swarm_index = #M.swarm_buffers end

    local target_buf = M.swarm_buffers[M.current_swarm_index].buf
    if M.popup_win and vim.api.nvim_win_is_valid(M.popup_win) then
        vim.api.nvim_win_set_buf(M.popup_win, target_buf)
        M.update_title()
    end
end

return M




======== ./lua/multi_context/swarm_manager.lua ========
local config = require('multi_context.config')
local api_client = require('multi_context.api_client')
local popup = require('multi_context.ui.popup')
local tools = require('multi_context.tools')
local agents = require('multi_context.agents')
local tool_parser = require('multi_context.tool_parser')
local tool_runner = require('multi_context.tool_runner')

local M = {}
M.state = { queue = {}, workers = {}, reports = {} }

M.reset = function() M.state.queue = {}; M.state.workers = {}; M.state.reports = {} end

M.init_swarm = function(json_payload)
    M.reset()
    if not json_payload or json_payload == "" then return false end
    local ok, decoded = pcall(vim.fn.json_decode, vim.trim(json_payload))
    if not ok or type(decoded) ~= "table" or type(decoded.tasks) ~= "table" then return false end
    
    -- Pré-processamento de Tarefas Avançadas (Fase 21)
    for _, task in ipairs(decoded.tasks) do
        if not task.agent and type(task.chain) == "table" and #task.chain > 0 then
            task.agent = task.chain[1]
        end
    end
    
    M.state.queue = decoded.tasks
    local apis = config.get_spawn_apis()
    for _, api_cfg in ipairs(apis) do
        table.insert(M.state.workers, { api = api_cfg, busy = false, current_task = nil })
    end
    return true
end

M.dispatch_next = function()
    -- FINALIZADOR (REDUCE)
    if #M.state.queue == 0 then
        local any_busy = false
        for _, w in ipairs(M.state.workers) do if w.busy then any_busy = true; break end end
        if not any_busy and M.on_swarm_complete then
            local summary = "=== RELATÓRIO DO ENXAME (SWARM) ===\n"
            for _, rep in ipairs(M.state.reports) do
                summary = summary .. "\nAgente: @" .. rep.agent .. "\nResultado Final:\n" .. rep.result .. "\n------------------------"
            end
            M.on_swarm_complete(summary)
        end
        return
    end

    -- DESPACHANTE (MAP)
        local level_val = { low = 1, medium = 2, high = 3 }
    local loaded_agents = require('multi_context.agents').load_agents()

    -- Processa a fila inteira procurando match para cada tarefa
    local i = 1
        local max_attempts = #M.state.queue
    local attempts = 0
    while i <= #M.state.queue and attempts < max_attempts do
        attempts = attempts + 1
        local task = M.state.queue[i]
        local agent_def = loaded_agents[task.agent]
        local req_level = (agent_def and agent_def.abstraction_level) and level_val[agent_def.abstraction_level] or 3
        
        local selected_worker = nil
        local best_diff = 999
        
        for _, worker in ipairs(M.state.workers) do
            if not worker.busy then
                local api_level = worker.api.abstraction_level and level_val[worker.api.abstraction_level] or 2
                
                -- Se a API é forte o suficiente para a tarefa
                if api_level >= req_level then
                    local diff = api_level - req_level
                    -- Preferimos o Match perfeito (diff 0). Se nao houver, pegamos o proximo mais barato
                    if diff < best_diff then
                        best_diff = diff
                        selected_worker = worker
                    end
                end
            end
        end

        if selected_worker then
            table.remove(M.state.queue, i)
            local worker = selected_worker
            worker.busy = true
            worker.current_task = task

            worker.busy = true
            worker.current_task = task
            local buf_id = popup.create_swarm_buffer(task.agent, task.instruction, worker.api.name)
            
            local loaded_agents = agents.load_agents()
            local system_prompt = "Você é um sub-agente operando em modo SWARM. Sua tarefa estrita é: " .. (task.instruction or "")
            if loaded_agents[task.agent] then
                system_prompt = system_prompt .. "\n\n=== SUAS DIRETRIZES ===\n" .. loaded_agents[task.agent].system_prompt
            end
            
            local context_text = ""
            if type(task.context) == "table" then
                for _, path in ipairs(task.context) do
                    if path ~= "*" and path ~= "" then
                        context_text = context_text .. "\n== Arquivo: " .. path .. " ==\n" .. tools.read_file(path)
                    end
                end
            end
            system_prompt = system_prompt .. "\n\n=== CONTEXTO INICIAL FORNECIDO ===\n" .. context_text            
            system_prompt = system_prompt .. "\n\n=== REGRAS DE ENTREGA (MANDATÓRIO) ===\nQuando terminar a tarefa e não precisar usar mais nenhuma ferramenta, você DEVE entregar o seu relatório final dentro das tags <final_report>...</final_report>. Esta tag encerra a sua execução. Sem ela, o mestre não lerá sua resposta."

            
            local messages = {
                { role = "system", content = system_prompt },
                { role = "user", content = "Inicie a execução da sua tarefa. Se precisar de mais informações, use as ferramentas disponíveis. Quando finalizar todo o trabalho, dê um resumo." }
            }
            
            local visual_history = ""
            local final_report_text = ""

            -- O MOTOR REACT RECURSIVO DO SUB-AGENTE
            local function execute_turn()
                local current_chunk = ""
                api_client.execute(messages,
                    function() end,
                    function(chunk) 
                        current_chunk = current_chunk .. chunk 
                        if buf_id and vim.api.nvim_buf_is_valid(buf_id) then
                            local display_text = visual_history .. "\n\n## IA >>\n" .. current_chunk
                            local lines = vim.split(display_text, "\n", {plain=true})
                            vim.api.nvim_buf_set_lines(buf_id, 4, -1, false, lines)
                        end
                    end,
                    function(api_entry, metrics)
                        visual_history = visual_history .. "\n\n## IA >>\n" .. current_chunk
                        table.insert(messages, { role = "assistant", content = current_chunk })
                                                -- FASE 20: Extrai APENAS o bloco estruturado, evitando Token Leak
                        local extracted_report = current_chunk:match("<final_report>(.-)</final_report>")
                        if extracted_report then
                            final_report_text = vim.trim(extracted_report)
                        else
                            final_report_text = "" -- Forçará o retry logo abaixo
                        end

                        
                        local sanitized = tool_parser.sanitize_payload(current_chunk)
                        
                        -- SE A IA USOU FERRAMENTAS, EXECUTA E CHAMA O PRÓXIMO TURNO
                        if sanitized:match("<tool_call") then
                            local new_content = ""
                            local cursor = 1
                            local approve_ref = { value = true } -- Auto Approve SILENCIOSO
                            
                            while cursor <= #sanitized do
                                local parsed = tool_parser.parse_next_tool(sanitized, cursor)
                                if not parsed then break end
                                if parsed.is_invalid or not parsed.name or parsed.name == "" then
                                    cursor = parsed.close_end + 1
                                else
                                    local tag_out = tool_runner.execute(parsed, true, approve_ref, buf_id)
                                    new_content = new_content .. "\n" .. tag_out
                                    cursor = parsed.close_end + 1
                                end
                            end
                            
                            if new_content ~= "" then
                                local switch_target = new_content:match("SWITCH_AGENT_REQUEST:([%w_]+)")
                                if switch_target then
                                    local is_allowed = false
                                    if type(task.allow_switch) == "table" then
                                        for _, allowed in ipairs(task.allow_switch) do
                                            if allowed == switch_target then is_allowed = true; break end
                                        end
                                    end
                                    
                                    if is_allowed then
                                        task.agent = switch_target
                                        local loaded_agents = require('multi_context.agents').load_agents()
                                        local new_system = "Você é um sub-agente operando em modo SWARM. Sua tarefa estrita é: " .. (task.instruction or "")
                                        if loaded_agents[switch_target] then
                                            new_system = new_system .. "\n\n=== SUAS DIRETRIZES ===\n" .. loaded_agents[switch_target].system_prompt
                                        end
                                        new_system = new_system .. "\n\n=== CONTEXTO INICIAL FORNECIDO ===\n" .. context_text
                                        new_system = new_system .. "\n\n=== REGRAS DE ENTREGA (MANDATÓRIO) ===\nQuando terminar a tarefa e não precisar usar mais nenhuma ferramenta, você DEVE entregar o seu relatório final dentro das tags <final_report>...</final_report>. Esta tag encerra a sua execução. Sem ela, o mestre não lerá sua resposta."
                                        
                                        messages[1].content = new_system
                                        new_content = "SUCESSO: Controle transferido para @" .. switch_target .. ". O sistema foi reconfigurado com suas diretrizes."
                                        
                                        if buf_id and vim.api.nvim_buf_is_valid(buf_id) then
                                            local popup = require('multi_context.ui.popup')
                                            if popup.swarm_buffers then
                                                for _, sb in ipairs(popup.swarm_buffers) do
                                                    if sb.buf == buf_id then
                                                        sb.name = switch_target
                                                        break
                                                    end
                                                end
                                            end
                                            pcall(popup.update_title)
                                        end
                                    else
                                        new_content = "ERRO: O agente @" .. task.agent .. " não tem permissão para transferir o controle para @" .. switch_target .. " (Verifique allow_switch)."
                                    end
                                end

                                visual_history = visual_history .. "\n\n## Sistema >>\n" .. new_content
                                table.insert(messages, { role = "user", content = new_content })
                                -- Recursão! O agente chama a API novamente para ler o output da ferramenta
                                execute_turn() 
                                return
                            end
                        end
                        
                        -- SE CHEGOU AQUI, ELE NÃO USOU FERRAMENTAS. A TAREFA ACABOU!
                        if buf_id and vim.api.nvim_buf_is_valid(buf_id) then
                            local lines = vim.api.nvim_buf_get_lines(buf_id, 0, -1, false)
                            table.insert(lines, "")
                            table.insert(lines, "✅ TAREFA CONCLUÍDA")
                            vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
                        end
                        
                                                worker.busy = false
                        local clean_res = final_report_text:gsub("%s+", "")
                        
                        task.retries = task.retries or 0
                        if clean_res == "" and task.retries < 2 then
                            task.retries = task.retries + 1
                            if buf_id and vim.api.nvim_buf_is_valid(buf_id) then
                                local lines = vim.api.nvim_buf_get_lines(buf_id, 0, -1, false)
                                table.insert(lines, "⚠️ API retornou vazio. Devolvendo tarefa para a fila (Tentativa " .. task.retries .. "/2)...")
                                vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
                            end
                            table.insert(M.state.queue, task)
                        else
                            if clean_res == "" then final_report_text = "FALHA: A API falhou repetidas vezes em processar esta tarefa." end
                            local has_next = false
                            if type(task.chain) == 'table' then
                                local c_idx = 0
                                for idx, a in ipairs(task.chain) do if a == task.agent then c_idx = idx; break end end
                                if c_idx > 0 and c_idx < #task.chain then
                                    task.agent = task.chain[c_idx + 1]
                                    task.instruction = (task.instruction or '') .. '\n\n=== RELATÓRIO DO AGENTE ANTERIOR ===\n' .. final_report_text
                                    task.retries = 0
                                    table.insert(M.state.queue, task)
                                    has_next = true
                                end
                            end
                            if not has_next then
                            table.insert(M.state.reports, { agent = task.agent, result = final_report_text })
                            end
                        end
                        vim.schedule(M.dispatch_next) -- Chama o próximo da fila

                    end,
                    function(err)
                        if buf_id and vim.api.nvim_buf_is_valid(buf_id) then
                            local lines = vim.api.nvim_buf_get_lines(buf_id, 0, -1, false)
                            table.insert(lines, "")
                            table.insert(lines, "❌ ERRO NA API: " .. tostring(err))
                            vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
                        end
                                                worker.busy = false
                        task.retries = task.retries or 0
                        if task.retries < 2 then
                            task.retries = task.retries + 1
                            if buf_id and vim.api.nvim_buf_is_valid(buf_id) then
                                local lines = vim.api.nvim_buf_get_lines(buf_id, 0, -1, false)
                                table.insert(lines, "⚠️ Falha na API (".. worker.api.name .. "). Devolvendo para a fila (Tentativa " .. task.retries .. "/2)...")
                                vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
                            end
                            table.insert(M.state.queue, task)
                        else
                            table.insert(M.state.reports, { agent = task.agent, result = "ERRO FATAL APÓS TENTATIVAS: " .. tostring(err) })
                        end
                        vim.schedule(M.dispatch_next)

                    end,
                    worker.api
                )
            end
            
            execute_turn()
        else
            i = i + 1
        end
    end
end

return M




======== ./lua/multi_context/agents.lua ========
-- lua/multi_context/agents.lua
local api = vim.api
local M = {}

M.agents_file = vim.fn.stdpath("config") .. "/mctx_agents.json"

M.load_agents = function()
    if vim.fn.filereadable(M.agents_file) == 0 then
        local curr_file = debug.getinfo(1, "S").source:sub(2)
        local default_agents_file = vim.fn.fnamemodify(curr_file, ":h") .. "/agents/agents.json"
        
        if vim.fn.filereadable(default_agents_file) == 1 then
            local lines = vim.fn.readfile(default_agents_file)
            vim.fn.writefile(lines, M.agents_file)
            vim.notify("[MultiContext] Arquivo base de Agentes instalado em: " .. M.agents_file, vim.log.levels.INFO)
        else
            vim.fn.writefile({"{}"}, M.agents_file)
        end
    end

    local file = io.open(M.agents_file, 'r')
    if not file then return {} end
    local content = file:read('*a')
    file:close()
    local ok, parsed = pcall(vim.fn.json_decode, content)
        if ok and parsed then
        for _, agent in pairs(parsed) do
            if not agent.abstraction_level then
                agent.abstraction_level = "high"
            end
        end
    end
    return ok and parsed or {}

end

M.get_agent_names = function()
    local agents = M.load_agents()
    local names = {}
    for name, _ in pairs(agents) do table.insert(names, name) end
    table.sort(names)
    return names
end

M.selector_buf = nil; M.selector_win = nil; M.current_selection = 1; M.api_list = {}; M.parent_win = nil

M.open_agent_selector = function()
    M.api_list = M.get_agent_names()
    if #M.api_list == 0 then return end
    M.parent_win = api.nvim_get_current_win()
    M.current_selection = 1
    M.selector_buf = api.nvim_create_buf(false, true)
    M.selector_win = api.nvim_open_win(M.selector_buf, true, {
        relative = "cursor", row = 1, col = 0, width = 30, height = #M.api_list,
        style = "minimal", border = "rounded",
    })
    vim.bo[M.selector_buf].buftype = "nofile"
    M._render(); M._keymaps()
end

M._render = function()
    if not M.selector_buf or not api.nvim_buf_is_valid(M.selector_buf) then return end
    local lines = {}
    for i, name in ipairs(M.api_list) do
        local cursor = (i == M.current_selection) and "❯ " or "  "
        table.insert(lines, cursor .. name)
    end
    vim.bo[M.selector_buf].modifiable = true
    api.nvim_buf_set_lines(M.selector_buf, 0, -1, false, lines)
    local ns = api.nvim_create_namespace("mc_agents")
    api.nvim_buf_clear_namespace(M.selector_buf, ns, 0, -1)
    api.nvim_buf_add_highlight(M.selector_buf, ns, "ContextSelectorCurrent", M.current_selection - 1, 0, -1)
end

M._keymaps = function()
    if not M.selector_buf or not api.nvim_buf_is_valid(M.selector_buf) then return end
    local mk = function(k, fn) api.nvim_buf_set_keymap(M.selector_buf, "n", k, "", { callback = fn, noremap = true, silent = true }) end
    mk("j", function() M._move(1) end); mk("k", function() M._move(-1) end)
    mk("<CR>", M._select); mk("<Esc>", M._close); mk("q", M._close)
end

M._move = function(dir)
    local n = M.current_selection + dir
    if n >= 1 and n <= #M.api_list then M.current_selection = n; M._render() end
end

M._select = function()
    local name = M.api_list[M.current_selection]
    M._close_win_only()
    if M.parent_win and api.nvim_win_is_valid(M.parent_win) then
        api.nvim_set_current_win(M.parent_win)
        local row, col = unpack(api.nvim_win_get_cursor(0))
        local line = api.nvim_get_current_line()
        local new_line = string.sub(line, 1, col + 1) .. name .. string.sub(line, col + 2)
        api.nvim_set_current_line(new_line)
        api.nvim_win_set_cursor(0, {row, col + 1 + #name})
        api.nvim_feedkeys("a", "n", true)
    end
end

M._close_win_only = function()
    if M.selector_win and api.nvim_win_is_valid(M.selector_win) then api.nvim_win_close(M.selector_win, true) end
    M.selector_buf = nil; M.selector_win = nil
end
M._close = function()
    M._close_win_only()
    if M.parent_win and api.nvim_win_is_valid(M.parent_win) then api.nvim_set_current_win(M.parent_win); api.nvim_feedkeys("a", "n", true) end
end

return M




======== ./lua/multi_context/tool_runner.lua ========
-- lua/multi_context/tool_runner.lua
local M = {}
local tools = require('multi_context.tools')
local react_loop = require('multi_context.react_loop')

local valid_tools = {
    list_files = true, read_file = true, search_code = true,
    edit_file = true, run_shell = true, replace_lines = true, apply_diff = true,
    rewrite_chat_buffer = true, get_diagnostics = true, spawn_swarm = true, switch_agent = true
}

local dangerous_commands = {"rm%s+-rf", "mkfs", "sudo ", ">%s*/dev", "chmod ", "chown "}
local function is_dangerous(cmd)
    if not cmd then return false end
    for _, pat in ipairs(dangerous_commands) do if cmd:match(pat) then return true end end
    return false
end

M.execute = function(tool_data, is_autonomous, approve_all_ref, buf)
    local name = tool_data.name
    local clean_inner = tool_data.inner

    local skills_manager = require('multi_context.skills_manager')
    local custom_skills = skills_manager.get_skills()
    local is_custom_skill = custom_skills[name] ~= nil

    if not valid_tools[name] and not is_custom_skill then
        local err_msg = string.format("Ferramenta '%s' não existe.", tostring(name))
        local out = string.format('<tool_call name="%s">\n%s\n</tool_call>\n\n>[Sistema]: ERRO - %s', tostring(name), clean_inner, err_msg)
        return out, false, false, nil, nil
    end

    -- ==========================================
    -- GATEKEEPER DE SKILLS (Autorização)
    -- ==========================================
    local agents = require('multi_context.agents').load_agents()
    local active_agent = react_loop.state.active_agent
    local is_authorized = false

    if active_agent and agents[active_agent] and agents[active_agent].skills then
        for _, skill in ipairs(agents[active_agent].skills) do
            if skill == name then is_authorized = true; break end
        end
    else
        is_authorized = true -- Sem agente ativo (Modo Root/Manual), permite tudo
    end

    if not is_authorized then
        local err_msg = string.format("Operação negada. O agente @%s não possui a Skill '%s'.", tostring(active_agent), tostring(name))
        local out = string.format('<tool_call name="%s">\n%s\n</tool_call>\n\n>[Sistema]: ⛔ ERRO - %s', tostring(name), clean_inner, err_msg)
        return out, false, false, nil, nil
    end
    -- ==========================================

    local choice = 1
    if not approve_all_ref.value then
        if is_autonomous then
            if name == "run_shell" and is_dangerous(clean_inner) then
                vim.notify("🛡️ Comando PERIGOSO detectado.", vim.log.levels.ERROR)
                choice = vim.fn.confirm("Permitir execução PERIGOSA: " .. clean_inner, "&Sim\n&Nao\n&Todos\n&Cancelar", 2)
            elseif name == "rewrite_chat_buffer" then
                choice = vim.fn.confirm("Agente solicitou DESTRUIR E COMPRIMIR o chat. Permitir?", "&Sim\n&Nao\n&Todos\n&Cancelar", 1)
            else choice = 3; approve_all_ref.value = true end
        else
            choice = vim.fn.confirm(string.format("Agente requisitou [%s]. Permitir?", tostring(name)), "&Sim\n&Nao\n&Todos\n&Cancelar", 1)
        end
    end

    if choice == 3 then approve_all_ref.value = true; choice = 1 end
    if choice == 4 or choice == 0 then
        local out = string.format('<tool_call name="%s">\n%s\n</tool_call>', tostring(tool_data.raw_tag), clean_inner)
        return out, true, false, nil, nil
    end

    local result = ""
    local should_continue_loop = false
    local pending_rewrite_content = nil
    local backup_made = nil

    if choice == 2 then
        result = "Acesso NEGADO pelo usuario."
        local out = string.format('<tool_call name="%s">\n%s\n</tool_call>\n\n>[Sistema]: ERRO - %s', tostring(name), clean_inner, result)
        return out, false, false, nil, nil
    end

    if is_custom_skill then
        local args = {}
        if clean_inner then
            for p_name, p_val in clean_inner:gmatch("<([%w_]+)[^>]*>(.-)</%1>") do
                args[p_name] = vim.trim(p_val)
            end
        end
        local ok, skill_res = pcall(custom_skills[name].execute, args)
        if ok then
            result = tostring(skill_res)
            should_continue_loop = true
        else
            result = "ERRO NA EXECUCAO DA SKILL: " .. tostring(skill_res)
        end
    elseif name == "rewrite_chat_buffer" then
        backup_made = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        local backup_file = vim.fn.stdpath("data") .. "/mctx_backup_" .. os.date("%Y%m%d_%H%M%S") .. ".mctx"
        vim.fn.writefile(backup_made, backup_file)
        pending_rewrite_content = clean_inner
        result = "Buffer reescrito."
    elseif name == "list_files" then 
        should_continue_loop = true; result = tools.list_files()
    elseif name == "read_file" then 
        should_continue_loop = true; result = tools.read_file(tool_data.path)
    elseif name == "search_code" then 
        should_continue_loop = true; result = tools.search_code(tool_data.query)
    elseif name == "edit_file" then 
        result = tools.edit_file(tool_data.path, clean_inner)
        if is_autonomous and result:match("SUCESSO") then result = result .. "\n\n[Auto-LSP]:\n" .. tools.get_diagnostics(tool_data.path) end
    elseif name == "run_shell" then 
        result = tools.run_shell(clean_inner)
    elseif name == "replace_lines" then 
        result = tools.replace_lines(tool_data.path, tool_data.start_line, tool_data.end_line, clean_inner)
        if is_autonomous and result:match("SUCESSO") then result = result .. "\n\n[Auto-LSP]:\n" .. tools.get_diagnostics(tool_data.path) end
    elseif name == "apply_diff" then
        result = tools.apply_diff(tool_data.path, clean_inner)
        if is_autonomous and result:match("SUCESSO") then result = result .. "\n\n[Auto-LSP]:\n" .. tools.get_diagnostics(tool_data.path) end
    elseif name == "get_diagnostics" then 
        should_continue_loop = true; result = tools.get_diagnostics(tool_data.path)
    elseif name == "spawn_swarm" then
        local swarm = require('multi_context.swarm_manager')
        if swarm.init_swarm(clean_inner) then
            swarm.on_swarm_complete = require('multi_context').OnSwarmComplete
            vim.defer_fn(function() swarm.dispatch_next() end, 100)
            result = "SWARM INICIADO. O trabalho foi delegado aos sub-agentes e está rodando em background."
            should_continue_loop = false
        else
            result = "ERRO: O payload JSON fornecido para spawn_swarm é inválido."
        end
    elseif name == "switch_agent" then
        local target = clean_inner:match("<target_agent>(.-)</target_agent>")
        if not target then target = clean_inner:match("([%w_]+)") end
        if target then target = vim.trim(target) else target = "" end
        result = "SWITCH_AGENT_REQUEST:" .. target
        should_continue_loop = true
    end

    local output = ""
    if not pending_rewrite_content then
        output = string.format('<tool_call name="%s" path="%s">\n%s\n</tool_call>\n\n>[Sistema]: Resultado:\n```text\n%s\n```', tostring(name), tostring(tool_data.path or ""), clean_inner, result)
    end

    return output, false, should_continue_loop, pending_rewrite_content, backup_made
end

return M




======== ./lua/multi_context/api_client.lua ========
-- lua/multi_context/api_client.lua
local M = {}

local function build_queue(cfg)
    local queue = {}
    for _, a in ipairs(cfg.apis) do
        if a.name == cfg.default_api then table.insert(queue, a); break end
    end
    if cfg.fallback_mode then
        for _, a in ipairs(cfg.apis) do
            if a['include_in_fall-back_mode'] and a.name ~= cfg.default_api then table.insert(queue, a) end
        end
    end
    return queue
end

M.execute = function(messages, on_start, on_chunk, on_done, on_error, force_api_cfg)
    local config = require('multi_context.config')
    local api_handlers = require('multi_context.api_handlers')

    local cfg = config.load_api_config()
    if not cfg then on_error("Configuração de APIs não encontrada."); return end

        local queue = {}
    if force_api_cfg then
        table.insert(queue, force_api_cfg)
    else
        queue = build_queue(cfg)
        if #queue == 0 then on_error("Nenhuma API na fila. Configure com :ContextApis"); return end
    end


    local api_keys = config.load_api_keys()

    local function try(idx)
        if idx > #queue then on_error("Erro em todas as APIs da fila."); return end
        local entry = queue[idx]
        local handler = api_handlers[entry.api_type or "openai"]
        
        if not handler then try(idx + 1); return end
        
        handler.make_request(entry, messages, api_keys, nil, function(chunk, err, done, metrics, job_id)
            vim.schedule(function()
                if job_id and on_start then on_start(job_id) end
                if err then try(idx + 1); return end
                if chunk then on_chunk(chunk, entry) end
                if done then on_done(entry, metrics) end
            end)
        end)
    end

    try(1)
end

return M




======== ./lua/multi_context/init.lua ========
-- lua/multi_context/init.lua
local api = vim.api
local utils = require('multi_context.utils')
local popup = require('multi_context.ui.popup')
local commands = require('multi_context.commands')
local config = require('multi_context.config')

local tool_parser = require('multi_context.tool_parser')
local tool_runner = require('multi_context.tool_runner')
local react_loop = require('multi_context.react_loop')
local prompt_parser = require('multi_context.prompt_parser')
local scroller = require('multi_context.ui.scroller')

local M = {}
M.popup_buf = popup.popup_buf
M.popup_win = popup.popup_win
M.current_workspace_file = nil

M.setup = function(opts) if config and config.setup then config.setup(opts) end end

M.OnSwarmComplete = function(summary)
    local p = require('multi_context.ui.popup')
    local buf = p.popup_buf
    if not buf or not api.nvim_buf_is_valid(buf) then return end

    -- Volta o foco pro Main Buffer na janela flutuante
    if p.swarm_buffers and #p.swarm_buffers > 0 then
        p.current_swarm_index = 1
        if p.popup_win and api.nvim_win_is_valid(p.popup_win) then
            api.nvim_win_set_buf(p.popup_win, p.swarm_buffers[1].buf)
            p.update_title()
        end
    end

    local cfg = require('multi_context.config')
    local user_prefix = "## " .. (cfg.options.user_name or "Nardi") .. " >>"
    
    local lines = api.nvim_buf_get_lines(buf, 0, -1, false)
    table.insert(lines, "")
    table.insert(lines, user_prefix .. " [Sistema]:")
    
    local append_text = summary .. "\n\nPor favor, consolide essas informações, verifique se houve algum erro nos sub-agentes, e dê sua palavra final para o usuário."
    for _, l in ipairs(vim.split(append_text, "\n", {plain=true})) do
        table.insert(lines, l)
    end

    api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    require('multi_context.ui.highlights').apply_chat(buf)
    p.create_folds(buf)

    -- Rola a tela para o final
    if p.popup_win and api.nvim_win_is_valid(p.popup_win) then
        api.nvim_win_set_cursor(p.popup_win, {api.nvim_buf_line_count(buf), 0})
        vim.cmd("normal! zz")
    end

    -- Religa a IA automaticamente para dar a palavra final
    vim.defer_fn(function() require('multi_context').SendFromPopup() end, 100)
end

M.ContextChatFull = commands.ContextChatFull
M.ContextChatSelection = commands.ContextChatSelection
M.ContextChatFolder = commands.ContextChatFolder
M.ContextChatHandler = commands.ContextChatHandler
M.ContextChatRepo = commands.ContextChatRepo
M.ContextChatGit = commands.ContextChatGit
M.ContextApis = commands.ContextApis
M.ContextTree = commands.ContextTree
M.ContextBuffers = commands.ContextBuffers
M.TogglePopup = commands.TogglePopup

M.ContextUndo = function()
    local p = require('multi_context.ui.popup')
    local buf = p.popup_buf
    if not buf or not api.nvim_buf_is_valid(buf) then buf = api.nvim_get_current_buf() end
    if react_loop.state.last_backup then
        api.nvim_buf_set_lines(buf, 0, -1, false, react_loop.state.last_backup)
        require('multi_context.ui.highlights').apply_chat(buf)
        p.create_folds(buf)
        p.update_title()
        vim.notify("✅ Chat restaurado do último backup com sucesso!", vim.log.levels.INFO)
    else
        vim.notify("Nenhum backup de compressão encontrado nesta sessão.", vim.log.levels.WARN)
    end
end

M.ToggleWorkspaceView = function()
    local ui_popup = require('multi_context.ui.popup')
    local is_popup = (ui_popup.popup_win and vim.api.nvim_win_is_valid(ui_popup.popup_win) and vim.api.nvim_get_current_win() == ui_popup.popup_win)
    if is_popup then
        vim.api.nvim_win_hide(ui_popup.popup_win)
        local new_filename, content = utils.build_workspace_content(ui_popup.popup_buf, M.current_workspace_file)
        M.current_workspace_file = utils.export_to_workspace(content, new_filename)
    else
        local cur_buf = vim.api.nvim_get_current_buf()
        if vim.api.nvim_buf_get_name(cur_buf):match(".mctx$") then
            M.current_workspace_file = vim.api.nvim_buf_get_name(cur_buf)
            utils.load_workspace_state(cur_buf)
            ui_popup.create_popup(cur_buf)
        else
            vim.notify("Você não está em um arquivo de workspace (.mctx).", vim.log.levels.WARN)
        end
    end
end

local original_open_popup = popup.create_popup
popup.create_popup = function(initial_content)
    local b, w = original_open_popup(initial_content)
    M.popup_buf = popup.popup_buf
    M.popup_win = popup.popup_win
    return b, w
end

M.TerminateTurn = function()
    react_loop.reset_turn()
    local p = require('multi_context.ui.popup')
    local buf = p.popup_buf
    if not buf or not vim.api.nvim_buf_is_valid(buf) then return end
    
    local cfg = require('multi_context.config')
    local current_api = cfg.get_current_api()
    local user_prefix = "## " .. (cfg.options.user_name or "Nardi") .. " >>"
    
    local next_prompt_lines = { "", "## API atual: " .. current_api, user_prefix .. " " }
    
    if react_loop.state.queued_tasks and react_loop.state.queued_tasks ~= "" then
        table.insert(next_prompt_lines, "> [Checkpoint] Avalie a resposta acima. Pressione <CR> para continuar a fila:")
        for _, q_line in ipairs(vim.split(react_loop.state.queued_tasks, "\n")) do table.insert(next_prompt_lines, q_line) end
        react_loop.state.queued_tasks = nil
    end
    
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, next_prompt_lines)
    p.create_folds(buf)
    require('multi_context.ui.highlights').apply_chat(buf)
    p.update_title()
    
    if p.popup_win and vim.api.nvim_win_is_valid(p.popup_win) then
        pcall(vim.api.nvim_win_set_cursor, p.popup_win, { vim.api.nvim_buf_line_count(buf), 0 })
        vim.cmd("normal! zz"); vim.cmd("startinsert!")
    end
end

local function get_context_md_content()
    local root = vim.fn.system("git rev-parse --show-toplevel")
    if vim.v.shell_error == 0 then root = root:gsub("\n", "") else root = vim.fn.getcwd() end
    local filepath = root .. "/CONTEXT.md"
    if vim.fn.filereadable(filepath) == 1 then return table.concat(vim.fn.readfile(filepath), "\n") end
    return nil
end

function M.SendFromPopup()
    pcall(function() require('multi_context.skills_manager').load_skills() end)
    if not popup.popup_buf or not api.nvim_buf_is_valid(popup.popup_buf) then return end
    local buf = popup.popup_buf
    local start_idx, _ = utils.find_last_user_line(buf)
    if not start_idx then return end

    local cfg = require('multi_context.config')
    local user_prefix = "## " .. (cfg.options.user_name or "Nardi") .. " >>"
    local lines = api.nvim_buf_get_lines(buf, start_idx, -1, false)
    if lines[1] then lines[1] = lines[1]:gsub("^" .. user_prefix .. "%s*", "") end

    local agents = require('multi_context.agents').load_agents()
    local current_task_lines = {}; local queued_tasks_lines = {}; local found_agent_count = 0

    for _, line in ipairs(lines) do
        if not line:match("^> %[Checkpoint%]") then
            local possible_agent = line:match("@([%w_]+)")
            if possible_agent and agents[possible_agent] then found_agent_count = found_agent_count + 1 end
            if found_agent_count <= 1 then table.insert(current_task_lines, line) else table.insert(queued_tasks_lines, line) end
        end
    end

    local raw_user_text = table.concat(current_task_lines, "\n"):gsub("^%s*", ""):gsub("%s*$", "")
    if #queued_tasks_lines > 0 then react_loop.state.queued_tasks = table.concat(queued_tasks_lines, "\n") end
    if raw_user_text == "" then vim.notify("Digite algo antes de enviar.", vim.log.levels.WARN); return end

    local parsed_intent = prompt_parser.parse_user_input(raw_user_text, agents)
    
    if parsed_intent.agent_name then
        if parsed_intent.agent_name == "reset" then react_loop.state.active_agent = nil
        else react_loop.state.active_agent = parsed_intent.agent_name end
    end
    if parsed_intent.is_autonomous then react_loop.state.is_autonomous = true end

    local text_to_send = parsed_intent.text_to_send
    local active_agent_name = react_loop.state.active_agent

    -- === INJEÇÃO DO WATCHDOG (QUADRIPARTITE) ===
    local mem_tracker = require('multi_context.memory_tracker')
    local current_tokens = utils.estimate_tokens(buf)
    local prompt_tokens = math.floor(#text_to_send / 4)
    local predicted_total = mem_tracker.predict_next_total(current_tokens, prompt_tokens)
    local horizon = (cfg.options.cognitive_horizon or 4000) * (cfg.options.user_tolerance or 1.0)

    if predicted_total > horizon and active_agent_name ~= "archivist" then
        react_loop.state.pending_user_prompt = text_to_send
        react_loop.state.active_agent = "archivist"
        active_agent_name = "archivist"
        text_to_send = "O contexto atingiu o limite crítico. Analise o histórico e comprima o estado usando EXATAMENTE o modelo Quadripartite (<genesis>, <plan>, <journey>, <now>). Responda APENAS com o XML."
        
        local msg = string.format("> [Guardião do Contexto]: Limite iminente (%d > %d). Invocando @archivist...", predicted_total, horizon)
        api.nvim_buf_set_lines(buf, -1, -1, false, { "", msg, "" })
    end
    -- ==========================================

    local sending_msg = "[Enviando requisição" .. (active_agent_name and (" via @" .. active_agent_name) or "") .. "...]"
    api.nvim_buf_set_lines(buf, -1, -1, false, { "", sending_msg })

    local history_lines = api.nvim_buf_get_lines(buf, 0, start_idx, false)
    local messages = require('multi_context.conversation').build_history(history_lines)
    
    local base_sys_prompt = "Você é um Engenheiro de Software Autônomo no Neovim."
    local memory_context = get_context_md_content()
    local system_prompt = prompt_parser.build_system_prompt(base_sys_prompt, memory_context, active_agent_name, agents, current_tokens)
    
    table.insert(messages, 1, { role = "system", content = system_prompt })
    
    if #messages > 1 and messages[#messages].role == "user" then
        messages[#messages].content = messages[#messages].content .. "\n\n" .. text_to_send
    else
        table.insert(messages, { role = "user", content = text_to_send })
    end

    local response_started = false
    local accumulated_text = ""
    local current_ia_start_idx = nil
    
    local function remove_sending_msg()
        local count = api.nvim_buf_line_count(buf)
        local last_line = api.nvim_buf_get_lines(buf, count - 1, count, false)[1]
        if last_line:match("%[Enviando requisi") then api.nvim_buf_set_lines(buf, count - 2, count, false, {}) end
    end

    scroller.start_streaming(buf, popup.popup_win)

    require('multi_context.api_client').execute(messages, 
        function(job_id)
            react_loop.state.active_job_id = job_id
            react_loop.state.user_aborted = false
        end,
        function(chunk, api_entry)
            if not response_started then
                remove_sending_msg()
                local ia_title = "## IA (" .. api_entry.model .. ")" .. (active_agent_name and ("[@" .. active_agent_name .. "]") or "") .. " >> "
                local count_before = api.nvim_buf_line_count(buf)
                api.nvim_buf_set_lines(buf, -1, -1, false, { "", ia_title, "" })
                current_ia_start_idx = count_before + 2
                response_started = true
            end
            if type(chunk) == "string" and chunk ~= "" then
                local lines_to_add = vim.split(chunk, "\n", {plain = true})
                local count = api.nvim_buf_line_count(buf)
                local last_line = api.nvim_buf_get_lines(buf, count - 1, count, false)[1]
                lines_to_add[1] = last_line .. lines_to_add[1]
                api.nvim_buf_set_lines(buf, count - 1, count, false, lines_to_add)
                
                scroller.on_chunk_received(buf, popup.popup_win)
                
                accumulated_text = accumulated_text .. chunk
                if accumulated_text:match("</tool_call>%s*$") then
                    local tags = {}
                    for n in accumulated_text:gmatch('<tool_call[^>]*name="([^"]+)"') do table.insert(tags, n) end
                    local last_name = tags[#tags]
                    if last_name and (last_name == "edit_file" or last_name == "replace_lines" or last_name == "run_shell") then
                        react_loop.abort_stream(false)
                    end
                end
                
                if popup.popup_win and api.nvim_win_is_valid(popup.popup_win) then
                    popup.update_title()
                end
            end
        end,
        function(api_entry, metrics)
            -- FASE 25: Alimenta a memória preditiva com os tokens gerados pela IA
            require('multi_context.memory_tracker').add_turn(math.floor(#accumulated_text / 4))
            scroller.stop_streaming(buf)
            react_loop.state.active_job_id = nil
            
            if react_loop.state.user_aborted then
                api.nvim_buf_set_lines(buf, -1, -1, false, { "", ">[Sistema]: 🛑 Geração interrompida pelo usuário." })
                M.TerminateTurn()
                return
            end
            
            if not response_started then remove_sending_msg() end
            if metrics and (metrics.cache_read_input_tokens or 0) > 0 then
                vim.notify(string.format("⚡ Prompt Caching: %d tokens economizados!", metrics.cache_read_input_tokens), vim.log.levels.INFO)
            end
            
            local b_lines = api.nvim_buf_get_lines(buf, 0, -1, false)
            local has_tool = false
            local scan_start = current_ia_start_idx or 1
            for i = scan_start, #b_lines do
                if b_lines[i]:match("<tool_call") then has_tool = true; break end
            end

            if react_loop.state.pending_user_prompt and react_loop.state.active_agent == "archivist" then
                vim.defer_fn(function() require('multi_context').HandleArchivistCompression(current_ia_start_idx) end, 100)
            elseif has_tool then
                vim.defer_fn(function() require('multi_context').ExecuteTools(current_ia_start_idx) end, 100)
            else
                M.TerminateTurn()
            end
        end,
        function(err_msg)
            scroller.stop_streaming(buf)
            remove_sending_msg()
            api.nvim_buf_set_lines(buf, -1, -1, false, { "", "**[ERRO]** " .. err_msg, "", user_prefix .. " " })
            react_loop.state.is_autonomous = false
        end
    )
end
function M.ExecuteTools(ia_idx)
    local p = require('multi_context.ui.popup')
    local buf = p.popup_buf
    if not buf or not vim.api.nvim_buf_is_valid(buf) then buf = vim.api.nvim_get_current_buf() end

    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local last_ia_idx = ia_idx
    
    if not last_ia_idx then
        last_ia_idx = 0
        for i = #lines, 1, -1 do if lines[i]:match("^## IA %(") then last_ia_idx = i; break end end
        if last_ia_idx == 0 then
            for i = #lines, 1, -1 do if lines[i]:match("^## IA") then last_ia_idx = i; break end end
        end
    end
    if last_ia_idx == 0 then return end

    local prefix_lines = {}; for i = 1, last_ia_idx - 1 do table.insert(prefix_lines, lines[i]) end
    local process_lines = {}; for i = last_ia_idx, #lines do table.insert(process_lines, lines[i]) end
    
    local content_to_process = tool_parser.sanitize_payload(table.concat(process_lines, "\n"))

    local new_content = ""
    local cursor = 1
    local has_changes = false
    local abort_all = false
    local approve_all_ref = { value = false }
    local pending_rewrite_content = nil
    local should_continue_loop = false 

    while cursor <= #content_to_process do
        local parsed_tag = tool_parser.parse_next_tool(content_to_process, cursor)
        
        if not parsed_tag then
            new_content = new_content .. content_to_process:sub(cursor)
            break
        end

        new_content = new_content .. parsed_tag.text_before

        if parsed_tag.is_invalid or not parsed_tag.name or parsed_tag.name == "" then
            new_content = new_content .. parsed_tag.raw_tag .. (parsed_tag.inner or "") .. (parsed_tag.close_start and "</tool_call>" or "")
            cursor = parsed_tag.close_end + 1
            goto continue
        end

        if abort_all then
            new_content = new_content .. parsed_tag.raw_tag .. parsed_tag.inner .. "</tool_call>"
            cursor = parsed_tag.close_end + 1
            goto continue
        end

        has_changes = true

        do
            local tag_output, should_abort, cont_loop, rew_content, backup_made = tool_runner.execute(
                parsed_tag, 
                react_loop.state.is_autonomous, 
                approve_all_ref, 
                buf
            )

            if backup_made then react_loop.state.last_backup = backup_made end
            if rew_content then pending_rewrite_content = rew_content end
            if cont_loop then should_continue_loop = true end

            if should_abort then
                abort_all = true
                new_content = new_content .. parsed_tag.raw_tag .. parsed_tag.inner .. "</tool_call>"
            else
                new_content = new_content .. tag_output
                if tag_output:match(">%[Sistema%]: ERRO %- Ferramenta") then
                    react_loop.state.is_autonomous = false
                    should_continue_loop = false
                end
            end
        end

        ::continue::
        cursor = parsed_tag.close_end + 1
    end

    if not has_changes or abort_all then M.TerminateTurn(); return end

    if pending_rewrite_content then
        local rewrite_lines = vim.split(pending_rewrite_content, "\n", {plain=true})
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, rewrite_lines)
    else
        local final_lines = {}
        for _, l in ipairs(prefix_lines) do table.insert(final_lines, l) end
        for _, l in ipairs(vim.split(new_content, "\n", {plain=true})) do table.insert(final_lines, l) end
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, final_lines)
    end

    if pending_rewrite_content or (not should_continue_loop and not react_loop.state.is_autonomous) then
        M.TerminateTurn(); return
    end

    if react_loop.check_circuit_breaker() then
        M.TerminateTurn(); return
    end

    local cfg = require('multi_context.config')
    local user_prefix = "## " .. (cfg.options.user_name or "Nardi") .. " >>"
    
    local sys_msg = "[Sistema]: Informação coletada. Analise o resultado e continue."
    if not should_continue_loop and react_loop.state.is_autonomous then
        sys_msg = "[Sistema]: Ação executada. Verifique se o passo foi concluído ou prossiga para a próxima ação."
    end

    local b_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    table.insert(b_lines, ""); table.insert(b_lines, user_prefix .. " " .. sys_msg)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, b_lines)
    require('multi_context.ui.highlights').apply_chat(buf)

    vim.defer_fn(function() require('multi_context').SendFromPopup() end, 100)
end

vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
        if _G.MultiContextTempFiles then for _, f in ipairs(_G.MultiContextTempFiles) do pcall(os.remove, f) end end
    end
})

vim.cmd([[
command! -range Context lua require('multi_context').ContextChatHandler(<line1>, <line2>)
command! -nargs=0 ContextUndo lua require('multi_context').ContextUndo()
command! -nargs=0 ContextFolder lua require('multi_context').ContextChatFolder()
command! -nargs=0 ContextRepo lua require('multi_context').ContextChatRepo()
command! -nargs=0 ContextGit lua require('multi_context').ContextChatGit()
command! -nargs=0 ContextApis lua require('multi_context').ContextApis()
command! -nargs=0 ContextTree lua require('multi_context').ContextTree()
command! -nargs=0 ContextBuffers lua require('multi_context').ContextBuffers()
command! -nargs=0 ContextToggle lua require('multi_context').TogglePopup()
command! -nargs=0 ContextReloadSkills lua require('multi_context.skills_manager').load_skills(); vim.notify('Skills customizadas recarregadas!', vim.log.levels.INFO)
]])

M.HandleArchivistCompression = function(ia_idx)
    local p = require('multi_context.ui.popup')
    local buf = p.popup_buf
    if not buf or not vim.api.nvim_buf_is_valid(buf) then return end
    
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local content = table.concat(lines, "\n")
    
    local genesis = content:match("<genesis>(.-)</genesis>") or "N/A"
    local plan = content:match("<plan>(.-)</plan>") or "N/A"
    local journey = content:match("<journey>(.-)</journey>") or "N/A"
    local now = content:match("<now>(.-)</now>") or "N/A"
    
    local backup_file = vim.fn.stdpath("data") .. "/mctx_pre_compression_" .. os.date("%Y%m%d_%H%M%S") .. ".mctx"
    vim.fn.writefile(lines, backup_file)
    
    local cfg = require('multi_context.config')
    local user_prefix = "## " .. (cfg.options.user_name or "Nardi") .. " >>"
    
    local new_lines = { "=== MEMÓRIA CONSOLIDADA (QUADRIPARTITE) ===" }
    
    local function append_split(txt)
        if not txt then return end
        for _, l in ipairs(vim.split(txt, "\n", {plain=true})) do table.insert(new_lines, l) end
    end
    
    append_split("<genesis>\n" .. vim.trim(genesis) .. "\n</genesis>\n")
    append_split("<plan>\n" .. vim.trim(plan) .. "\n</plan>\n")
    append_split("<journey>\n" .. vim.trim(journey) .. "\n</journey>\n")
    append_split("<now>\n" .. vim.trim(now) .. "\n</now>\n")
    
    append_split(user_prefix .. " " .. (react_loop.state.pending_user_prompt or ""))
    
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, new_lines)
    
    require('multi_context.memory_tracker').reset()
    react_loop.state.pending_user_prompt = nil
    react_loop.state.active_agent = nil
    
    require('multi_context.ui.highlights').apply_chat(buf)
    p.create_folds(buf)
    p.update_title()
    
    vim.notify("🧠 Contexto hiper-comprimido pelo @archivist. Retomando tarefa...", vim.log.levels.INFO)
    vim.defer_fn(function() require('multi_context').SendFromPopup() end, 100)
end

M.HandleArchivistCompression = function(ia_idx)
    local p = require('multi_context.ui.popup')
    local buf = p.popup_buf
    if not buf or not vim.api.nvim_buf_is_valid(buf) then return end
    
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local content = table.concat(lines, "\n")
    
    local genesis = content:match("<genesis>(.-)</genesis>") or "N/A"
    local plan = content:match("<plan>(.-)</plan>") or "N/A"
    local journey = content:match("<journey>(.-)</journey>") or "N/A"
    local now = content:match("<now>(.-)</now>") or "N/A"
    
    local backup_file = vim.fn.stdpath("data") .. "/mctx_pre_compression_" .. os.date("%Y%m%d_%H%M%S") .. ".mctx"
    vim.fn.writefile(lines, backup_file)
    
    local cfg = require('multi_context.config')
    local user_prefix = "## " .. (cfg.options.user_name or "Nardi") .. " >>"
    
    local new_lines = { "=== MEMÓRIA CONSOLIDADA (QUADRIPARTITE) ===" }
    
    local function append_split(txt)
        if not txt then return end
        for _, l in ipairs(vim.split(txt, "\n", {plain=true})) do table.insert(new_lines, l) end
    end
    
    append_split("<genesis>\n" .. vim.trim(genesis) .. "\n</genesis>\n")
    append_split("<plan>\n" .. vim.trim(plan) .. "\n</plan>\n")
    append_split("<journey>\n" .. vim.trim(journey) .. "\n</journey>\n")
    append_split("<now>\n" .. vim.trim(now) .. "\n</now>\n")
    
    append_split(user_prefix .. " " .. (react_loop.state.pending_user_prompt or ""))
    
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, new_lines)
    
    require('multi_context.memory_tracker').reset()
    react_loop.state.pending_user_prompt = nil
    react_loop.state.active_agent = nil
    
    require('multi_context.ui.highlights').apply_chat(buf)
    p.create_folds(buf)
    p.update_title()
    
    vim.notify("🧠 Contexto hiper-comprimido pelo @archivist. Retomando tarefa...", vim.log.levels.INFO)
    vim.defer_fn(function() require('multi_context').SendFromPopup() end, 100)
end

return M




======== ./lua/multi_context/tools.lua ========
-- lua/multi_context/tools.lua
local M = {}

local function get_repo_root()
    vim.fn.system("git rev-parse --show-toplevel")
    if vim.v.shell_error ~= 0 then return nil end
    return vim.fn.system("git rev-parse --show-toplevel"):gsub("\n", "")
end

local function resolve_path(path)
    if not path or path == "" then return nil end
    path = vim.trim(path)
    if path:sub(1, 1) == "/" then return path end
    local root = get_repo_root() or vim.fn.getcwd()
    return root .. "/" .. path
end

M.list_files = function()
    local root = get_repo_root()
    if not root then return "ERRO: Fora de um repositório Git." end
    local files = vim.fn.system("git -C " .. vim.fn.shellescape(root) .. " ls-files")
    return "Arquivos rastreados pelo Git:\n" .. files
end

M.read_file = function(path)
    local full_path = resolve_path(path)
    if not full_path then return "ERRO: Atributo 'path' obrigatório." end
    if vim.fn.filereadable(full_path) == 0 then return "ERRO: Arquivo não encontrado (" .. full_path .. ")" end
    
    local lines = vim.fn.readfile(full_path)
    local numbered_lines = {}
    for i, line in ipairs(lines) do
        table.insert(numbered_lines, string.format("%d | %s", i, line))
    end
    
    return table.concat(numbered_lines, "\n")
end

M.edit_file = function(path, content)
    local full_path = resolve_path(path)
    if not full_path then return "ERRO: O atributo 'path' é obrigatório." end
    
    local dir = vim.fn.fnamemodify(full_path, ":h")
    if vim.fn.isdirectory(dir) == 0 then vim.fn.mkdir(dir, "p") end

    -- Blindagem: Limpa lixo de formatação da IA
    content = content:gsub("\r", "")
    content = content:gsub("^%s*```[%w_]*\n", ""):gsub("\n%s*```%s*$", "")
    
    local lines = vim.split(content, "\n", {plain=true})
    local bufnr = vim.fn.bufnr(full_path)
    
    if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
        vim.api.nvim_buf_call(bufnr, function() vim.cmd("silent! write") end)
    else
        if vim.fn.writefile(lines, full_path) == -1 then
            return "ERRO: Falha de permissão ao salvar " .. full_path
        end
    end
    vim.notify("✅ Arquivo criado/salvo: " .. full_path, vim.log.levels.INFO)
    return "SUCESSO: Arquivo " .. full_path .. " foi sobrescrito/criado."
end

M.run_shell = function(cmd)
    if not cmd or cmd == "" then return "ERRO: Comando não fornecido." end
    local root = get_repo_root() or vim.fn.getcwd()
    cmd = vim.trim(cmd)
    local bash_script = string.format("cd %s && %s", vim.fn.shellescape(root), cmd)
    local out = vim.fn.system({'bash', '-c', bash_script})
    local status = vim.v.shell_error ~= 0 and ("FALHA (Código " .. vim.v.shell_error .. ")") or "SUCESSO"
    return string.format("Comando:\n%s\n\nStatus: %s\nSaída:\n%s", cmd, status, out)
end

M.search_code = function(query)
    local root = get_repo_root()
    if not root then return "ERRO: Fora de repositório Git." end
    if not query or query == "" then return "ERRO: 'query' obrigatória." end
    local cmd = string.format("git -C %s grep -n -i -I %s", vim.fn.shellescape(root), vim.fn.shellescape(query))
    local out = vim.fn.system(cmd)
    if vim.v.shell_error ~= 0 or out == "" then return "Nenhum resultado para: " .. query end
    if #out > 3000 then out = out:sub(1, 3000) .. "\n\n... [AVISO: TRUNCADO] ..." end
    return "Resultados da busca:\n" .. out
end

M.replace_lines = function(path, start_line, end_line, content)
    local full_path = resolve_path(path)
    if not full_path then return "ERRO: 'path' obrigatório." end
    start_line, end_line = tonumber(start_line), tonumber(end_line)
    if not start_line or not end_line then return "ERRO: 'start' e 'end' devem ser números." end
    
    local bufnr = vim.fn.bufnr(full_path)
    local lines = {}
    if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
        lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    else
        if vim.fn.filereadable(full_path) == 0 then return "ERRO: Arquivo não encontrado." end
        lines = vim.fn.readfile(full_path)
    end
    
    if start_line < 1 then start_line = 1 end
    if end_line > #lines then end_line = #lines end
    
    content = content:gsub("\r", "")
    content = content:gsub("^%s*```[%w_]*\n", ""):gsub("\n%s*```%s*$", "")
    local new_lines = content == "" and {} or vim.split(content, "\n", {plain=true})
    
    local final_lines = {}
    for i = 1, start_line - 1 do table.insert(final_lines, lines[i]) end
    for _, l in ipairs(new_lines) do table.insert(final_lines, l) end
    for i = end_line + 1, #lines do table.insert(final_lines, lines[i]) end
    
    if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, final_lines)
        vim.api.nvim_buf_call(bufnr, function() vim.cmd("silent! write") end)
    else
        vim.fn.writefile(final_lines, full_path)
    end
    vim.notify("✅ Edição aplicada: " .. full_path, vim.log.levels.INFO)
    return "SUCESSO: Edição nas linhas " .. start_line .. " a " .. end_line
end

M.get_diagnostics = function(path)
    -- 1. Exige explicitamente o caminho do arquivo
    if not path or path == "" or path == "nil" then
        return "ERRO: O atributo 'path' é OBRIGATÓRIO. Ex: <tool_call name=\"get_diagnostics\" path=\"caminho/do/arquivo.lua\"></tool_call>"
    end

    -- 2. Resolve o caminho e carrega o buffer
    path = vim.trim(path)
    local full_path = resolve_path(path)
    if not full_path then return "ERRO: 'path' inválido." end
    
    local bufnr = vim.fn.bufnr(full_path)
    if bufnr == -1 then
        if vim.fn.filereadable(full_path) == 0 then
            return "ERRO: Arquivo não encontrado: " .. full_path
        end
        bufnr = vim.fn.bufadd(full_path)
        if bufnr == 0 then return "ERRO: Não foi possível carregar o arquivo: " .. full_path end
        vim.fn.bufload(bufnr)
    end

    -- 3. Verifica presença de LSP ativo
    local has_lsp = vim.lsp.buf_is_attached and vim.lsp.buf_is_attached(bufnr)
    if not has_lsp then
        local clients = vim.lsp.get_clients and vim.lsp.get_clients({bufnr = bufnr}) or {}
        has_lsp = #clients > 0
    end

    if has_lsp then
        -- Aguarda o LSP recalcular diagnósticos (até 2s)
        vim.wait(2000, function() return false end, 50)
        vim.wait(300)
    end

    -- 4. Coleta diagnósticos
    local diagnostics = vim.diagnostic.get(bufnr)
    if not diagnostics or #diagnostics == 0 then
        if not has_lsp then
            return "AVISO: Nenhum servidor LSP ativo detectado para: " .. full_path
        end
        return "✅ Nenhum diagnóstico ou erro encontrado em: " .. full_path
    end

    -- 5. Formata e Trunca a resposta para proteger a janela de contexto
    local MAX_DIAGS = 50
    local MAX_BYTES = 3000
    local severity_names = { [1] = "ERROR", [2] = "WARN", [3] = "INFO", [4] = "HINT" }
    local out_lines = {}
    local count = math.min(#diagnostics, MAX_DIAGS)

    for i = 1, count do
        local d = diagnostics[i]
        local sev = severity_names[d.severity] or "?"
        local msg = d.message or ""
        local lnum = (d.lnum or 0) + 1
        local col = (d.col or 0) + 1
        local source = d.source or ""
        table.insert(out_lines, string.format("L%d:C%d [%s] %s%s", lnum, col, sev, msg, source ~= "" and (" ("..source..")") or ""))
    end

    local result = "Diagnósticos para " .. full_path .. ":\n" .. table.concat(out_lines, "\n")

    if #result > MAX_BYTES then
        result = result:sub(1, MAX_BYTES) .. "\n\n[AVISO: TRUNCADO - " .. #diagnostics .. " diagnósticos no total, exibindo " .. count .. "]"
    elseif #diagnostics > MAX_DIAGS then
        result = result .. "\n\n[AVISO: " .. #diagnostics .. " diagnósticos no total, exibindo os primeiros " .. MAX_DIAGS .. "]"
    end

    return result
end


M.apply_diff = function(path, diff_content)
    local full_path = resolve_path(path)
    if not full_path then return "ERRO: 'path' obrigatório." end
    
    local bufnr = vim.fn.bufnr(full_path)
    local lines = {}
    
    -- Antes de aplicar o diff em disco, garantimos que o disco está atualizado com o buffer vivo
    if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
        lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        vim.fn.writefile(lines, full_path)
    else
        if vim.fn.filereadable(full_path) == 0 then return "ERRO: Arquivo não encontrado." end
    end
    
    -- Limpa sujeira comum que as LLMs adicionam ao redor do diff
    diff_content = diff_content:gsub("\r", "")
    diff_content = diff_content:gsub("^%s*```[%w_]*\n", ""):gsub("\n%s*```%s*$", "")
    
    local tmp_patch = os.tmpname()
    vim.fn.writefile(vim.split(diff_content, "\n", {plain=true}), tmp_patch)
    
    -- Chama o binário UNIX `patch`. A flag --force impede que o binário fique pendurado esperando input no terminal se falhar.
    local cmd = string.format("patch --force -u %s -i %s", vim.fn.shellescape(full_path), vim.fn.shellescape(tmp_patch))
    local out = vim.fn.system(cmd)
    local status = vim.v.shell_error
    
    -- Limpa os rastros
    os.remove(tmp_patch)
    os.remove(full_path .. ".orig")
    os.remove(full_path .. ".rej")
    
    if status ~= 0 then
        return "FALHA ao aplicar diff (Código " .. status .. "):\n" .. out
    end
    
    -- Se o buffer estava aberto no vim, fazemos o recarregamento (hot-reload) do arquivo modificado
    if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
        local new_lines = vim.fn.readfile(full_path)
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)
        vim.api.nvim_buf_call(bufnr, function() vim.cmd("silent! write") end)
    end
    
    vim.notify("✅ Diff aplicado: " .. full_path, vim.log.levels.INFO)
    return "SUCESSO: Diff aplicado no arquivo " .. full_path
end

return M




======== ./lua/multi_context/conversation.lua ========
local M = {}
local api = vim.api

-- Regex hiper tolerantes para não quebrar em exports .mctx formatados de forma estranha
local user_pat = "^##%s*([%w_]+)%s*>>"
local ia_pat   = "^##%s*IA.*>>"

M.find_last_user_line = function(buf)
    local lines = api.nvim_buf_get_lines(buf, 0, -1, false)
    for i = #lines, 1, -1 do
        if lines[i]:match(user_pat) then return i - 1, lines[i] end
    end
    return nil
end

M.build_history = function(buf_or_lines)
    local lines = type(buf_or_lines) == "table" and buf_or_lines or api.nvim_buf_get_lines(buf_or_lines, 0, -1, false)
    local messages = {}; local role = nil; local acc = {}
    local orphaned_text = {} -- NOVO: Guarda o texto injetado pelos comandos :Context

    local function flush()
        if role and #acc > 0 then
            local text = table.concat(acc, "\n"):match("^%s*(.-)%s*$")
            if text ~= "" then 
                -- MÁGICA 1: Se houver texto injetado no topo (ex: git diff), mescla na 1ª msg do usuário
                if role == "user" and #orphaned_text > 0 then
                    text = table.concat(orphaned_text, "\n") .. "\n\n" .. text
                    orphaned_text = {}
                end
                
                -- MÁGICA 2: Previne 2 mensagens seguidas com mesmo papel (evita crash na Anthropic)
                if #messages > 0 and messages[#messages].role == role then
                    messages[#messages].content = messages[#messages].content .. "\n\n" .. text
                else
                    table.insert(messages, { role = role, content = text })
                end
            end
        end
        acc = {}
    end

    for _, line in ipairs(lines) do
        if line:match(user_pat) then
            flush(); role = "user"
            local body = line:gsub(user_pat .. "%s*", "")
            if body ~= "" then table.insert(acc, body) end
        elseif line:match(ia_pat) then
            flush(); role = "assistant"
        elseif not line:match("^## API atual:") then
            if role then 
                table.insert(acc, line) 
            else
                -- Coleta texto antes da primeira tag (o contexto injetado pelos comandos :Context*)
                if line:match("%S") then table.insert(orphaned_text, line) end
            end
        end
    end
    flush()
    
    -- Fallback: Se sobrou texto órfão e não havia NENHUMA tag anterior no histórico
    if #orphaned_text > 0 then
        local text = table.concat(orphaned_text, "\n"):match("^%s*(.-)%s*$")
        if text ~= "" then
            table.insert(messages, { role = "user", content = text })
        end
    end
    
    return messages
end
return M


# E abaixo está o conteúdo do plano de implementação delineado em outro chat. Perceba que já fizemos algumas coisas. Você vai dar continuidade ao plano seguindo à risca as especificações.

Excelente adição! Você tocou num ponto avançado de *Prompt Engineering* e governança de custos. Existem projetos onde a semântica é vital e a IA precisa de liberdade; e projetos enormes onde o limite estrito (hard-cap) é a única forma de evitar o estouro de limite de tokens e de faturamento.

Aqui está o plano atualizado, incorporando os **3 Motores de Compressão**, sua mecânica de injeção e como isso reflete no nosso painel de controle interativo.

---

## 🏛️ ESPECIFICAÇÃO DE DESIGN: FASE 25 (Governança e Controles)

### 1. Motores de Compressão (A Regra de Ouro do Arquivista)
O sistema terá três algoritmos de compressão, definidos na configuração e refletidos dinamicamente no prompt do `@archivist`.

*   **Motor 1: Compressão Semântica (Default)**
    *   *Mecânica:* O sistema dita a estrutura (Quadripartite), mas deixa o tamanho livre.
    *   *Injeção no Prompt:* "Gere o XML. O tamanho final é determinado pela complexidade do histórico. Priorize a integridade da informação."
*   **Motor 2: Compressão Percentual**
    *   *Mecânica:* O sistema lê o tamanho do chat atual no momento da interceptação, calcula a porcentagem e passa para a IA. (ex: Chat atual 5000 tokens, Config de 30%).
    *   *Injeção no Prompt:* "MANDATÓRIO: Sintetize pesadamente. Seu output estruturado não deve ultrapassar o teto aproximado de **1500 tokens**."
*   **Motor 3: Compressão por Target Size (Fixo)**
    *   *Mecânica:* Um valor absoluto configurado pelo usuário.
    *   *Injeção no Prompt:* "MANDATÓRIO: A compressão é agressiva. Sob nenhuma circunstância o seu output estruturado pode ultrapassar **[X] tokens**."

### 2. O Painel de Controle: `:ContextControls` (Atualizado)

A Seção 3 será expandida para suportar não apenas os Modos do Watchdog, mas também o Motor de Compressão, exibindo ou ocultando parâmetros dinamicamente com base na estratégia escolhida.

**UI Expandida (Visão do Usuário):**
```text
=== ⚙️ MULTICONTEXT CONTROLS ===
(Use j/k para navegar, <Space> para alternar, <CR> expandir, c editar, :w salvar)

▶ [1] PROVEDORES DE REDE E APIS
▶ [2] ORQUESTRAÇÃO DE SWARM (MOA) E FALLBACKS
▼ [3] GUARDIÃO DE CONTEXTO (WATCHDOG)
      Status da Interceptação: [ Ask ]  (Off | Ask | Auto)
      Gatilho (Limiar):        4000 tokens
      Tolerância:              1.0

      --- Motor de Compressão (@archivist) ---
      Estratégia:              [ Percentual ]  (Semântico | Percentual | Fixo)
      Alvo Percentual:         30% do chat atual
▶ [4] STATUS DO SISTEMA E SKILLS
```
*(Nota de UX: Se o usuário apertar `<Space>` em Estratégia e mudar para "Fixo", a linha de baixo muda instantaneamente para `Alvo (Fixo): 1000 tokens`)*

### 3. O Motor do Guardião 2.0 (Resiliência Consolidada)
*   **Imunidade do Primeiro Turno:** O Watchdog aborta se for a primeira mensagem (`count < 2`). O Arquivista só trabalha com passado.
*   **Matemática Real:** `tokens_buffer_atual + EMA`. O texto pendente do prompt do usuário NÃO será somado duas vezes.
*   **Telemetria UI:** Título atualizado dinamicamente: ` Multi_Context_Chat | ~3500 tokens | WD: Ask `.

---

### 🗺️ PLANO DE IMPLEMENTAÇÃO TDD (Fase 25 - Atualizado)

*   **Passo 1: Fundações, Configs e Desacoplamento**
    *   *Meta:* Consertar o `memory_tracker` e adicionar os novos campos de configuração (Modos do Watchdog e os 3 Motores de Compressão).
    *   *TDD:* Testaremos se a configuração padrão (`Off`, `Semântico`) é carregada. Testaremos se o preditor matemático ignora o prompt e se a Imunidade de Primeiro Turno devolve bloqueio (`false`) caso o chat tenha acabado de começar.
*   **Passo 2: O System Agent (`@archivist`) e Engenharia de Prompt Dinâmica**
    *   *Meta:* Interceptar a busca de agente e gerar o Prompt do Arquivista. Plugar a matemática para que, caso a estratégia seja "Percentual", ele calcule o valor na hora de enviar.
    *   *TDD:* Simular a invocação do Arquivista usando o motor "Percentual" num chat com 10.000 tokens (mock). O teste afirmará que a string "MANDATÓRIO: [...] 3000 tokens" foi forjada dentro do *system prompt*.
*   **Passo 3: A Engine Virtual do `:ContextControls`**
    *   *Meta:* Criar o `context_controls.lua`. Fazer o renderizador de Árvore e a sintaxe visual (expansão/retração). Aqui excluiremos os antigos e isolados `queue_editor` e `api_selector`.
    *   *TDD:* Validar a lógica de Estado x UI. Garantir que expandir uma seção retorna a quantidade exata de linhas.
*   **Passo 4: Interatividade e Mutação de Estado**
    *   *Meta:* Plugar as keybinds (`<Space>`, `c`, `dd/p`) e amarrar com a persistência (`config.save_api_config`). Garantir que a UI oculta/mostra o campo "Alvo" baseada na "Estratégia".
    *   *TDD:* Simular eventos de teclado. Mudar a estratégia para "Fixo" apertando barra de espaço e verificar se a linha seguinte na UI refletiu o texto correto, e se `:w` salvou corretamente no JSON.

---

O escopo da Fase 25 está totalmente fechado, integrando resiliência técnica, governança de custos (compressão) e uma experiência de usuário (Painel) de primeiro nível.

Com seu **"De acordo"**, te envio agora o Script nº 1 contendo os testes do **Passo 1**!

Perceba que já demos alguns passos. 
