
--------------------- ./log_tests.txt : ---------------------
======================================================================
📊 RESUMO GLOBAL AGREGADO (MULTI-CONTEXT)
======================================================================
✅ Success: 273
❌ Failed : 2
💥 Errors : 0
======================================================================

======================================================================
🔍 RELATÓRIO DE FALHAS (ISOLADO)
======================================================================
Fail    ||      Fixes TDD - Bugs Críticos e Performance (1.1, 1.3, 2.1, 2.2): 1.1: Transport - Deve fechar o canal de stdin do curl apenas UMA vez
            ...context_plugin/lua/multi_context/tests/libuv_barrier.lua:116: ...ontext_plugin/lua/multi_context/tests/tdd_fixes_spec.lua:29: chansend foi chamado mais de uma vez (Duplicação)
            Expected objects to be the same.
            Passed in:
            (number) 0
            Expected:
            (number) 1

            stack traceback:
                ...context_plugin/lua/multi_context/tests/libuv_barrier.lua:116: in function <...context_plugin/lua/multi_context/tests/libuv_barrier.lua:81>

Success ||      Fixes TDD - Bugs Críticos e Performance (1.1, 1.3, 2.1, 2.2): 1.3: Swarm - Nao deve dar starvation no worker se a API falhar silenciosamente (Throw Error)
Success ||      Fixes TDD - Bugs Críticos e Performance (1.1, 1.3, 2.1, 2.2): 2.1: Native Tools - run_shell e apply_diff DEVEM rodar de forma Assíncrona (Evitar UI Freeze)
--
Fail    ||      MultiContext V2.4 - Security & Regression Tests Bug 8: CURL Pipe via STDIN e remoção de Tmp Leak
            ...context_plugin/lua/multi_context/tests/libuv_barrier.lua:116: ...ntext_plugin/lua/multi_context/tests/regression_spec.lua:47: Expected to be truthy, but value was:
            (nil)

            stack traceback:
                ...context_plugin/lua/multi_context/tests/libuv_barrier.lua:116: in function <...context_plugin/lua/multi_context/tests/libuv_barrier.lua:81>

Success ||      MultiContext V2.4 - Security & Regression Tests Bug do Architect: O Gatekeeper MCP deve resolver Skills Semanticas nativamente
Success ||      MultiContext V2.4 - Security & Regression Tests Bug do Loop Infinito: O Motor ReAct deve abortar autonomia (--auto) se receber erro do Gatekeeper
Success ||      MultiContext V2.4 - Security & Regression Tests Bug do Payload Sujo: Swarm Manager deve extrair JSON embutido em texto
Success ||      MultiContext V2.4 - Security & Regression Tests Fase 46 - Integridade Arquitetural: Resultados de Tools devem ser envelopados em <block>

Success:        7
======================================================================
❌ ALERTA: Há testes falhando no sistema. Veja os detalhes acima.
make: *** [Makefile:17: test_agregate_results] Fehler 1

--------------------- ./lua/multi_context/commands.lua : ---------------------
local M = {}

local function open_with(content)
    local buf, win = require('multi_context.ui.chat_view').create_popup(content)
    if buf and win then vim.cmd("startinsert!") end
end

M.ContextChatHandler = function(line1, line2)
    local ctx = require('multi_context.utils.context_builders')
    if line1 and line2 and tonumber(line1) ~= tonumber(line2) then
        open_with(ctx.get_visual_selection(line1, line2))
        return
    end
    
    local mode = vim.api.nvim_get_mode().mode
    if mode == 'v' or mode == 'V' then
        open_with(ctx.get_visual_selection())
    else
        -- Modo normal: abre o chat completamente limpo
        open_with("")
    end
end

M.ContextChatFull = function() open_with("") end

M.ContextChatFolder = function()
    open_with(require('multi_context.utils.context_builders').get_folder_context())
end

M.ContextTree = function()
    open_with(require('multi_context.utils.context_builders').get_tree_context())
end

M.ContextChatRepo = function()
    open_with(require('multi_context.utils.context_builders').get_repo_context())
end

M.ContextChatGit = function()
    open_with(require('multi_context.utils.context_builders').get_git_diff())
end

M.ContextControls = function()
    require('multi_context.ui.controls_view').open_panel()
end

M.ContextBuffers  = function()
    open_with(require('multi_context.utils.context_builders').get_all_buffers_content())
end

M.TogglePopup = function()
    local popup = require('multi_context.ui.chat_view')

    if popup.popup_win and vim.api.nvim_win_is_valid(popup.popup_win) then
        vim.api.nvim_win_hide(popup.popup_win)
        vim.cmd("stopinsert")
        return
    end

    if popup.popup_buf and vim.api.nvim_buf_is_valid(popup.popup_buf) then
        open_with(popup.popup_buf)
    else
        open_with("")
    end
end

return M
--------------------- ./lua/multi_context/i18n.lua : ---------------------
local config = require('multi_context.config')
local M = {}

M.dict = {
    en = {
        tool_not_found = "Tool '%s' does not exist.",
        op_denied = "Operation denied. Agent @%s does not have the Skill '%s'.",
        danger_cmd = "🛡️ DANGEROUS command detected.",
        allow_danger = "Allow DANGEROUS execution: ",
        allow_rewrite = "Agent requested to DESTROY AND COMPRESS the chat. Allow?",
        allow_tool = "Agent requested[%s]. Allow?",
        confirm_opts = "&Yes\n&No\n&All\n&Cancel",
        denied_user = "Access DENIED by user.",
        skill_err = "SKILL EXECUTION ERROR: ",
        buf_rewritten = "Buffer rewritten.",
        swarm_started = "SWARM STARTED. Work delegated to sub-agents running in background.",
        swarm_err_json = "ERROR: Invalid JSON payload for spawn_swarm.",
        err_git_destructive = "Access DENIED. Remote or destructive Git commands (push, reset, rebase) are strictly blocked for safety.",
        err_not_git = "ERROR: Not a Git repository.",
        git_tracked_files = "Files tracked by Git:\n",
        err_path_req = "ERROR: 'path' attribute is required.",
        err_file_not_found = "ERROR: File not found (%s)",
        err_perm_save = "ERROR: Permission denied when saving %s",
        file_saved = "✅ File created/saved: %s",
        succ_file_saved = "SUCCESS: File %s was overwritten/created.",
        err_cmd_req = "ERROR: Command not provided.",
        fail_code = "FAILURE (Code %s)",
        success = "SUCCESS",
        shell_output = "Command:\n%s\n\nStatus: %s\nOutput:\n%s",
        err_query_req = "ERROR: 'query' is required.",
        no_results = "No results for: %s",
        warn_truncated = "...[WARNING: TRUNCATED] ...",
        search_results = "Search results:\n",
        err_lines_num = "ERROR: 'start' and 'end' must be numbers.",
        err_file_not_found_simple = "ERROR: File not found.",
        edit_applied = "✅ Edit applied: %s",
        succ_edit_lines = "SUCCESS: Edited lines %s to %s",
        err_path_req_diag = "ERROR: 'path' is REQUIRED. Ex: <tool_call name=\"get_diagnostics\" path=\"file.lua\"></tool_call>",
        err_path_invalid = "ERROR: Invalid 'path'.",
        err_load_file = "ERROR: Could not load file: %s",
        warn_no_lsp = "WARNING: No active LSP server detected for: %s",
        diag_clean = "✅ No diagnostics or errors found in: %s",
        diag_for = "Diagnostics for %s:\n",
        diag_trunc_1 = "\n\n[WARNING: TRUNCATED - %s total diagnostics, showing %s]",
        diag_trunc_2 = "\n\n[WARNING: %s total diagnostics, showing first %s]",
        fail_diff = "FAILURE applying diff (Code %s):\n%s",
        diff_applied = "✅ Diff applied: %s",
        succ_diff = "SUCCESS: Diff applied to file %s",
        err_git_status = "ERROR getting git status:\n%s",
        git_status_clean = "Working tree is clean.",
        git_status_header = "=== GIT STATUS ===\n",
        err_branch_req = "ERROR: Branch name required.",
        fail_branch = "FAILURE changing branch:\n%s",
        succ_branch = "SUCCESS: %s",
        err_files_req = "ERROR: File list required.",
        err_msg_req = "ERROR: Commit message required.",
        err_git_add_all = "ERROR: Using 'git add .' or '*' is forbidden. You MUST be surgical and specify exact file names separated by commas.",
        err_no_valid_files = "ERROR: No valid files provided.",
        err_git_add = "ERROR in git add:\n%s",
        err_git_commit = "ERROR in git commit:\n%s",
        succ_commit = "SUCCESS: Files committed.\n%s",
        chat_title = " Multi_Context_Chat | ~%d tokens ",
        hidden_lines = "    ↳ ⋯ [%d hidden lines] ⋯  %s",
        swarm_worker_title = "=== SWARM WORKER ===",
        agent_label = "Agent: @",
        api_label = "API: ",
        unknown = "Unknown",
        chat_restored = "✅ Chat successfully restored from the last backup!",
        no_backup = "No compression backup found in this session.",
        not_workspace = "You are not in a workspace file (.mctx).",
        checkpoint = "> [Checkpoint] Evaluate the response above. Press <CR> to continue the queue:",
        type_something = "Type something before sending.",
        archivist_sys_prompt = "The context reached a critical limit. Analyze the history and compress the state using EXACTLY the Quadripartite model (<genesis>, <plan>, <journey>, <now>). Reply ONLY with the XML.",
        guard_limit = "> [Context Watchdog]: Imminent limit (%d > %d). Invoking @archivist...",
        sending_req = "[Sending request%s...]",
        sending_via = " via @%s",
        gen_aborted = ">[System]: 🛑 Generation aborted by the user.",
        prompt_caching = "⚡ Prompt Caching: %d tokens saved!",
        sys_info_collected = "[System]: Information collected. Analyze the result and continue.",
        sys_action_executed = "[System]: Action executed. Check if the step is complete or proceed to the next action.",
        quad_memory = "=== CONSOLIDATED MEMORY (QUADRIPARTITE) ===",
        archivist_compressed = "🧠 Context hyper-compressed by @archivist. Resuming task...",

        sys_lang_directive = "\n\n=== LANGUAGE DIRECTIVE ===\nALWAYS respond to the user and add comments in the code in Brazilian Portuguese (pt-BR).",
        cc_apis_title = "[1] NETWORK PROVIDERS AND APIS",
        cc_apis_desc = "(Manage keys, AI models, and fallback)",
        cc_swarm_title = "[2] SWARM ORCHESTRATION (MOA)",
        cc_swarm_desc = "(Determine which APIs can act as autonomous sub-agents)",
        cc_watchdog_title = "[3] CONTEXT WATCHDOG",
        cc_watchdog_desc = "(Compression rules and AI memory window limits)",
        cc_limits_title = "[4] GLOBAL BEHAVIOR AND LIMITS",
        cc_limits_desc = "(User identity and ReAct loop limits)",
        cc_gatekeeper_title = "[5] AGENTS AND PERMISSIONS",
        cc_gatekeeper_desc = "(Fine-grained control of agent capabilities)",
        cc_semantic_skills_title = "[6] SEMANTIC SKILLS",
        cc_semantic_skills_desc = "(Agent behaviors grouping multiple system tools)",
        cc_system_tools_title = "[7] SYSTEM TOOLS (MCP)",
        cc_system_tools_desc = "(Raw binary tools and scripts available in the system)",
        cc_edit_skill_purpose = "      ├─ [ Edit Skill Guardrails ]",
        cc_delete_skill = "      └─ [ Delete Skill ]",
        cc_create_semantic_skill = "    └─ [ + Create New Semantic Skill ]",
        cc_create_semantic_skill_pmpt = "New Semantic Skill name: ",
        cc_semantic_skill_created = "Semantic Skill '%s' created!",
        cc_system_tools_hint = "    (Press 'e' on a tool to edit its code)",
        cc_create_tool = "    └─ [ + Create New System Tool ]",
        cc_delete_skill_prompt = "Do you want to DELETE skill '%s'?",
        cc_skills_title = "[6] LOCAL SKILLS ECOSYSTEM",
        cc_skills_desc = "(Native or user-created custom skills)",
        cc_injectors_title = "[7] CONTEXT MACROS (INJECTORS)",
        cc_injectors_desc = "(Dynamic shortcuts invoked by '\\')",
        cc_squads_title = "[8] META-AGENT SQUADS",
        cc_squads_desc = "(Pre-configured AI groups with pipelines)",
        cc_app_title = "[9] UI APPEARANCE AND STYLING",
        cc_app_desc = "(Control chat width, height, and borders)",
        cc_history_title = "[10] HISTORY AND WORKSPACES",
        cc_history_desc = "(Restore previous conversations saved in the project)",
        cc_vault_title = "[11] VAULT AND MASTER DIRECTIVE",
        cc_vault_desc = "(Manage API keys and the Base System Prompt)",
        cc_telemetry_title = "[12] TELEMETRY AND DEBUG MODE",
        cc_telemetry_desc = "(Network logs and advanced diagnostics)",
        cc_bg_pool_title = "Background Pool",
        cc_bg_pool_title = "Background Pool",
        cc_fallback_motor = "    Automatic Fallback Motor",
        cc_providers_list = "    Providers List:",
        cc_swarm_perm = "    (Permission to invoke sub-agents and usage priority)",
        cc_wd_status = "    Interception Status",
        cc_wd_trigger = "    Trigger (Threshold)",
        cc_wd_tolerance = "    User Tolerance",
        cc_wd_strategy = "    Strategy",
        cc_wd_percent = "    Percentage Target",
        cc_wd_fixed = "    Fixed Target",
        cc_limit_id = "    Chat Identity",
        cc_limit_loops = "    Autonomous Limit (ReAct)",
        cc_auto_inject_ctx = "    Auto-Inject CONTEXT.md",
        cc_gk_hint = "    (Press <CR> on an agent to configure)",
        cc_create_agent = "[ + Create New Agent ]",
        cc_edit_sys_prompt = "      ├─ [ Edit System Prompt ]",
        cc_delete_agent = "      └─ [ Delete Agent ]",
        cc_skills_hint = "    (Press 'e' on a skill to edit its code)",
        cc_native_f = "Native",
        cc_native_m = "Native",
        cc_custom = "Custom",
        cc_create_skill = "    └─ [ + Create New Skill ]",
        cc_inj_hint = "    (Press 'e' on an injector to edit its code)",
        cc_create_inj = "    └─[ + Create New Injector ]",
        cc_sq_hint = "    (Press 'e' on a squad to edit its guidelines)",
        cc_create_squad = "    └─ [ + Create New Squad ]",
        cc_app_width = "    Width",
        cc_app_height = "    Height",
        cc_app_border = "    Border Type",
        cc_hist_hint = "    (Press <CR> to load a previous chat)",
        cc_hist_none = "    No history found in this project.",
        cc_vault_hint = "    Vault Status (api_keys.json):",
        cc_master_prompt = "    Master Directive (Root Prompt)",
        cc_telemetry_log = "    Network Log (Print Requests)",
        cc_configured = "Configured",
        cc_missing = "Missing",
        cc_edit = "Edit",
        cc_load = "Load",
        cc_squad = "Squad",
        swarm_api_empty = "⚠️ API returned empty. Returning task to queue (Attempt %d/2)...",
        swarm_task_done = "✅ TASK COMPLETED",
        swarm_fail_repeated = "FAILURE: The API failed repeatedly to process this task.",
        swarm_prev_report = "=== PREVIOUS AGENT REPORT ===",
        swarm_api_err = "❌ API ERROR: %s",
        swarm_api_fail = "⚠️ API Failure (%s). Returning to queue (Attempt %d/2)...",
        swarm_fatal_err = "FATAL ERROR AFTER ATTEMPTS: %s",
        swarm_success_switch = "SUCCESS: Control transferred to @%s. System reconfigured with their guidelines.",
        swarm_err_switch = "ERROR: Agent @%s does not have permission to transfer control to @%s (Check allow_switch).",
        swarm_final_report = "=== SWARM REPORT ===",
        swarm_agent_res = "Agent: @%s\nFinal Result:\n%s\n------------------------",
        cc_create_agent_pmpt = "New Persona name: @",
        cc_create_agent_notify = "Agent @%s created! Expand to configure.",
        cc_delete_agent_prompt = "Do you want to DELETE agent @%s?",
        cc_yes = "&Yes",
        cc_no = "&No",
        cc_deleted = "Agent deleted.",
        cc_create_skill_pmpt = "New Skill name (.lua): ",
        cc_skill_created = "Skill created! Run :ContextReloadTools after editing.",
        cc_create_inj_pmpt = "New Injector name (.lua): ",
        cc_inj_created = "Injector created!",
        cc_create_squad_pmpt = "New Squad name: @",
        cc_squad_created = "Squad @%s created! (Press 'e' to configure)",
        cc_core_tool_warn = "This is a Core tool. Code cannot be edited from here.",
        cc_core_inj_warn = "This is a Native injector. Code cannot be edited from here.",
        cc_hint_default = "  Hint: Use j/k to navigate. Press q to exit.",
        cc_hint_expand = "  Hint: Press <CR> to expand/collapse.",
        cc_hint_toggle = "  Hint: Press <Space> to toggle the value.",
        cc_hint_edit_val = "  Hint: Press 'c' to change this value.",
        cc_hint_edit_src = "  Hint: Press 'e' to edit the source file.",
        cc_hint_cr = "  Hint: Press <CR> to execute the action.",
        cc_prompt_wd_horizon = "New Trigger (tokens): ",
        cc_prompt_wd_tolerance = "New Tolerance (e.g. 1.0): ",
        cc_prompt_wd_percent = "New Percentage (e.g. 30 for 30%): ",
        cc_prompt_wd_fixed = "New Fixed Target (tokens): ",
        cc_prompt_identity = "Your Name: ",
        cc_prompt_loops = "Max Autonomous Turns: ",
        cc_prompt_width = "New Width (e.g. 0.8): ",
        cc_prompt_height = "New Height (e.g. 0.8): ",
        cc_prompt_master = "New Master Directive: ",
        cc_sys_prompt_updated = "System Prompt for agent @%s updated!",
        cc_skill_desc_ph = "Your description here",
        cc_skill_arg_ph = "Argument description",
        cc_skill_res_ph = "Skill result",
        cc_inj_desc_ph = "Your description here",
        cc_inj_res_ph = "Text to be injected",
        cc_agent_sys_ph = "You are an expert in...",
        cc_saved = "Settings and Permissions saved!",
        lsp_prompt_install = "The file \"%s\" requires the LSP \"%s\". Install via Mason? (Recommended for AI)",
        lsp_installing = "Installing LSP %s... Please wait.",
        lsp_installed = "LSP %s installed successfully!",
        lsp_failed = "Failed to install LSP %s.",
    },
    ["pt-BR"] = {
        tool_not_found = "Ferramenta '%s' não existe.",
        op_denied = "Operação negada. O agente @%s não possui a Skill '%s'.",
        danger_cmd = "🛡️ Comando PERIGOSO detectado.",
        allow_danger = "Permitir execução PERIGOSA: ",
        allow_rewrite = "Agente solicitou DESTRUIR E COMPRIMIR o chat. Permitir?",
        allow_tool = "Agente requisitou [%s]. Permitir?",
        confirm_opts = "&Sim\n&Nao\n&Todos\n&Cancelar",
        denied_user = "Acesso NEGADO pelo usuario.",
        skill_err = "ERRO NA EXECUCAO DA SKILL: ",
        buf_rewritten = "Buffer reescrito.",
        swarm_started = "SWARM INICIADO. O trabalho foi delegado aos sub-agentes e está rodando em background.",
        swarm_err_json = "ERRO: O payload JSON fornecido para spawn_swarm é inválido.",
        err_git_destructive = "Acesso NEGADO. Comandos Git remotos ou destrutivos (push, reset, rebase) são estritamente bloqueados por segurança.",
        err_not_git = "ERRO: Fora de repositório Git.",
        git_tracked_files = "Arquivos rastreados pelo Git:\n",
        err_path_req = "ERRO: O atributo 'path' é obrigatório.",
        err_file_not_found = "ERRO: Arquivo não encontrado (%s)",
        err_perm_save = "ERRO: Falha de permissão ao salvar %s",
        file_saved = "✅ Arquivo criado/salvo: %s",
        succ_file_saved = "SUCESSO: Arquivo %s foi sobrescrito/criado.",
        err_cmd_req = "ERRO: Comando não fornecido.",
        fail_code = "FALHA (Código %s)",
        success = "SUCESSO",
        shell_output = "Comando:\n%s\n\nStatus: %s\nSaída:\n%s",
        err_query_req = "ERRO: 'query' obrigatória.",
        no_results = "Nenhum resultado para: %s",
        warn_truncated = "... [AVISO: TRUNCADO] ...",
        search_results = "Resultados da busca:\n",
        err_lines_num = "ERRO: 'start' e 'end' devem ser números.",
        err_file_not_found_simple = "ERRO: Arquivo não encontrado.",
        edit_applied = "✅ Edição aplicada: %s",
        succ_edit_lines = "SUCESSO: Edição nas linhas %s a %s",
        err_path_req_diag = "ERRO: O atributo 'path' é OBRIGATÓRIO. Ex: <tool_call name=\"get_diagnostics\" path=\"caminho/do/arquivo.lua\"></tool_call>",
        err_path_invalid = "ERRO: 'path' inválido.",
        err_load_file = "ERRO: Não foi possível carregar o arquivo: %s",
        warn_no_lsp = "AVISO: Nenhum servidor LSP ativo detectado para: %s",
        diag_clean = "✅ Nenhum diagnóstico ou erro encontrado em: %s",
        diag_for = "Diagnósticos para %s:\n",
        diag_trunc_1 = "\n\n[AVISO: TRUNCADO - %s diagnósticos no total, exibindo %s]",
        diag_trunc_2 = "\n\n[AVISO: %s diagnósticos no total, exibindo os primeiros %s]",
        fail_diff = "FALHA ao aplicar diff (Código %s):\n%s",
        diff_applied = "✅ Diff aplicado: %s",
        succ_diff = "SUCESSO: Diff aplicado no arquivo %s",
        err_git_status = "ERRO ao obter git status:\n%s",
        git_status_clean = "A árvore de trabalho está limpa.",
        git_status_header = "=== STATUS DO GIT ===\n",
        err_branch_req = "ERRO: Nome da branch obrigatório.",
        fail_branch = "FALHA ao trocar de branch:\n%s",
        succ_branch = "SUCESSO: %s",
        err_files_req = "ERRO: Lista de arquivos obrigatória.",
        err_msg_req = "ERRO: Mensagem de commit obrigatória.",
        err_git_add_all = "ERRO: O uso de 'git add .' ou '*' é proibido. Você DEVE ser cirúrgico e especificar os nomes exatos dos arquivos alterados separados por vírgula.",
        err_no_valid_files = "ERRO: Nenhum arquivo válido fornecido.",
        err_git_add = "ERRO no git add:\n%s",
        err_git_commit = "ERRO no git commit:\n%s",
        succ_commit = "SUCESSO: Arquivos comitados.\n%s",
        chat_title = " Multi_Context_Chat | ~%d tokens ",
        hidden_lines = "    ↳ ⋯ [%d linhas ocultas] ⋯  %s",
        swarm_worker_title = "=== SWARM WORKER ===",
        agent_label = "Agente: @",
        api_label = "API: ",
        unknown = "Desconhecida",
        chat_restored = "✅ Chat restaurado do último backup com sucesso!",
        no_backup = "Nenhum backup de compressão encontrado nesta sessão.",
        not_workspace = "Você não está em um arquivo de workspace (.mctx).",
        checkpoint = "> [Checkpoint] Avalie a resposta acima. Pressione <CR> para continuar a fila:",
        type_something = "Digite algo antes de enviar.",
        archivist_sys_prompt = "O contexto atingiu o limite crítico. Analise o histórico e comprima o estado usando EXATAMENTE o modelo Quadripartite (<genesis>, <plan>, <journey>, <now>). Responda APENAS com o XML.",
        guard_limit = "> [Guardião do Contexto]: Limite iminente (%d > %d). Invocando @archivist...",
        sending_req = "[Enviando requisição%s...]",
        sending_via = " via @%s",
        gen_aborted = ">[Sistema]: 🛑 Geração interrompida pelo usuário.",
        prompt_caching = "⚡ Prompt Caching: %d tokens economizados!",
        sys_info_collected = "[Sistema]: Informação coletada. Analise o resultado e continue.",
        sys_action_executed = "[Sistema]: Ação executada. Verifique se o passo foi concluído ou prossiga para a próxima ação.",
        quad_memory = "=== MEMÓRIA CONSOLIDADA (QUADRIPARTITE) ===",
        archivist_compressed = "🧠 Contexto hiper-comprimido pelo @archivist. Retomando tarefa...",
        
        sys_lang_directive = "\n\n=== DIRETRIZ DE IDIOMA ===\nSempre se comunique com o usuário e adicione os comentários no código em Português do Brasil (pt-BR).",
        cc_apis_title = "[1] PROVEDORES DE REDE E APIS",
        cc_apis_desc = "(Gerencie chaves, modelos de IA e fallback)",
        cc_swarm_title = "[2] ORQUESTRAÇÃO DE SWARM (MOA)",
        cc_swarm_desc = "(Determine quais APIs podem atuar como sub-agentes autônomos)",
        cc_watchdog_title = "[3] GUARDIÃO DE CONTEXTO (WATCHDOG)",
        cc_watchdog_desc = "(Regras de compressão e limites da janela de memória da IA)",
        cc_limits_title = "[4] COMPORTAMENTO E LIMITES GLOBAIS",
        cc_limits_desc = "(Identidade do usuário e limites de loops de ReAct)",
        cc_gatekeeper_title = "[5] AGENTES E PERMISSÕES",
        cc_gatekeeper_desc = "(Controle fino de permissões e capacidades por agente)",
        cc_semantic_skills_title = "[6] SKILLS SEMÂNTICAS",
        cc_semantic_skills_desc = "(Comportamentos dos agentes agrupando múltiplas ferramentas do sistema)",
        cc_system_tools_title = "[7] FERRAMENTAS DO SISTEMA (MCP)",
        cc_system_tools_desc = "(Ferramentas binárias brutas e scripts disponíveis no sistema)",
        cc_edit_skill_purpose = "      ├─ [ Editar Guardrails da Skill ]",
        cc_delete_skill = "      └─ [ Deletar Skill ]",
        cc_create_semantic_skill = "    └─ [ + Criar Nova Skill Semântica ]",
        cc_create_semantic_skill_pmpt = "Nome da nova Skill Semântica: ",
        cc_semantic_skill_created = "Skill Semântica '%s' criada!",
        cc_system_tools_hint = "    (Aperte 'e' sobre uma ferramenta para editar seu código)",
        cc_create_tool = "    └─ [ + Criar Nova Ferramenta de Sistema ]",
        cc_delete_skill_prompt = "Deseja DELETAR a skill '%s'?",
        cc_skills_title = "[6] ECOSSISTEMA DE SKILLS LOCAIS",
        cc_skills_desc = "(Habilidades adicionais nativas ou criadas pelo usuário)",
        cc_injectors_title = "[7] MACROS DE CONTEXTO (INJECTORS)",
        cc_injectors_desc = "(Atalhos dinâmicos invocados pela tecla '\\')",
        cc_squads_title = "[8] ESQUADRÕES META-AGENTES (SQUADS)",
        cc_squads_desc = "(Grupos pré-configurados de IA com pipelines e coreografia)",
        cc_app_title = "[9] ESTILIZAÇÃO E APARÊNCIA DA UI",
        cc_app_desc = "(Controle de largura, altura e bordas do chat)",
        cc_history_title = "[10] HISTÓRICO E WORKSPACES",
        cc_history_desc = "(Restaure conversas anteriores salvas no projeto)",
        cc_vault_title = "[11] COFRE E DIRETRIZ MESTRE",
        cc_vault_desc = "(Gerencie suas chaves de API e o Prompt de Sistema Base)",
        cc_telemetry_title = "[12] TELEMETRIA E MODO DEBUG",
        cc_telemetry_desc = "(Logs de rede e diagnósticos avançados)",
        cc_bg_pool_title = "Pool de Background",
        cc_bg_pool_title = "Pool de Background",
        cc_fallback_motor = "    Motor Automático de Fallback",
        cc_providers_list = "    Lista de Provedores:",
        cc_swarm_perm = "    (Permissão para invocar sub-agentes e prioridade de uso)",
        cc_wd_status = "    Status da Interceptação",
        cc_wd_trigger = "    Gatilho (Limiar)",
        cc_wd_tolerance = "    Tolerância do Usuário",
        cc_wd_strategy = "    Estratégia",
        cc_wd_percent = "    Alvo Percentual",
        cc_wd_fixed = "    Alvo Fixo",
        cc_limit_id = "    Identidade no Chat",
        cc_limit_loops = "    Limite Autônomo (ReAct)",
        cc_auto_inject_ctx = "    Auto-Inject CONTEXT.md",
        cc_gk_hint = "    (Aperte <CR> num agente para configurar)",
        cc_create_agent = "[ + Criar Novo Agente ]",
        cc_edit_sys_prompt = "      ├─ [ Editar System Prompt ]",
        cc_delete_agent = "      └─ [ Deletar Agente ]",
        cc_skills_hint = "    (Aperte 'e' sobre uma skill para editar seu código)",
        cc_native_f = "Nativa",
        cc_native_m = "Nativo",
        cc_custom = "Custom",
        cc_create_skill = "    └─ [ + Criar Nova Skill ]",
        cc_inj_hint = "    (Aperte 'e' sobre um injetor para editar seu código)",
        cc_create_inj = "    └─[ + Criar Novo Injetor ]",
        cc_sq_hint = "    (Aperte 'e' sobre um esquadrão para editar suas diretrizes)",
        cc_create_squad = "    └─ [ + Criar Novo Esquadrão ]",
        cc_app_width = "    Largura (Width)",
        cc_app_height = "    Altura (Height)",
        cc_app_border = "    Tipo de Borda",
        cc_hist_hint = "    (Aperte <CR> para carregar um chat anterior)",
        cc_hist_none = "    Nenhum histórico encontrado neste projeto.",
        cc_vault_hint = "    Status do Cofre de Chaves (api_keys.json):",
        cc_master_prompt = "    Diretriz Mestre (Root Prompt)",
        cc_telemetry_log = "    Log de Rede (Imprimir Requições)",
        cc_configured = "Configurada",
        cc_missing = "Faltando",
        cc_edit = "Editar",
        cc_load = "Load",
        cc_squad = "Squad",
        swarm_api_empty = "⚠️ API retornou vazio. Devolvendo tarefa para a fila (Tentativa %d/2)...",
        swarm_task_done = "✅ TAREFA CONCLUÍDA",
        swarm_fail_repeated = "FALHA: A API falhou repetidas vezes em processar esta tarefa.",
        swarm_prev_report = "=== RELATÓRIO DO AGENTE ANTERIOR ===",
        swarm_api_err = "❌ ERRO NA API: %s",
        swarm_api_fail = "⚠️ Falha na API (%s). Devolvendo para a fila (Tentativa %d/2)...",
        swarm_fatal_err = "ERRO FATAL APÓS TENTATIVAS: %s",
        swarm_success_switch = "SUCESSO: Controle transferido para @%s. O sistema foi reconfigurado com suas diretrizes.",
        swarm_err_switch = "ERRO: O agente @%s não tem permissão para transferir o controle para @%s (Verifique allow_switch).",
        swarm_final_report = "=== RELATÓRIO DO ENXAME (SWARM) ===",
        swarm_agent_res = "Agente: @%s\nResultado Final:\n%s\n------------------------",
        cc_create_agent_pmpt = "Nome da nova Persona: @",
        cc_create_agent_notify = "Agente @%s criado! Expanda-o para dar permissões.",
        cc_delete_agent_prompt = "Deseja DELETAR o agente @%s?",
        cc_yes = "&Sim",
        cc_no = "&Nao",
        cc_deleted = "Agente deletado.",
        cc_create_skill_pmpt = "Nome da nova Skill (.lua): ",
        cc_skill_created = "Skill criada! Execute :ContextReloadTools após editar.",
        cc_create_inj_pmpt = "Nome do novo Injetor (.lua): ",
        cc_inj_created = "Injetor criado!",
        cc_create_squad_pmpt = "Nome do novo Esquadrão: @",
        cc_squad_created = "Esquadrão @%s criado! (Aperte 'e' para configurar)",
        cc_core_tool_warn = "Essa é uma ferramenta Core. O código não pode ser alterado por aqui.",
        cc_core_inj_warn = "Este é um injetor nativo. O código não pode ser alterado por aqui.",
        cc_hint_default = "  Dica: Use j/k para navegar. Pressione q para sair.",
        cc_hint_expand = "  Dica: Pressione <CR> para expandir/recolher.",
        cc_hint_toggle = "  Dica: Pressione <Space> para alternar o valor.",
        cc_hint_edit_val = "  Dica: Pressione 'c' para alterar este valor.",
        cc_hint_edit_src = "  Dica: Pressione 'e' para editar o arquivo fonte.",
        cc_hint_cr = "  Dica: Pressione <CR> para executar a ação.",
        cc_prompt_wd_horizon = "Novo Gatilho (tokens): ",
        cc_prompt_wd_tolerance = "Nova Tolerância (ex: 1.0): ",
        cc_prompt_wd_percent = "Novo Percentual (ex: 30 para 30%): ",
        cc_prompt_wd_fixed = "Novo Alvo Fixo (tokens): ",
        cc_prompt_identity = "Seu Nome: ",
        cc_prompt_loops = "Máximo de Turnos Autônomos: ",
        cc_prompt_width = "Nova Largura (ex: 0.8): ",
        cc_prompt_height = "Nova Altura (ex: 0.8): ",
        cc_prompt_master = "Nova Diretriz Mestre: ",
        cc_sys_prompt_updated = "System Prompt do agente @%s atualizado!",
        cc_skill_desc_ph = "Sua descrição aqui",
        cc_skill_arg_ph = "Descrição do argumento",
        cc_skill_res_ph = "Resultado da skill",
        cc_inj_desc_ph = "Sua descrição aqui",
        cc_inj_res_ph = "Texto a ser injetado",
        cc_agent_sys_ph = "Você é um especialista em...",
        cc_saved = "Configurações e Permissões salvas!",
        lsp_prompt_install = "O arquivo \"%s\" requer o LSP \"%s\". Deseja instalar via Mason? (Recomendado para a IA)",
        lsp_installing = "Instalando LSP %s... Por favor, aguarde.",
        lsp_installed = "LSP %s instalado com sucesso!",
        lsp_failed = "Falha ao instalar o LSP %s.",
    }
}

M.t = function(key, ...)
    local lang = config.options.language or "pt-BR"
    local dict = M.dict[lang] or M.dict["pt-BR"]
    local str = dict[key]
    if not str and lang ~= "pt-BR" then str = M.dict["pt-BR"][key] end
    str = str or key
    if select('#', ...) > 0 then return string.format(str, ...) end
    return str
end

return M
--------------------- ./lua/multi_context/llm/prompt_parser.lua : ---------------------
local M = {}
local registry = require('multi_context.tools.registry')
local i18n = require('multi_context.i18n')

M.parse_user_input = function(raw_text, agents_table)
    local parsed = {
        text_to_send = raw_text,
        agent_name = nil,
        is_autonomous = false
    }
    
    local StateManager = require('multi_context.core.state_manager')
    if StateManager.get('react').is_moa_mode then
        parsed.agent_name = "tech_lead"
        parsed.text_to_send = "O usuário solicitou uma orquestração semântica (Modo MOA). Analise a demanda abaixo e use a ferramenta spawn_swarm para instanciar e coordenar os agentes mencionados para que resolvam o problema:\n\n" .. parsed.text_to_send
        parsed.is_autonomous = true
        return parsed
    end

    local ok_sq, squads_manager = pcall(require, 'multi_context.ecosystem.squads')
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
                main_task.instruction = (main_task.instruction or "") .. "\n\nUser Request:\n" .. parsed.text_to_send
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
        local prompt = "You are the system's @archivist. Your mission is to structure the verbose chat memory below using EXACTLY 4 tags: <genesis>, <plan>, <journey>, and <now>.\n"
        if wd.strategy == "percent" then
            local target = math.floor((current_tokens or 5000) * (wd.percent or 0.3))
            prompt = prompt .. "MANDATORY: Compression is based on a percentage ceiling. Your output must not exceed " .. target .. " tokens.\n"
        elseif wd.strategy == "fixed" then
            prompt = prompt .. "MANDATORY: Aggressive compression. Your output must not exceed " .. (wd.fixed_target or 1500) .. " tokens.\n"
        else
            prompt = prompt .. "SEMANTIC COMPRESSION: Adapt the size to the complexity of the content, focusing on information integrity.\n"
        end
        prompt = prompt .. "Reply STRICTLY with the generated XML."
        return prompt
    end
    
    local system_prompt = base_prompt

    if memory_context then
        system_prompt = system_prompt .. "\n\n=== CURRENT PROJECT STATE (MEMORY) ===\n" .. memory_context .. "\n- Update CONTEXT.md when finishing tasks."
    end

    if active_agent_name and active_agent_name ~= "reset" and agents_table and agents_table[active_agent_name] then
        local agent_data = agents_table[active_agent_name]
        local active_agent_prompt = "\n\n=== AGENT INSTRUCTIONS: " .. string.upper(active_agent_name) .. " ===\n" .. agent_data.system_prompt
        
        active_agent_prompt = active_agent_prompt .. "\n\n" .. registry.build_manual_for_skills(agent_data.skills)
        
        system_prompt = system_prompt .. active_agent_prompt
    end

    local ok, skills_manager = pcall(require, 'multi_context.ecosystem.tools_manager')
    if ok and skills_manager and skills_manager.get_tools then
        local user_skills = skills_manager.get_tools()
        local has_user_skills = false
        local user_skills_xml = "\n\n=== CUSTOM TOOLS ===\nYou have access to user-customized tools. You can invoke them by returning an XML block in the format <tool_call name=\"name\">\n<tools>\n"
        
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

    if active_agent_name == "tech_lead" then
        local available = {}
        for k, _ in pairs(agents_table) do table.insert(available, k) end
        system_prompt = system_prompt .. "\n\n=== AVAILABLE AGENTS FOR DELEGATION ===\nYou MUST ONLY assign tasks to these exact agents: " .. table.concat(available, ", ") .. "\nDo NOT invent new agent names (e.g., no 'frontend-coder', 'qa_contrato'). Use STRICTLY and ONLY the names listed above."
    end
    
    local cfg = require('multi_context.config').options
    if cfg.language == "pt-BR" then
        system_prompt = system_prompt .. i18n.t("sys_lang_directive")
    end

    local guardrails = [[

=== FINAL GUARDRAILS (OBEY STRICTLY) ===
- Provide your thought process if needed, but ALWAYS end your turn with a valid <tool_call> OR <final_report>.
- NEVER output ```xml wrappers around your tags. Output raw XML directly.
- NEVER invent tool names.]]
    
    system_prompt = system_prompt .. guardrails

    return system_prompt
end

M.build_asymmetric_payload = function(system_prompt, messages, memory_tier)
    local payload = {}
    if system_prompt then table.insert(payload, { role = "system", content = system_prompt }) end

    local total_msgs = #messages
    for i, msg in ipairs(messages) do
        -- Ignora mensagens que estao em armazenamento frio
        if not msg.metadata or msg.metadata.status ~= "archived" then
            local is_last = (i == total_msgs)
            local content = ""

            -- Se for Tier Meta e NAO for a ultima mensagem (ordem atual), entregamos apenas a topologia
            if memory_tier == "meta" and not is_last then
                local id = (msg.metadata and msg.metadata.id) or "unknown"
                
                if msg.metadata and msg.metadata.type == "summary" then
                    content = string.format("[ID: %s] SUMMARY OF ARCHIVED BLOCKS: %s\n%s", id, msg.metadata.covers or "none", vim.trim(msg.content))
                elseif msg.metadata and msg.metadata.abstract then
                    content = string.format("[ID: %s] Abstract: %s\nKeywords: %s", id, msg.metadata.abstract.summary, msg.metadata.abstract.key_words)
                else
                    content = string.format("[ID: %s] RAW CONTENT:\n%s", id, vim.trim(msg.content))
                end
            else
                -- Se for Tier Standard (ou se for a ultima mensagem), entregamos o texto literal e cru
                content = vim.trim(msg.content)
            end

            table.insert(payload, { role = msg.role, content = content })
        end
    end

    return payload
end

return M
--------------------- ./lua/multi_context/llm/api_handlers.lua : ---------------------
-- lua/multi_context/api_handlers.lua
local M = {}
local transport = require('multi_context.llm.transport')

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






--------------------- ./lua/multi_context/llm/transport.lua : ---------------------
local M = {}

M._temp_files = M._temp_files or {}

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
    if tmp_file then table.insert(cmd, "@" .. tmp_file) else table.insert(cmd, "@-") end
    return cmd
end

local function write_payload_to_tmp(payload)
    local tmp_file = os.tmpname()
    table.insert(M._temp_files, tmp_file)
    local f = io.open(tmp_file, "w")
    if f then f:write(vim.fn.json_encode(payload)); f:close() end
    return tmp_file
end

M.run_http_stream = function(cmd, tmp_file, process_stdout, extract_error, callback)
    local config = require('multi_context.config')
    if config.options.debug_mode then
        local log_file = vim.fn.stdpath('data') .. '/mctx_network_debug.log'
        local f_log = io.open(log_file, 'a')
        if f_log then f_log:write('[MCTX DEBUG] CMD: ' .. table.concat(cmd, ' ') .. '\n'); f_log:close() end
    end
    
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
            for i, f in ipairs(M._temp_files) do
                if f == tmp_file then table.remove(M._temp_files, i); break end
            end
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
--------------------- ./lua/multi_context/llm/api_client.lua : ---------------------
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
    local api_handlers = require('multi_context.llm.api_handlers')

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






--------------------- ./lua/multi_context/core/react_orchestrator.lua : ---------------------
local api = vim.api
local EventBus = require('multi_context.core.event_bus')
local StateManager = require('multi_context.core.state_manager')
local utils = require('multi_context.utils.utils')
local config = require('multi_context.config')
local prompt_parser = require('multi_context.llm.prompt_parser')
local tool_parser = require('multi_context.ecosystem.tool_parser')
local tool_runner = require('multi_context.ecosystem.tool_runner')

local M = {}

local function dispatch_jit_archiving(buf)
    pcall(function()
        local session = require("multi_context.core.session")
        local msgs = session.get_messages()
        local last_msg = msgs[#msgs]
        if last_msg and last_msg.metadata and last_msg.metadata.id then
            require("multi_context.core.dynamic_watchdog").dispatch_jit_task(buf, last_msg.metadata.id, last_msg.content)
        end
    end)
end

local function get_state()
    local st = StateManager.get("react")
    if st.is_autonomous == nil then st.is_autonomous = false end
    if st.auto_loop_count == nil then st.auto_loop_count = 0 end
    if st.is_queue_mode == nil then st.is_queue_mode = false end
    if st.is_moa_mode == nil then st.is_moa_mode = false end
    return st
end

M.setup = function()
    EventBus.on("USER_SUBMIT", function(payload)
        M.ProcessTurn(payload.buf)
    end)
end

M.reset_turn = function()
    StateManager.patch("react", {
        is_autonomous = false,
        auto_loop_count = 0,
        active_job_id = nil,
        user_aborted = false,
        is_moa_mode = false,
    })
end

M.check_circuit_breaker = function()
    local react_state = get_state()
    react_state.auto_loop_count = (react_state.auto_loop_count or 0) + 1
    if react_state.auto_loop_count >= 15 then
        vim.notify("Limite de 15 loops atingido. Pausando por segurança.", vim.log.levels.WARN)
        return true
    end
    return false
end

M.abort_stream = function(is_user)
    local react_state = get_state()
    if react_state.active_job_id then
        react_state.user_aborted = is_user or false
        pcall(vim.fn.jobstop, react_state.active_job_id)
        react_state.active_job_id = nil
    end
end

M.TerminateTurn = function()
    M.reset_turn()
    local react_state = get_state()
    local cfg = require('multi_context.config')
    
    local auto_trigger = false
    if react_state.queued_tasks and react_state.queued_tasks ~= "" then
        if react_state.is_queue_mode then auto_trigger = true end
    end
    
    EventBus.emit("UI_TERMINATE_TURN", {
        current_api = cfg.get_current_api(),
        user_name = cfg.options.user_name or "User",
        queued_tasks = react_state.queued_tasks,
        is_queue_mode = react_state.is_queue_mode,
        auto_trigger = auto_trigger
    })
    
    if react_state.queued_tasks and react_state.queued_tasks ~= "" then
        react_state.queued_tasks = nil
    else
        react_state.is_queue_mode = false
    end
end

local function get_context_md_content()
    local root = vim.fn.system("git rev-parse --show-toplevel")
    if vim.v.shell_error == 0 then root = root:gsub("\n", "") else root = vim.fn.getcwd() end
    local filepath = root .. "/CONTEXT.md"
    if vim.fn.filereadable(filepath) == 1 then return table.concat(vim.fn.readfile(filepath), "\n") end
    return nil
end

M.ProcessTurn = function(buf)
    pcall(function() require('multi_context.ecosystem.tools_manager').load_tools() end)
    if not buf or not api.nvim_buf_is_valid(buf) then return end
    
    local start_idx, _ = utils.find_last_user_line(buf)
    if not start_idx then return end

    local cfg = require('multi_context.config')
    local user_prefix = "## " .. (cfg.options.user_name or "User") .. " >>"
    local lines = api.nvim_buf_get_lines(buf, start_idx, -1, false)
    
    local first_line = lines[1] or ""
    local prefix = first_line:match("^(##%s*[%w_]+%s*>>%s*)") or ""
    lines[1] = first_line:sub(#prefix + 1)

    -- Impede Double Wrapping: Verifica se o prompt já está contido em um <block> XML
    local is_already_block = false
    if lines[1] and lines[1]:match('^<block[^>]*role="user"') then
        is_already_block = true
    end

    local agents = require('multi_context.agents').load_agents()
    local intent_parser = require('multi_context.core.intent_parser')
    
    local parsed_intent = intent_parser.parse_lines(lines, agents)
    local react_state = get_state()
    
    if parsed_intent.flags.is_queue then react_state.is_queue_mode = true end
    if parsed_intent.flags.is_moa then react_state.is_moa_mode = true end

    local raw_user_text = parsed_intent.raw_current_task
    if parsed_intent.queued_text then react_state.queued_tasks = parsed_intent.queued_text end

    -- Extrai o miolo limpo caso o processamento venha de uma rodada arquivada/herdada
    if is_already_block then
        local full_text = table.concat(lines, "\n")
        local inner = full_text:match('<block[^>]*>(.-)</block>')
        if inner then raw_user_text = vim.trim(inner) end
    end

    if raw_user_text == "" then vim.notify(require("multi_context.i18n").t("type_something"), vim.log.levels.WARN); return end

    local prompt_parsed = prompt_parser.parse_user_input(raw_user_text, agents)
    
    if prompt_parsed.agent_name then
        if prompt_parsed.agent_name == "reset" then react_state.active_agent = nil
        else react_state.active_agent = prompt_parsed.agent_name end
    end
    if prompt_parsed.is_autonomous then react_state.is_autonomous = true end

    local text_to_send = prompt_parsed.text_to_send
    local active_agent_name = react_state.active_agent

    -- Consagra e envelopa a intenção final na UI
    if not is_already_block then
        local b_id = "usr_" .. os.date("%H%M%S") .. "_" .. tostring(math.random(100, 999))
        local new_user_lines = { prefix .. string.format('<block id="%s" type="raw" role="user" status="active">', b_id) }
        for _, l in ipairs(vim.split(text_to_send, "\n", {plain=true})) do table.insert(new_user_lines, l) end
        table.insert(new_user_lines, "</block>")
        api.nvim_buf_set_lines(buf, start_idx, -1, false, new_user_lines)
    end

    local mem_tracker = require('multi_context.utils.memory_tracker')
    local current_tokens = utils.estimate_tokens(buf)
    local prompt_tokens = math.floor(#text_to_send / 4)
    local predicted_total = mem_tracker.predict_next_total(current_tokens, prompt_tokens)
    local horizon = (cfg.options.cognitive_horizon or 4000) * (cfg.options.user_tolerance or 1.0)

    local Session = require('multi_context.core.session')
    local history_lines = api.nvim_buf_get_lines(buf, 0, -1, false)
    Session.sync_from_lines(history_lines)

    if predicted_total > horizon and active_agent_name ~= "archivist" then
        react_state.pending_user_prompt = text_to_send
        react_state.active_agent = "archivist"
        active_agent_name = "archivist"
        text_to_send = require("multi_context.i18n").t("archivist_sys_prompt")
        
        local msgs = Session.get_messages()
        if #msgs > 0 then
            table.remove(msgs, #msgs)
            StateManager.set('session_messages', msgs)
        end

        Session.add_message("user", text_to_send, { id = "arch_"..os.date("%H%M%S"), type = "raw", status = "active" })
        
        local msg = require("multi_context.i18n").t("guard_limit", predicted_total, horizon)
        EventBus.emit("UI_APPEND_LINES", { buf = buf, lines = { "", msg, "" } })
    end

    local sending_msg = require("multi_context.i18n").t("sending_req", active_agent_name and require("multi_context.i18n").t("sending_via", active_agent_name) or "")
    EventBus.emit("UI_APPEND_LINES", { buf = buf, lines = { "", sending_msg } })

    local base_sys_prompt = cfg.options.master_prompt or "Você é um Engenheiro de Software Autônomo no Neovim."
    local memory_context = get_context_md_content()
    local system_prompt = prompt_parser.build_system_prompt(base_sys_prompt, memory_context, active_agent_name, agents, current_tokens)
    
    local messages = Session.build_payload(system_prompt)

    local response_started = false
    local accumulated_text = ""
    local current_ia_start_idx = nil
    
    local function remove_sending_msg()
        local count = api.nvim_buf_line_count(buf)
        local last_line = api.nvim_buf_get_lines(buf, count - 1, count, false)[1]
        if last_line:match("%[Enviando requisi") then 
            EventBus.emit("UI_SET_LINES_PARTIAL", { buf = buf, start_idx = count - 2, end_idx = count, lines = {} })
        end
    end

    EventBus.emit("UI_START_STREAMING", { buf = buf })

    require('multi_context.llm.api_client').execute(messages, 
        function(job_id)
            react_state.active_job_id = job_id
            react_state.user_aborted = false
        end,
        function(chunk, api_entry)
            if not response_started then
                remove_sending_msg()
                local ia_title = "## IA (" .. api_entry.model .. ")" .. (active_agent_name and ("[@" .. active_agent_name .. "]") or "") .. " >> "
                local ia_b_id = "ia_" .. os.date("%H%M%S") .. "_" .. tostring(math.random(100, 999))
                local block_start = string.format('<block id="%s" type="raw" role="assistant" status="active">', ia_b_id)
                local count_before = api.nvim_buf_line_count(buf)
                EventBus.emit("UI_APPEND_LINES", { buf = buf, lines = { "", ia_title .. block_start } })
                current_ia_start_idx = count_before + 2
                response_started = true
            end
            if type(chunk) == "string" and chunk ~= "" then
                EventBus.emit("UI_APPEND_CHUNK", { buf = buf, chunk = chunk })
                EventBus.emit("UI_CHUNK_RECEIVED", { buf = buf })
                
                accumulated_text = accumulated_text .. chunk
                if accumulated_text:match("</tool_call>%s*$") then
                    local tags = {}
                    for n in accumulated_text:gmatch('<tool_call[^>]*name="([^"]+)"') do table.insert(tags, n) end
                    local last_name = tags[#tags]
                    if last_name and (last_name == "edit_file" or last_name == "replace_lines" or last_name == "run_shell") then
                        M.abort_stream(false)
                    end
                end
                EventBus.emit("UI_UPDATE_TITLE")
            end
        end,
        function(api_entry, metrics)
            require('multi_context.utils.memory_tracker').add_turn(math.floor(#accumulated_text / 4))
            
            if response_started then
                EventBus.emit("UI_APPEND_CHUNK", { buf = buf, chunk = "\n</block>" })
            end
            
            EventBus.emit("UI_STOP_STREAMING", { buf = buf })
            react_state.active_job_id = nil
            
            if react_state.user_aborted then
                EventBus.emit("UI_APPEND_LINES", { buf = buf, lines = { "", require("multi_context.i18n").t("gen_aborted") } })
                dispatch_jit_archiving(buf)
                M.TerminateTurn()
                return
            end
            
            if not response_started then remove_sending_msg() end
            if metrics and (metrics.cache_read_input_tokens or 0) > 0 then
                vim.notify(require("multi_context.i18n").t("prompt_caching", metrics.cache_read_input_tokens), vim.log.levels.INFO)
            end
            
            local has_tool = accumulated_text:match("<tool_call") ~= nil

            if react_state.pending_user_prompt and react_state.active_agent == "archivist" then
                vim.defer_fn(function() M.HandleArchivistCompression(current_ia_start_idx, buf) end, 100)
            elseif has_tool then
                vim.defer_fn(function() M.ExecuteTools(current_ia_start_idx, buf) end, 100)
            else
                dispatch_jit_archiving(buf)
                M.TerminateTurn()
            end
        end,
        function(err_msg)
            EventBus.emit("UI_STOP_STREAMING", { buf = buf })
            remove_sending_msg()
            EventBus.emit("UI_APPEND_LINES", { buf = buf, lines = { "", "**[ERRO]** " .. err_msg, "", user_prefix .. " " } })
            react_state.is_autonomous = false
        end
    )
end

M.ExecuteTools = function(ia_idx, buf)
    if not buf or not vim.api.nvim_buf_is_valid(buf) then return end
    local react_state = get_state()
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
    local collected_results = {}
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

        -- FIX LUAJIT GOTO SCOPE: Variável declarada antes de qualquer goto
        local attr_str = (parsed_tag.path or "") .. "|" .. (parsed_tag.query or "") .. "|" .. (parsed_tag.start_line or "")

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

        -- Assinatura combinada com os atributos para detectar falhas iguais
        react_state._temp_sig = (parsed_tag.name or "") .. ":" .. vim.trim(parsed_tag.inner or "") .. ":" .. attr_str

        if react_state.last_tool_sig == react_state._temp_sig then
            react_state.tool_loop_count = (react_state.tool_loop_count or 0) + 1
        else
            react_state.last_tool_sig = react_state._temp_sig
            react_state.tool_loop_count = 1
        end

        if react_state.tool_loop_count >= 3 then
            abort_all = true
            new_content = new_content .. parsed_tag.raw_tag .. (parsed_tag.inner or "") .. "</tool_call>\n\n>[Sistema]: 🛑 ERRO FATAL - LOOP INFINITO DETECTADO (Você repetiu a mesma ação 3 vezes). Autonomia suspensa."
            react_state.is_autonomous = false
            should_continue_loop = false
            goto continue
        end

        has_changes = true
        
        new_content = new_content .. parsed_tag.raw_tag .. (parsed_tag.inner or "") .. "</tool_call>"

        do
            local tag_out, should_abort, cont_loop, rew_content, backup_made = tool_runner.execute(
                parsed_tag, 
                react_state.is_autonomous, 
                approve_all_ref, 
                buf
            )

            if backup_made then StateManager.get('react').last_backup = backup_made end
            if rew_content then pending_rewrite_content = rew_content end
            if cont_loop then should_continue_loop = true end

            if tag_out and tag_out ~= "" then
                table.insert(collected_results, tag_out)
            end

            if should_abort then
                abort_all = true
            else
                -- Regex robusta para capturar erros e suspender autonomia
                if tag_out:match("ERROR") or tag_out:match("ERRO:") or tag_out:match("ERRO %-") then
                    react_state.is_autonomous = false
                    should_continue_loop = false
                end
            end
        end

        ::continue::
        cursor = parsed_tag.close_end + 1
    end

    if not has_changes then 
        dispatch_jit_archiving(buf)
        M.TerminateTurn()
        return 
    end

    -- Fase 1: Renderiza o texto na tela
    if pending_rewrite_content then
        local rewrite_lines = vim.split(pending_rewrite_content, "\n", {plain=true})
        EventBus.emit("UI_SET_LINES", { buf = buf, lines = rewrite_lines })
    else
        local final_lines = {}
        for _, l in ipairs(prefix_lines) do table.insert(final_lines, l) end
        for _, l in ipairs(vim.split(new_content, "\n", {plain=true})) do table.insert(final_lines, l) end
        
        -- Resultados alocados estritamente em blocks fora do response original da IA
        if #collected_results > 0 then
            table.insert(final_lines, "")
            for _, res in ipairs(collected_results) do
                for _, l in ipairs(vim.split(res, "\n", {plain=true})) do table.insert(final_lines, l) end
                table.insert(final_lines, "")
            end
        end
        
        EventBus.emit("UI_SET_LINES", { buf = buf, lines = final_lines })
    end

    -- Fase 2: Decide se aborta o loop (incluindo se o abort_all disparou)
    if pending_rewrite_content or abort_all or (not should_continue_loop and not react_state.is_autonomous) then
        dispatch_jit_archiving(buf)
        M.TerminateTurn()
        return
    end

    -- Fase 3: Circuit Breaker Global
    if M.check_circuit_breaker() then
        dispatch_jit_archiving(buf)
        M.TerminateTurn()
        return
    end

    local cfg = require('multi_context.config')
    local user_prefix = "## " .. (cfg.options.user_name or "User") .. " >>"
    
    local sys_msg = require("multi_context.i18n").t("sys_info_collected")
    if not should_continue_loop and react_state.is_autonomous then
        sys_msg = require("multi_context.i18n").t("sys_action_executed")
    end

    local sys_id = "sys_" .. os.date("%H%M%S") .. "_" .. tostring(math.random(100, 999))
    local sys_block = string.format('<block id="%s" type="tool_result" role="user" status="active">\n<content>\n>[Sistema]: %s\n</content>\n</block>', sys_id, sys_msg)

    EventBus.emit("UI_APPEND_LINES", { buf = buf, lines = { "", user_prefix .. " " .. sys_block } })
    vim.defer_fn(function() M.ProcessTurn(buf) end, 100)
end

M.HandleArchivistCompression = function(ia_idx, buf)
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
    local user_prefix = "## " .. (cfg.options.user_name or "User") .. " >>"
    
    local new_lines = { require("multi_context.i18n").t("quad_memory") }
    
    local function append_split(txt)
        if not txt then return end
        for _, l in ipairs(vim.split(txt, "\n", {plain=true})) do table.insert(new_lines, l) end
    end
    
    local b_id = "summary_" .. os.date("%H%M%S") .. "_" .. tostring(math.random(100, 999))
    append_split(string.format('<block id="%s" type="summary" role="assistant" status="active" covers="all">', b_id))
    append_split("<genesis>\n" .. vim.trim(genesis) .. "\n</genesis>")
    append_split("<plan>\n" .. vim.trim(plan) .. "\n</plan>")
    append_split("<journey>\n" .. vim.trim(journey) .. "\n</journey>")
    append_split("<now>\n" .. vim.trim(now) .. "\n</now>")
    append_split("</block>")
    
    local react_state = get_state()
    if react_state.pending_user_prompt then
        local u_id = "usr_" .. os.date("%H%M%S") .. "_" .. tostring(math.random(100, 999))
        append_split(user_prefix .. string.format(' <block id="%s" type="raw" role="user" status="active">', u_id))
        append_split(react_state.pending_user_prompt)
        append_split("</block>")
    end
    
    EventBus.emit("UI_SET_LINES", { buf = buf, lines = new_lines })
    
    require('multi_context.utils.memory_tracker').reset()
    react_state.pending_user_prompt = nil
    react_state.active_agent = nil
    
    EventBus.emit("UI_ARCHIVIST_DONE", { buf = buf })
    vim.notify(require("multi_context.i18n").t("archivist_compressed"), vim.log.levels.INFO)
    vim.defer_fn(function() M.ProcessTurn(buf) end, 100)
end

return M
--------------------- ./lua/multi_context/core/intent_parser.lua : ---------------------
local M = {}

M.parse = function(raw_text)
    local intent = {
        clean_text = raw_text or "",
        agent = nil,
        flags = { is_queue = false, is_moa = false }
    }
    
    if intent.clean_text == "" then return intent end

    -- Extração de flags booleanas rígidas
    if intent.clean_text:match("%-%-queue") then 
        intent.flags.is_queue = true 
    end
    if intent.clean_text:match("%-%-moa") then 
        intent.flags.is_moa = true 
    end
    
    intent.clean_text = intent.clean_text:gsub("%s*%-%-queue", ""):gsub("%s*%-%-moa", "")
    intent.clean_text = vim.trim(intent.clean_text)

    -- Extração do Agente com override forçado para MOA
    if intent.flags.is_moa then
        intent.agent = "tech_lead"
    else
        local possible_agent = intent.clean_text:match("^@([%w_]+)")
        if possible_agent then
            intent.agent = possible_agent
            intent.clean_text = vim.trim(intent.clean_text:gsub("^@" .. possible_agent .. "%s*", ""))
        else
            possible_agent = intent.clean_text:match("@([%w_]+)")
            if possible_agent then
                intent.agent = possible_agent
                intent.clean_text = vim.trim(intent.clean_text:gsub("@" .. possible_agent .. "%s*", ""))
            end
        end
    end

    return intent
end

M.parse_lines = function(lines, agents_table)
    agents_table = agents_table or {}
    local raw_full_text = table.concat(lines, "\n")
    
    local intent = {
        raw_current_task = "",
        queued_text = nil,
        flags = { is_queue = false, is_moa = false }
    }
    
    -- O Lua match retorna a string. Convertendo explicitamente para booleano:
    if raw_full_text:match("%-%-queue") then intent.flags.is_queue = true end
    if raw_full_text:match("%-%-moa") then intent.flags.is_moa = true end
    
    local current_task_lines = {}
    local queued_tasks_lines = {}
    local found_agent_count = 0
    
    local cleaned_lines = {}
    for _, line in ipairs(lines) do
	  		if line:match("^##%s*IA") then break end -- IMPEDE A CRIAÇÃO DE FILAS FANTASMAS
        table.insert(cleaned_lines, (line:gsub("%s*%-%-queue", ""):gsub("%s*%-%-moa", "")))
    end

    for _, line in ipairs(cleaned_lines) do
        if not line:match("^> %[Checkpoint%]") then
            local possible_agent = line:match("@([%w_]+)")
            if possible_agent and agents_table[possible_agent] then 
                found_agent_count = found_agent_count + 1 
            end
            
            if intent.flags.is_moa then
                table.insert(current_task_lines, line)
            else
                if found_agent_count <= 1 then 
                    table.insert(current_task_lines, line) 
                else 
                    table.insert(queued_tasks_lines, line) 
                end
            end
        end
    end
    
    intent.raw_current_task = table.concat(current_task_lines, "\n"):gsub("^%s*", ""):gsub("%s*$", "")
    if #queued_tasks_lines > 0 then
        intent.queued_text = table.concat(queued_tasks_lines, "\n")
    end
    
    return intent
end

return M
--------------------- ./lua/multi_context/core/session.lua : ---------------------
local StateManager = require('multi_context.core.state_manager')
local M = {}

M.clear = function()
    StateManager.set('session_messages', {})
end

M.add_message = function(role, content, metadata)
    local safe_content = vim.trim(content or "")
    if safe_content == "" then return end
    
    local msgs = StateManager.get('session_messages') or {}
    table.insert(msgs, { role = role, content = safe_content, metadata = metadata or {} })
    StateManager.set('session_messages', msgs)
end

M.get_messages = function()
    return vim.deepcopy(StateManager.get('session_messages') or {})
end

M.build_payload = function(system_prompt)
    local config = require('multi_context.config')
    local utils = require('multi_context.utils.utils')
    local final_sys = system_prompt or ''
    if config.options.auto_inject_context_md then
        local ctx_path = utils.get_context_md_path()
        if ctx_path then
            local lines = vim.fn.readfile(ctx_path)
            local ctx_content = table.concat(lines, '\n')
            final_sys = final_sys .. '\n\n=== CONTEXT.md (Active Memory) ===\n' .. ctx_content
        end
    end
    local payload = {}
    if final_sys ~= '' then table.insert(payload, { role = 'system', content = final_sys }) end
    for _, m in ipairs(M.get_messages()) do 
        if not m.metadata or m.metadata.status ~= 'archived' then
            table.insert(payload, { role = m.role, content = m.content })
        end
    end
    return payload
end

M.sync_from_lines = function(lines)
    M.clear()
    if not lines or #lines == 0 then return end
    
    local xml_content = table.concat(lines, "\n")
    
    for tag_attrs, raw_inner_content in xml_content:gmatch('<block([^>]*)>(.-)</block>') do
        local id = tag_attrs:match('id="([^"]+)"')
        local type = tag_attrs:match('type="([^"]+)"')
        local role = tag_attrs:match('role="([^"]+)"')
        local status = tag_attrs:match('status="([^"]+)"')
        local covers = tag_attrs:match('covers="([^"]*)"')
        
        local meta = { id = id, type = type, status = status }
        if covers and covers ~= "" then meta.covers = covers end
        
        local final_content = raw_inner_content
        local abstract_content = raw_inner_content:match('<abstract>(.-)</abstract>')
        
        if abstract_content then
            local kw = abstract_content:match('<key_words>(.-)</key_words>')
            local summ = abstract_content:match('<summary>(.-)</summary>')
            meta.abstract = {
                key_words = kw and vim.trim(kw) or "",
                summary = summ and vim.trim(summ) or ""
            }
        end
        
        local explicit_content = raw_inner_content:match('<content>(.-)</content>')
        if explicit_content then
            final_content = explicit_content
        end
        
        M.add_message(role, final_content, meta)
    end
end

return M
--------------------- ./lua/multi_context/core/dynamic_watchdog.lua : ---------------------
local session = require('multi_context.core.session')
local archiver = require('multi_context.core.archiver')
local EventBus = require('multi_context.core.event_bus')

local M = {}

M.build_background_payload = function()
    local payload = {}
    table.insert(payload, { 
        role = "system", 
        content = "Você é um arquivista de background. Sua tarefa é ler o histórico a seguir e gerar um resumo estritamente descritivo, mantendo os detalhes técnicos e operacionais. Não use formatação markdown e não invente fatos." 
    })
    
    local msgs = session.get_messages()
    local content_to_summarize = {}
    
    for _, msg in ipairs(msgs) do
        if msg.metadata and msg.metadata.status ~= "archived" and msg.metadata.type ~= "summary" then
            table.insert(content_to_summarize, string.format("[%s]: %s", msg.role, msg.content))
        end
    end
    
    table.insert(payload, { role = "user", content = table.concat(content_to_summarize, "\n\n") })
    return payload
end

M.on_background_response_received = function(ids_to_cover, summary_text)
    local new_id = "summary_" .. os.date("%H%M%S")
    archiver.compress(ids_to_cover, summary_text, new_id)
    EventBus.emit("UI_ARCHIVIST_DONE", { buf = vim.api.nvim_get_current_buf() })
end

M.build_jit_payload = function(msg_content)
    return {
        {
            role = "system",
            content = "You are a Cognitive Librarian. Analyze the provided block content and extract semantic metadata. Reply STRICTLY and ONLY with valid XML containing: <key_words>comma-separated keywords</key_words> and <summary>brief descriptive summary</summary>."
        },
        {
            role = "user",
            content = msg_content
        }
    }
end

M.patch_block_abstract = function(buf, block_id, abstract_xml)
    if not vim.api.nvim_buf_is_valid(buf) then return false end
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local start_idx = nil
    local end_idx = nil
    
    for i, line in ipairs(lines) do
        if line:match('<block[^>]*id="' .. vim.pesc(block_id) .. '"') then
            start_idx = i - 1
        elseif start_idx and line:match('</block>') then
            end_idx = i - 1
            break
        end
    end
    
    if not start_idx or not end_idx then return false end
    
    local block_def = lines[start_idx + 1]
    local block_end = lines[end_idx + 1]
    
    local inner_lines = {}
    for i = start_idx + 2, end_idx do table.insert(inner_lines, lines[i]) end
    local inner_content = table.concat(inner_lines, "\n")
    
    if inner_content:match("<content>") then return true end
    
    local new_lines = { block_def }
    local abs_lines = vim.split("<abstract>\n" .. vim.trim(abstract_xml) .. "\n</abstract>", "\n", {plain=true})
    for _, l in ipairs(abs_lines) do table.insert(new_lines, l) end
    
    table.insert(new_lines, "<content>")
    for _, l in ipairs(inner_lines) do table.insert(new_lines, l) end
    table.insert(new_lines, "</content>")
    table.insert(new_lines, block_end)
    
    vim.api.nvim_buf_set_lines(buf, start_idx, end_idx + 1, false, new_lines)
    
    local msgs = session.get_messages()
    for _, msg in ipairs(msgs) do
        if msg.metadata and msg.metadata.id == block_id then
            local kw = abstract_xml:match("<key_words>(.-)</key_words>")
            local summ = abstract_xml:match("<summary>(.-)</summary>")
            msg.metadata.abstract = {
                key_words = kw and vim.trim(kw) or "",
                summary = summ and vim.trim(summ) or ""
            }
            break
        end
    end
    require('multi_context.core.state_manager').set('session_messages', msgs)
    EventBus.emit("UI_ARCHIVIST_DONE", { buf = buf })
    return true
end

M.dispatch_jit_task = function(buf, block_id, msg_content)
    local config = require('multi_context.config')
    local wd_cfg = config.options.watchdog or {}
    
    if wd_cfg.strategy ~= "dynamic" or not wd_cfg.background_api or wd_cfg.background_api == "" then return end
    
    local api_cfg = config.load_api_config()
    if not api_cfg or not api_cfg.apis then return end
    
    local target_api = nil
    for _, a in ipairs(api_cfg.apis) do
        if a.name == wd_cfg.background_api then target_api = a; break end
    end
    if not target_api then return end
    
    local payload = M.build_jit_payload(msg_content)
    local api_client = require('multi_context.llm.api_client')
    local accumulated = ""
    
    api_client.execute(payload, 
        function() end, 
        function(chunk) if chunk then accumulated = accumulated .. chunk end end,
        function() M.patch_block_abstract(buf, block_id, accumulated) end,
        function(err) vim.notify("[Watchdog] JIT Erro: " .. tostring(err), vim.log.levels.WARN) end,
        target_api
    )
end


M.dispatch_parallel_jit_tasks = function(buf, blocks)
    local config = require('multi_context.config')
    local api_cfg = config.load_api_config()
    if not api_cfg or not api_cfg.apis then return end
    
    local pool = {}
    for _, a in ipairs(api_cfg.apis) do
        if a.allow_background then
            table.insert(pool, a)
        end
    end
    
    if #pool == 0 then return end
    
    local api_client = require('multi_context.llm.api_client')
    
    for i, block in ipairs(blocks) do
        local target_api = pool[((i - 1) % #pool) + 1]
        local payload = M.build_jit_payload(block.content)
        local accumulated = ""
        
        api_client.execute(payload,
            function() end, 
            function(chunk) if chunk then accumulated = accumulated .. chunk end end,
            function() M.patch_block_abstract(buf, block.id, accumulated) end,
            function(err) vim.notify("[Watchdog] JIT Erro (Pool): " .. tostring(err), vim.log.levels.WARN) end,
            target_api
        )
    end
end


M.build_harvester_payload = function()
    local payload = {}
    table.insert(payload, {
        role = "system",
        content = "Você é o 'The Harvester'. Analise o histórico da sessão e extraia fatos arquiteturais, regras de negócio e resoluções de bugs. Retorne um texto limpo e direto para compor o arquivo CONTEXT.md."
    })
    local session = require("multi_context.core.session")
    local msgs = session.get_messages()
    local to_summarize = {}
    for _, m in ipairs(msgs) do
        if m.metadata and m.metadata.status ~= "archived" and m.metadata.type ~= "summary" then
            table.insert(to_summarize, string.format("[%s]: %s", m.role, m.content))
        end
    end
    table.insert(payload, { role = "user", content = table.concat(to_summarize, "\n\n") })
    return payload
end

M.run_harvester = function()
    local config = require('multi_context.config')
    if not config.options.auto_inject_context_md then return end
    local wd_cfg = config.options.watchdog or {}
    local api_cfg = config.load_api_config()
    if not api_cfg or not api_cfg.apis then return end
    local target_api = nil
    for _, a in ipairs(api_cfg.apis) do
        if a.name == wd_cfg.background_api then target_api = a; break end
    end
    if not target_api then
        for _, a in ipairs(api_cfg.apis) do
            if a.allow_background then target_api = a; break end
        end
    end
    if not target_api then target_api = api_cfg.apis[1] end
    if not target_api then return end
    local payload = M.build_harvester_payload()
    local api_client = require('multi_context.llm.api_client')
    local accumulated = ""
    vim.notify("[Harvester] 🌾 Analisando a sessão em background para colher aprendizados...", vim.log.levels.INFO)
    api_client.execute(payload, function() end,
        function(chunk) if chunk then accumulated = accumulated .. chunk end end,
        function()
            local tools = require('multi_context.ecosystem.native_tools')
            local clean = accumulated:gsub("^%s*```[%w_]*\n", ""):gsub("\n%s*```%s*$", "")
            if clean and clean ~= "" then
                local header = "\n\n### 🌾 Harvester Insight (" .. os.date("%Y-%m-%d %H:%M") .. ")\n"
                local res = tools.update_context_md(header .. clean)
                if res:match("SUCESSO") then
                    vim.notify("[Harvester] ✅ CONTEXT.md atualizado organicamente!", vim.log.levels.INFO)
                end
            end
        end,
        function(err) vim.notify("[Harvester] Erro: " .. tostring(err), vim.log.levels.WARN) end,
    target_api)
end

EventBus.on("WORKSPACE_SAVED", function()
    M.run_harvester()
end)

return M
--------------------- ./lua/multi_context/core/event_bus.lua : ---------------------
local M = {}

-- Estado interno do Bus: Dicionário onde a chave é o nome do evento
-- e o valor é uma lista de callbacks (funções).
local listeners = {}

M.on = function(event_name, callback)
    if type(callback) ~= "function" then return end
    if not listeners[event_name] then listeners[event_name] = {} end
    table.insert(listeners[event_name], callback)
end

M._once_wrappers = {}
M.once = function(event_name, callback)
    if type(callback) ~= "function" then return end
    local wrapper
    wrapper = function(payload)
        M.off(event_name, wrapper)
        callback(payload)
    end
    M._once_wrappers[wrapper] = callback
    M.on(event_name, wrapper)
end

M.off = function(event_name, callback)
    if not listeners[event_name] then return end
    for i, cb in ipairs(listeners[event_name]) do
        if cb == callback or (M._once_wrappers and M._once_wrappers[cb] == callback) then
            table.remove(listeners[event_name], i)
            break
        end
    end
end

M.emit = function(event_name, payload)
    if not listeners[event_name] then return end
    
    -- Criamos uma cópia local da lista de callbacks.
    -- Isso é crucial para evitar bugs caso um evento remova 
    -- a si mesmo (como no caso do 'once') durante a iteração.
    local cbs = {}
    for _, cb in ipairs(listeners[event_name]) do 
        table.insert(cbs, cb) 
    end
    
    for _, cb in ipairs(cbs) do
        -- Executa envolto em pcall para que um listener quebrado
        -- não trave toda a cadeia de execução do sistema.
        pcall(cb, payload)
    end
end

M.clear = function()
    listeners = {}
end

return M
--------------------- ./lua/multi_context/core/state_manager.lua : ---------------------
local M = {}

local _state = {}

M.get = function(key)
    if not _state[key] then _state[key] = {} end
    return _state[key]
end

M.set = function(key, value)
    _state[key] = value
end

M.patch = function(key, table_values)
    if type(table_values) ~= "table" then return end
    if type(_state[key]) ~= "table" then _state[key] = {} end
    
    for k, v in pairs(table_values) do
        _state[key][k] = v
    end
end

M.reset = function()
    _state = {}
end

return M
--------------------- ./lua/multi_context/core/swarm_manager.lua : ---------------------
local config = require('multi_context.config')
local api_client = require('multi_context.llm.api_client')
local popup = require('multi_context.ui.chat_view')
local tools = require('multi_context.ecosystem.native_tools')
local agents = require('multi_context.agents')
local tool_parser = require('multi_context.ecosystem.tool_parser')
local tool_runner = require('multi_context.ecosystem.tool_runner')
local i18n = require('multi_context.i18n')

local M = {}
M.state = { queue = {}, workers = {}, reports = {} }

M.reset = function() M.state.queue = {}; M.state.workers = {}; M.state.reports = {} end

M.init_swarm = function(json_payload)
    M.reset()
    if not json_payload or json_payload == "" then return false end
    local clean_payload = vim.trim(json_payload)
    local ok, decoded = pcall(vim.fn.json_decode, clean_payload)
    if not ok then
        -- A Mágica de Extração: Ignora tudo e pega do primeiro { até o último }
        local json_match = clean_payload:match("%b{}")
        if json_match then ok, decoded = pcall(vim.fn.json_decode, json_match) end
    end
    -- NOVO: Fallback para desembrulhar a alucinação "json_payload" do LLM
    if ok and type(decoded) == "table" and decoded.json_payload and type(decoded.json_payload) == "string" then
        local inner_ok, inner_decoded = pcall(vim.fn.json_decode, decoded.json_payload)
        if inner_ok and type(inner_decoded) == "table" then
            decoded = inner_decoded
        end
    end
    if not ok or type(decoded) ~= "table" or type(decoded.tasks) ~= "table" then 
        return false, "ERRO JSON: Formato inválido. Use apenas chaves { } e o array 'tasks'." 
    end
    local ok_sq, squads_manager = pcall(require, "multi_context.ecosystem.squads")
    local squads = ok_sq and squads_manager.load_squads() or {}
    local new_tasks = {}
    for _, task in ipairs(decoded.tasks) do
        local target = task.agent or (task.chain and task.chain[1])
        if target and squads[target] then
            local squad = squads[target]
            local main_task = vim.deepcopy(squad.tasks[1] or {})
            local col_purp = squad.collective_purpose or squad.description or ""
            local purpose_block = col_purp ~= "" and ("\n=== SQUAD MISSION: " .. col_purp .. " ===\n") or ""
            main_task.instruction = purpose_block .. (main_task.instruction or "") .. "\n\nDelegated Task: " .. (task.instruction or "")
            if not main_task.agent and main_task.chain and #main_task.chain > 0 then main_task.agent = main_task.chain[1] end
            table.insert(new_tasks, main_task)
            if squad.tasks then for i = 2, #squad.tasks do table.insert(new_tasks, squad.tasks[i]) end end
        else
            if not task.agent and type(task.chain) == "table" and #task.chain > 0 then task.agent = task.chain[1] end
            table.insert(new_tasks, task)
        end
    end
    M.state.queue = new_tasks
    local apis = require("multi_context.config").get_spawn_apis()
    for _, api_cfg in ipairs(apis) do table.insert(M.state.workers, { api = api_cfg, busy = false, current_task = nil }) end
    return true
end

M.dispatch_next = function()
    if #M.state.queue == 0 then
        local any_busy = false
        for _, w in ipairs(M.state.workers) do if w.busy then any_busy = true; break end end
        if not any_busy and M.on_swarm_complete then
            local summary = i18n.t("swarm_final_report") .. "\n"
            for _, rep in ipairs(M.state.reports) do
                summary = summary .. "\n" .. i18n.t("swarm_agent_res", rep.agent, rep.result)
            end
            M.on_swarm_complete(summary)
        end
        return
    end

    local level_val = { low = 1, medium = 2, high = 3 }
    local loaded_agents = require('multi_context.agents').load_agents()

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
                if api_level >= req_level then
                    local diff = api_level - req_level
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
            local buf_id = popup.create_swarm_buffer(task.agent, task.instruction, worker.api.name)
            
            local system_prompt = "You are a sub-agent operating in SWARM mode. Your strict task is: " .. (task.instruction or "")
            if loaded_agents[task.agent] then
                system_prompt = system_prompt .. "\n\n=== YOUR GUIDELINES ===\n" .. loaded_agents[task.agent].system_prompt
            end
            
            local registry = require('multi_context.tools.registry')
            local agent_def_for_skills = loaded_agents[task.agent] or loaded_agents["coder"] or {skills={}}
            system_prompt = system_prompt .. "\n\n" .. registry.build_manual_for_skills(agent_def_for_skills.skills)
            
            local context_text = "" 
            if type(task.context) == "table" then
                for _, path in ipairs(task.context) do
                    if path ~= "*" and path ~= "" then
                        context_text = context_text .. "\n== File: " .. path .. " ==\n" .. tools.read_file(path)
                    end
                end
            end
            system_prompt = system_prompt .. "\n\n=== INITIAL CONTEXT PROVIDED ===\n" .. context_text            
            system_prompt = system_prompt .. "\n\n=== DELIVERY RULES & TOOL SYNTAX (CRITICAL) ===\n1. TOOL SYNTAX: You must ONLY use the exact tool names provided in the ACTIVE SKILLS list. Do NOT invent tools or XML tags (e.g., no <bash>, <execute>, <function>). Parameters like 'path' MUST be passed as XML attributes, e.g.: <tool_call name=\"read_file\" path=\"src/main.ts\"></tool_call>\n2. TASK COMPLETION: When your task is fully completed and you DO NOT need to call any more tools, you MUST output your results inside <final_report>...</final_report> tags.\n3. FATAL ERROR WARNING: If you stop responding without using a tool AND without opening a <final_report> tag, the system will consider it a FATAL ERROR and fail your task. ALWAYS conclude with <final_report>. The report MUST include a clear summary of what was done, the edited files, and list in a structured way the executed Git operations (if any)."

            local cfg = require('multi_context.config').options
            if cfg.language == "pt-BR" then
                system_prompt = system_prompt .. i18n.t("sys_lang_directive")
            end

            local messages = {
                { role = "system", content = system_prompt },
                { role = "user", content = "Start executing your task. If you need more information, use the available tools. When you finish all the work, provide a summary." }
            }
            
            local visual_history = ""
            local final_report_text = ""

            local function execute_turn()
                local current_chunk = ""
                api_client.execute(messages,
                    function() end,
                    function(chunk) 
                        current_chunk = current_chunk .. chunk 
                        require('multi_context.core.event_bus').emit("UI_SWARM_WORKER_UPDATE", { 
                            buf = buf_id, 
                            text = visual_history .. "\n\n## IA >>\n" .. current_chunk 
                        })
                    end,
                    function(api_entry, metrics)
                        visual_history = visual_history .. "\n\n## IA >>\n" .. current_chunk
                        table.insert(messages, { role = "assistant", content = current_chunk })
                        
                        local extracted_report = current_chunk:match("<final_report>(.-)</final_report>")
                        if extracted_report then
                            final_report_text = vim.trim(extracted_report)
                        else
                            final_report_text = ""
                        end

                        local sanitized = tool_parser.sanitize_payload(current_chunk)
                        
                        if sanitized:match("<tool_call") then
                            local new_content = ""
                            local cursor = 1
                            local approve_ref = { value = true }
                            
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
                                task.switch_count = (task.switch_count or 0) + 1
                                if task.switch_count > 3 then switch_target = nil; new_content = "FATAL ERROR: Loop infinito de troca de agente detectado." end
                                task.switch_count = (task.switch_count or 0) + 1
                                if task.switch_count > 3 then switch_target = nil; new_content = "FATAL ERROR: Loop infinito de troca de agente detectado (limite de 3) excedido." end
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
                                        local new_system = "You are a sub-agent operating in SWARM mode. Your strict task is: " .. (task.instruction or "")
                                        if loaded_agents[switch_target] then
                                            new_system = new_system .. "\n\n=== YOUR GUIDELINES ===\n" .. loaded_agents[switch_target].system_prompt
                                        end
                                        new_system = new_system .. "\n\n=== INITIAL CONTEXT PROVIDED ===\n" .. context_text
                                        new_system = new_system .. "\n\n=== DELIVERY RULES & TOOL SYNTAX (CRITICAL) ===\n1. TOOL SYNTAX: You must ONLY use exact tool names from ACTIVE SKILLS. Do NOT invent tags (no <bash>, <execute>). Parameters like 'path' MUST be XML attributes.\n2. TASK COMPLETION: When your task is fully completed, you MUST output results inside <final_report>...</final_report> tags.\n3. FATAL ERROR WARNING: Stopping without using a tool AND without a <final_report> is a FATAL ERROR. ALWAYS conclude with <final_report>. The report MUST include a clear summary of what was done, the edited files, and list in a structured way the executed Git operations (if any). This tag ends your execution, and without it, the master will not read your response."
                                        
                                        local cfg = require('multi_context.config').options
                                        if cfg.language == "pt-BR" then
                                            new_system = new_system .. i18n.t("sys_lang_directive")
                                        end
                                        
                                        messages[1].content = new_system
                                        new_content = i18n.t("swarm_success_switch", switch_target)
                                        
                                        if buf_id and vim.api.nvim_buf_is_valid(buf_id) then
                                            local popup = require('multi_context.ui.chat_view')
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
                                        new_content = i18n.t("swarm_err_switch", task.agent, switch_target)
                                    end
                                end

                                visual_history = visual_history .. "\n\n## Sistema >>\n" .. new_content
                                table.insert(messages, { role = "user", content = new_content })
                                execute_turn() 
                                return
                            end
                        end
                        
                        if buf_id and vim.api.nvim_buf_is_valid(buf_id) then
                            local lines = vim.api.nvim_buf_get_lines(buf_id, 0, -1, false)
                            table.insert(lines, "")
                            table.insert(lines, i18n.t("swarm_task_done"))
                            vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
                        end
                        
                        worker.busy = false
                        local clean_res = final_report_text:gsub("%s+", "")
                        
                        task.retries = task.retries or 0
                        if clean_res == "" and task.retries < 2 then
                            task.retries = task.retries + 1
                            if buf_id and vim.api.nvim_buf_is_valid(buf_id) then
                                local lines = vim.api.nvim_buf_get_lines(buf_id, 0, -1, false)
                                table.insert(lines, i18n.t("swarm_api_empty", task.retries))
                                vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
                            end
                            table.insert(M.state.queue, task)
                        else
                            if clean_res == "" then final_report_text = i18n.t("swarm_fail_repeated") end
                            local has_next = false
                            if type(task.chain) == 'table' then
                                local c_idx = 0
                                for idx, a in ipairs(task.chain) do if a == task.agent then c_idx = idx; break end end
                                if c_idx > 0 and c_idx < #task.chain then
                                    task.agent = task.chain[c_idx + 1]
                                    task.instruction = (task.instruction or '') .. '\n\n' .. i18n.t("swarm_prev_report") .. '\n' .. final_report_text
                                    task.retries = 0
                                    table.insert(M.state.queue, task)
                                    has_next = true
                                end
                            end
                            if not has_next then
                            table.insert(M.state.reports, { agent = task.agent, result = final_report_text })
                            end
                        end
                        vim.schedule(M.dispatch_next)
                    end,
                    function(err)
                        if buf_id and vim.api.nvim_buf_is_valid(buf_id) then
                            local lines = vim.api.nvim_buf_get_lines(buf_id, 0, -1, false)
                            table.insert(lines, "")
                            table.insert(lines, i18n.t("swarm_api_err", tostring(err)))
                            vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
                        end
                        worker.busy = false
                        task.retries = task.retries or 0
                        if task.retries < 2 then
                            task.retries = task.retries + 1
                            if buf_id and vim.api.nvim_buf_is_valid(buf_id) then
                                local lines = vim.api.nvim_buf_get_lines(buf_id, 0, -1, false)
                                table.insert(lines, i18n.t("swarm_api_fail", worker.api.name, task.retries))
                                vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
                            end
                            table.insert(M.state.queue, task)
                        else
                            table.insert(M.state.reports, { agent = task.agent, result = i18n.t("swarm_fatal_err", tostring(err)) })
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
--------------------- ./lua/multi_context/core/archiver.lua : ---------------------
local session = require('multi_context.core.session')
local StateManager = require('multi_context.core.state_manager')
local M = {}

M.compress = function(ids_to_cover, summary_text, new_id)
    local msgs = StateManager.get('session_messages') or {}
    
    for _, msg in ipairs(msgs) do
        for _, target_id in ipairs(ids_to_cover) do
            if msg.metadata and msg.metadata.id == target_id then
                msg.metadata.status = "archived"
            end
        end
    end
    
    session.add_message("assistant", summary_text, {
        id = new_id,
        type = "summary",
        status = "active",
        covers = table.concat(ids_to_cover, ",")
    })
end

M.deep_dive = function(target_id)
    local msgs = StateManager.get('session_messages') or {}
    local covers = nil
    
    -- 1. Busca o bloco summary pelo ID para extrair a lista covers
    for _, msg in ipairs(msgs) do
        if msg.metadata and msg.metadata.id == target_id then
            covers = msg.metadata.covers
            break
        end
    end
    
    -- Se não achou ou não tem covers, aborta
    if not covers or covers == "" then
        return "Sistema: Nenhum bloco associado ao ID fornecido ou ID não encontrado. (nenhum bloco)"
    end
    
    local target_ids = vim.split(covers, ",", { plain = true })
    local retrieved_blocks = {}
    
    -- 2. Varre novamente a RAM buscando os blocos cujos IDs estão na lista
    for _, msg in ipairs(msgs) do
        if msg.metadata and msg.metadata.id then
            for _, t_id in ipairs(target_ids) do
                if msg.metadata.id == vim.trim(t_id) then
                    local id = msg.metadata.id
                    local type = msg.metadata.type or "raw"
                    local role = msg.role or "unknown"
                    local status = msg.metadata.status or "archived"
                    
                    -- Reconstrói o bloco XML original
                    local xml = string.format('<block id="%s" type="%s" role="%s" status="%s">\n%s\n</block>', 
                        id, type, role, status, vim.trim(msg.content))
                    table.insert(retrieved_blocks, xml)
                end
            end
        end
    end
    
    if #retrieved_blocks == 0 then
        return "Sistema: Nenhum bloco associado ao ID fornecido foi encontrado em memória. (nenhum bloco)"
    end
    
    return table.concat(retrieved_blocks, "\n\n")
end

return M
--------------------- ./lua/multi_context/core/conversation.lua : ---------------------
local Session = require('multi_context.core.session')
local M = {}
local api = vim.api
local user_pat = "^##%s*([%w_]+)%s*>>"

local ia_pat = "^##%s*IA.*>>"
M.find_last_user_line = function(buf)
    local lines = api.nvim_buf_get_lines(buf, 0, -1, false)
    for i = #lines, 1, -1 do
        if lines[i]:match(user_pat) and not lines[i]:match(ia_pat) then return i - 1, lines[i] end
    end
    return nil
end

M.build_history = function(buf_or_lines)
    local lines = type(buf_or_lines) == "table" and buf_or_lines or api.nvim_buf_get_lines(buf_or_lines, 0, -1, false)
    Session.sync_from_lines(lines)
    return Session.get_messages()
end

return M
--------------------- ./lua/multi_context/config.lua : ---------------------
local M = {}

M.defaults = {
    user_name     = "User",
    language      = "pt-BR",
    config_path   = vim.fn.stdpath("config") .. "/context_apis.json",
    api_keys_path = vim.fn.stdpath("config") .. "/api_keys.json",
    default_api   = nil,
    cognitive_horizon = 4000,
    user_tolerance = 1.0,
    auto_inject_context_md = true,
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
                    num_tries = 3,
                    ["include_in_fall-back_mode"] = true,
                    allow_spawn = true,
                    abstraction_level = "high"
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
    
    local agents_file = vim.fn.stdpath("config") .. "/mctx_agents.json"
    if vim.fn.filereadable(agents_file) == 1 then
        local lines = vim.fn.readfile(agents_file)
        local ok, parsed = pcall(vim.fn.json_decode, table.concat(lines, "\n"))
        if ok and type(parsed) == "table" then
            local changed = false
            for _, v in pairs(parsed) do
                if v.use_tools ~= nil then
                    if v.use_tools == true then
                        v.skills = {"list_files", "search_code", "read_file", "replace_lines", "apply_diff", "edit_file", "run_shell", "rewrite_chat_buffer", "get_diagnostics", "lsp_definition", "lsp_references", "lsp_document_symbols", "git_status", "git_branch", "git_commit"}
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

    M.bootstrap()
    local disk_cfg = M.load_api_config()
    if disk_cfg then
        if disk_cfg.watchdog then M.options.watchdog = vim.deepcopy(disk_cfg.watchdog) end
        if disk_cfg.cognitive_horizon then M.options.cognitive_horizon = disk_cfg.cognitive_horizon end
        if disk_cfg.user_tolerance then M.options.user_tolerance = disk_cfg.user_tolerance end
        if disk_cfg.auto_inject_context_md ~= nil then M.options.auto_inject_context_md = disk_cfg.auto_inject_context_md end
        if disk_cfg.appearance then M.options.appearance = vim.deepcopy(disk_cfg.appearance) end
    end
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
--------------------- ./lua/multi_context/agents/agents.json : ---------------------
{"coder": {"description": "Engenheiro de Software autônomo (estilo Devin/Claude Code). Muta arquivos e refatora.", "system_prompt": "Você é um Engenheiro de Software Autônomo Sênior integrado diretamente no Neovim do usuário.\n\nRegras Ouro de Execução:\n1. PLANEJAMENTO: NUNCA proponha alterações em códigos que você não leu. Use `search_code` e `read_file` primeiro.\n2. EDIÇÃO CIRÚRGICA: NUNCA crie ou sobrescreva arquivos inteiros com `edit_file` a menos que seja um arquivo novo ou uma refatoração estrutural profunda. SEMPRE prefira usar `replace_lines` para alterações pequenas. Mudanças devem ser mínimas e não super-engenheiradas.\n3. AUTO-CORREÇÃO: Ao editar, o sistema usará o `get_diagnostics`. Se você receber erros de sintaxe ou LSP, não pare; corrija-os na mesma iteração.\n4. NÃO USE BASH PARA COMUNICAR: Não use ferramentas de shell (echo) ou comentários de código temporários para falar com o usuário. Toda comunicação deve ser texto puro fora das tags XML.", "skills": ["list_files", "search_code", "read_file", "replace_lines", "edit_file", "get_diagnostics", "run_shell"]}, "qa": {"description": "Engenheiro de Qualidade (QA). Especialista em testes automatizados.", "system_prompt": "Você é um Engenheiro QA Sênior. Sua função é criar testes unitários, testes de integração e mocks robustos para garantir a resiliência do código. Você tem permissão para ler, buscar e criar arquivos de teste.", "skills": ["list_files", "search_code", "read_file", "edit_file", "run_shell"]}, "inspetor_cli": {"description": "DevOps e Integração (Terminal). Roda comandos bash, compila código e verifica testes.", "system_prompt": "Você é um Engenheiro DevOps especializado em resolução de problemas via linha de comando. Você deve diagnosticar o ambiente e validar execuções.\n\nRegras de Terminal:\n1. Use a ferramenta `run_shell` para rodar suítes de testes (`npm test`, `pytest`, `cargo check`), linting ou auditorias no git.\n2. Se um comando bash falhar, não desista de primeira. Leia as mensagens de erro (stderr), infira a causa (ex: dependência faltando, porta em uso) e rode um novo comando corretivo.\n3. NUNCA use ferramentas bash (`cat`, `grep`, `sed`) para ler ou manipular arquivos nativos. Use comandos estritamente para interações de ambiente, build e execução de binários.", "skills": ["list_files", "read_file", "run_shell"]}, "tech_lead": {"description": "Tech Lead. Orquestra sub-agentes para executar tarefas em paralelo.", "system_prompt": "Voce e um Tech Lead Senior. Sua unica funcao e analisar o pedido do usuario e dividi-lo em tarefas independentes que possam ser executadas em paralelo por outros agentes.\n\nRegras:\n1. NAO ESCREVA CODIGO DIRETAMENTE. Apenas planeje a arquitetura.\n2. Para delegar trabalho, voce DEVE estritamente invocar a ferramenta `spawn_swarm` usando formato JSON rigoroso.\n3. Entenda as capacidades de cada agente: @coder muta codigo, @qa escreve testes, @inspetor_cli roda shell, @arquiteto analisa.\n4. Especifique exatamente quais arquivos devem compor o 'context' de cada tarefa.", "skills": ["spawn_swarm"]}, "arquiteto": {"description": "Especialista em Discovery e Planejamento. Analisa a estrutura e cria rotas (Playbooks), mas não altera código.", "system_prompt": "Você é um Staff Engineer e Arquiteto de Software operando em modo de 'Discovery' (Planejamento). Sua função é navegar pelo projeto, entender o fluxo de dados e identificar débitos técnicos ou arquiteturas alvo.\n\nDiretrizes de Discovery:\n1. Use `list_files`, `search_code` e `read_file` agressivamente para construir um mapa mental da aplicação.\n2. NUNCA EDITE ARQUIVOS DIRETAMENTE. Você está proibido de usar ferramentas de mutação.\n3. Entregue sua análise na forma de Diagramas, Markdown ou um 'Playbook' passo a passo, detalhando exatamente quais arquivos o agente '@coder' precisará alterar depois.", "skills": ["list_files", "search_code", "read_file"]}, "engenheiro_de_prompt": {"description": "Sub-agente de Compressão de Memória. Previne 'Context Rot' reescrevendo o histórico.", "system_prompt": "Você é um Agente de Compressão de Contexto e Extração de Memória. Modelos de IA sofrem de 'Context Rot' em sessões muito longas. Sua ÚNICA finalidade é observar o chat gigantesco atual e usar a ferramenta `rewrite_chat_buffer` para condensar a conversa.\n\nInstruções da ferramenta:\n1. Extraia o que foi pedido pelo usuário e o progresso alcançado até o momento.\n2. Transforme o histórico em um resumo denso com decisões arquiteturais duráveis.\n3. AVISO: Use a ferramenta `rewrite_chat_buffer` e responda APENAS com a chamada XML. Texto fora da chamada é um desperdício do seu turno.", "skills": ["rewrite_chat_buffer"]}}--------------------- ./lua/multi_context/tools/docs/get_project_stack.md : ---------------------
<tool_definition>
  <name>get_project_stack</name>
  <description>Faz uma varredura heurística no ambiente. Retorna o Sistema Operacional, Shell base, configuração de indentação (tabs vs spaces) do buffer atual, presença de LSP e marcadores críticos (Makefile, package.json, tests/). Use antes de planejar arquiteturas ou rodar comandos shell.</description>
  <parameters></parameters>
</tool_definition>
--------------------- ./lua/multi_context/tools/docs/apply_diff.md : ---------------------
  <tool_definition>
    <name>apply_diff</name>
    <description>Aplica um patch estrito de Unified Diff em um arquivo existente. Ideal e RECOMENDADO para fazer pequenas/médias modificações em arquivos longos, economizando tokens e evitando alucinações.</description>
    <parameters>
      <parameter name="path" type="string" required="true">Caminho do arquivo (ex: src/main.lua).</parameter>
      <parameter name="content" type="string" required="true">O código absoluto no formato Unified Diff contendo as flags --- a/file e +++ b/file originais e inalteradas.</parameter>
    </parameters>
  </tool_definition>
--------------------- ./lua/multi_context/tools/docs/git_commit.md : ---------------------
<tool_definition>
  <name>git_commit</name>
  <description>Realiza git add nos arquivos listados e depois cria um git commit. É ESTRITAMENTE PROIBIDO usar '*' ou '.' para adicionar tudo.</description>
  <parameters>
    <parameter name="files" type="string" required="true">Lista de arquivos alterados separados por vírgula (ex: src/main.lua, README.md)</parameter>
    <parameter name="message" type="string" required="true">A mensagem do commit no formato Semantic Commits (ex: feat(ui): ajusta layout)</parameter>
  </parameters>
  <content_description>
    Você deve fornecer os parâmetros em tags XML internas:
    <files>src/main.lua, src/utils.lua</files>
    <message>feat: atualiza utilitários</message>
  </content_description>
</tool_definition>
--------------------- ./lua/multi_context/tools/docs/deep_dive.md : ---------------------
### Tool: deep_dive
Recupera os detalhes completos e o histórico bruto de um bloco de resumo (summary). Use esta ferramenta quando precisar ler as etapas anteriores que foram comprimidas pelo Arquivista para economizar contexto.
**Parameters:**
- `target_id` (string): O ID do bloco de resumo (ex: id="b50") que você deseja expandir. O bloco deve possuir a tag `covers="..."`.

**Usage Example:**
<tool_call name="deep_dive" target_id="b50" />
--------------------- ./lua/multi_context/tools/docs/lsp_definition.md : ---------------------
<tool_definition>
  <name>lsp_definition</name>
  <description>Retorna a linha exata e o código fonte onde uma função/classe foi definida (Go to Definition). Sempre tente usar o search_code ou document_symbols antes para saber o nome do arquivo.</description>
  <parameters>
    <parameter name="path" type="string" required="true">Caminho do arquivo onde o símbolo está sendo chamado</parameter>
    <parameter name="line" type="number" required="true">Linha onde a chamada ocorre</parameter>
  </parameters>
  <content_description>O nome do símbolo (ex: nome da função ou variável)</content_description>
</tool_definition>
--------------------- ./lua/multi_context/tools/docs/get_git_env.md : ---------------------
<tool_definition>
  <name>get_git_env</name>
  <description>Retorna o estado cirúrgico do Git local: Branch atual, commits pendentes (ahead/behind) e bloqueios ativos (Merge conflict em andamento ou Rebase). Use para ter consciência do ambiente antes de criar branches ou commitar.</description>
  <parameters></parameters>
</tool_definition>
--------------------- ./lua/multi_context/tools/docs/git_status.md : ---------------------
<tool_definition>
  <name>git_status</name>
  <description>Retorna o status atual dos arquivos no repositório git local (modificados, adicionados, deletados). Ideal para saber o que compor no commit.</description>
  <parameters>
  </parameters>
</tool_definition>
--------------------- ./lua/multi_context/tools/docs/get_diagnostics.md : ---------------------
8. Obter Diagnósticos LSP (get_diagnostics)
Lê erros e avisos sintáticos apontados pelo LSP em um arquivo específico.
Formato: <tool_call name="get_diagnostics" path="caminho/do/arquivo.lua"></tool_call>
--------------------- ./lua/multi_context/tools/docs/edit_file.md : ---------------------
5. Sobrescrever Arquivo Completo (edit_file)
Sobrescreve um arquivo inteiro ou cria um novo caso não exista.
Formato:
<tool_call name="edit_file" path="caminho.ext">
CÓDIGO INTEIRO AQUI
</tool_call>
--------------------- ./lua/multi_context/tools/docs/switch_agent.md : ---------------------
<tool_definition>
  <name>switch_agent</name>
  <description>Transfere o controle do seu corpo e da sua aba para outro agente em tempo real. Use isso SE você travar ou precisar que um especialista (ex: DBA, QA) assuma a tarefa imediatamente. Só funciona se o mestre lhe autorizou na flag "allow_switch".</description>
  <parameters>
    <parameter name="target_agent" type="string" required="true">
      O nome da persona/agente que deve assumir o controle a partir de agora (ex: "qa", "dba").
    </parameter>
  </parameters>
</tool_definition>
--------------------- ./lua/multi_context/tools/docs/run_shell.md : ---------------------
6. Executar Terminal (run_shell)
Executa scripts bash/git na raiz do projeto.
**Aviso Crítico**: NÃO USE esta ferramenta para ler arquivos com `cat` ou `grep`. Para lidar com código, use as ferramentas nativas de sistema. Use `run_shell` para rodar testes, linting, compilar ou gerenciar o git.

Formato:
<tool_call name="run_shell">
npm run build
</tool_call>--------------------- ./lua/multi_context/tools/docs/list_files.md : ---------------------
1. Listar Arquivos (list_files)
Permite ao agente ver a estrutura do projeto.
Formato: <tool_call name="list_files"></tool_call>
--------------------- ./lua/multi_context/tools/docs/rewrite_chat_buffer.md : ---------------------
7. Reescrever e Comprimir o Chat (rewrite_chat_buffer)
Apaga o histórico inteiro do chat atual e substitui apenas pelo conteúdo enviado. 
VOCÊ DEVE manter a estrutura (## Nome_Do_Usuario >> e ## IA >>) no novo texto.
Formato:
<tool_call name="rewrite_chat_buffer">
## Nome_Do_Usuario >>[Resumo do que foi pedido]
## IA >> [Resumo do estado atual]
</tool_call>
--------------------- ./lua/multi_context/tools/docs/search_code.md : ---------------------
2. Buscar Código no Repositório (search_code)
Busca a ocorrência de uma string/regex nos arquivos rastreados.
Formato: <tool_call name="search_code" query="palavra_ou_funcao"></tool_call>
--------------------- ./lua/multi_context/tools/docs/git_branch.md : ---------------------
<tool_definition>
  <name>git_branch</name>
  <description>Alterna para uma branch existente ou cria uma nova branch de forma isolada.</description>
  <parameters>
    <parameter name="branch_name" type="string" required="true">O nome da branch alvo</parameter>
    <parameter name="create_new" type="boolean" required="false">Se true, cria a branch (checkout -b)</parameter>
  </parameters>
  <content_description>
    Você deve fornecer os parâmetros em tags XML internas:
    <branch_name>feature/nova-tela</branch_name>
    <create_new>true</create_new>
  </content_description>
</tool_definition>
--------------------- ./lua/multi_context/tools/docs/read_file.md : ---------------------
3. Ler Arquivo (read_file)
Permite ler o conteúdo completo de um arquivo local.
Formato: <tool_call name="read_file" path="caminho/do/arquivo.ext"></tool_call>
--------------------- ./lua/multi_context/tools/docs/replace_lines.md : ---------------------
4. Substituir Bloco de Código (replace_lines) - FERRAMENTA RECOMENDADA
Edita um arquivo substituindo estritamente as linhas alvo. 
**Regra do Claude Code**: Prefira ESTA ferramenta no lugar de `edit_file` para economizar contexto e manter a integridade do arquivo. Não envie o arquivo inteiro, apenas as linhas modificadas.

Formato:
<tool_call name="replace_lines" path="arquivo.ts" start="10" end="15">
// APENAS AS NOVAS LINHAS AQUI (substituindo das linhas 10 à 15)
</tool_call>--------------------- ./lua/multi_context/tools/docs/lsp_references.md : ---------------------
<tool_definition>
  <name>lsp_references</name>
  <description>Retorna uma lista de arquivos e linhas onde uma função/variável/classe está sendo usada no projeto (Find References).</description>
  <parameters>
    <parameter name="path" type="string" required="true">Caminho do arquivo onde a definição ocorre</parameter>
    <parameter name="line" type="number" required="true">Linha do símbolo</parameter>
  </parameters>
  <content_description>O nome do símbolo</content_description>
</tool_definition>
--------------------- ./lua/multi_context/tools/docs/spawn_swarm.md : ---------------------
<tool_definition>
  <name>spawn_swarm</name>
  <description>Delega tarefas pesadas para sub-agentes assíncronos. VOCÊ É O TECH LEAD: Não escreva código longo. Apenas leia o contexto, monte a arquitetura e delegue o trabalho braçal usando esta ferramenta.</description>
  <parameters>
    <parameter name="json_payload" type="string" required="true">JSON estrito contendo o array "tasks".</parameter>
  </parameters>
  <content_description>
    CRÍTICO / TERMINANTEMENTE PROIBIDO: 
    - NÃO envolva o JSON em uma chave inventada como {"json_payload": ...}. 
    - NÃO use blocos de código Markdown (```json).
    - Escreva o objeto JSON puro e diretamente no corpo da tag.
    
    Exemplo CORRETO de execução:
    <tool_call name="spawn_swarm">
    {
      "tasks": [
        {
          "agent": "coder",
          "chain": ["qa"],
          "context": ["src/main.lua"],
          "instruction": "Refatorar função X. O QA revisará em seguida."
        }
      ]
    }
    </tool_call>
  </content_description>
</tool_definition>
--------------------- ./lua/multi_context/tools/docs/get_agents_info.md : ---------------------
<tool_definition>
  <name>get_agents_info</name>
  <description>Retorna a lista completa de todos os agentes configurados no sistema e as ferramentas (skills) que cada um tem permissão de usar. Essencial para o @tech_lead saber para quem delegar tarefas.</description>
  <parameters></parameters>
</tool_definition>
--------------------- ./lua/multi_context/tools/docs/lsp_document_symbols.md : ---------------------
<tool_definition>
  <name>lsp_document_symbols</name>
  <description>Retorna uma tabela de conteúdos/índice de um arquivo, listando todas as funções, métodos, e classes declarados nele com suas respectivas linhas.</description>
  <parameters>
    <parameter name="path" type="string" required="true">Caminho do arquivo a ser inspecionado</parameter>
  </parameters>
</tool_definition>
--------------------- ./lua/multi_context/tools/registry.lua : ---------------------
local M = {}

local function get_plugin_base_path()
    local source = debug.getinfo(1, "S").source:sub(2)
    if not source then return nil end
    local base = vim.fn.fnamemodify(source, ":p:h:h:h")
    if vim.fn.fnamemodify(base, ":t") == "lua" then return vim.fn.fnamemodify(base, ":h") end
    return base
end

M.get_skill_doc = function(skill_name)
    local base_path = get_plugin_base_path()
    if not base_path then return nil end
    local skill_file = vim.fn.join({ base_path, "lua", "multi_context", "tools", "docs", skill_name .. ".md" }, "/")
    if vim.fn.filereadable(skill_file) == 0 then
        local curr_file = debug.getinfo(1, "S").source:sub(2)
        skill_file = vim.fn.fnamemodify(curr_file, ":h") .. "/docs/" .. skill_name .. ".md"
    end
    if vim.fn.filereadable(skill_file) == 1 then return table.concat(vim.fn.readfile(skill_file), "\n") end
    return nil
end

M.build_manual_for_skills = function(skills_array)
    local ok, ontology = pcall(require, 'multi_context.ecosystem.ontology')
    if not ok then return "" end
    
    local resolved = ontology.resolve_agent_skills(skills_array)
    if #resolved.raw_tools == 0 then 
        return "\n\n=== SYSTEM TOOLS ===\nWARNING: You currently have NO TOOLS available. Rely entirely on your internal reasoning and the provided context." 
    end
    
    local manual = [[=== SYSTEM TOOLS & SYNTAX (CRITICAL) ===
You are an autonomous machine connected to a Neovim IDE. You have access to the tools below.

CRITICAL RULES:
1. STRICT XML ONLY. Format: <tool_call name="name" attr="val">...</tool_call>
2. NO MARKDOWN WRAPPING. Never wrap your XML in ```xml ... ``` blocks.
3. NO INVENTED TOOLS. Use ONLY the tools explicitly listed below.
4. ONE ACTION PER TURN. Use ONE tool per response to allow the system to process it.
5. AUTO-LSP ACTIVE. The system automatically runs diagnostics after edits. Do not call get_diagnostics manually after saving.]]

    if #resolved.semantic_skills > 0 then
        manual = manual .. "\n\n=== YOUR CAPABILITIES (SKILLS) ==="
        for _, skill in ipairs(resolved.semantic_skills) do
            manual = manual .. "\n- [" .. skill.name .. "]: " .. skill.purpose
        end
    end

    manual = manual .. "\n\n=== ACTIVE TOOLS MANUAL ==="
    for _, tool in ipairs(resolved.raw_tools) do
        local doc = M.get_skill_doc(tool)
        if doc then manual = manual .. "\n" .. doc .. "\n" end
    end
    return manual
end
return M
--------------------- ./lua/multi_context/ecosystem/tool_parser.lua : ---------------------
local M = {}

local valid_tools_list = {
    "list_files", "read_file", "search_code", "edit_file", 
    "run_shell", "replace_lines", "apply_diff", "rewrite_chat_buffer", "get_diagnostics", "spawn_swarm", "switch_agent",
    "lsp_definition", "lsp_references", "lsp_document_symbols", "git_status", "git_branch", "git_commit", "get_agents_info", "get_project_stack", "get_git_env"
}

-- 1. SANITIZADOR ANTI-ALUCINAÇÃO DE SINTAXE
M.sanitize_payload = function(content)
    local c = content
    -- Corrigido para[^<]* para que ele engula o ">" do </arg_value>tool_call>
    c = c:gsub("</[^<]*tool_call%s*>", "</tool_call>")
    c = c:gsub("<tool_call>%s*([a-zA-Z_]+)%s*>", '<tool_call name="%1">')
    
    -- Aliases de Sanitização (Alucinações do LLM)
    c = c:gsub("<bash%s*>", '<tool_call name="run_shell">')
    c = c:gsub("</bash%s*>", '</tool_call>')
    c = c:gsub("<execute%s*>", '<tool_call name="run_shell">')
    c = c:gsub("</execute%s*>", '</tool_call>')
    c = c:gsub("<execute_command%s*>", '<tool_call name="run_shell">')
    c = c:gsub("</execute_command%s*>", '</tool_call>')
    c = c:gsub("<read%s+path=", '<tool_call name="read_file" path=')
    c = c:gsub("</read%s*>", '</tool_call>')

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

    -- Remove tags inventadas que circundam o JSON
    local h_tags = {"content", "code", "command", "arg_value", "argument", "parameters", "parameter", "text", "source", "tool_call", "json_payload"}
    local changed = true
    while changed do
        changed = false
        local before_md = clean
        clean = clean:gsub("^%s*```[%w_]*\n", ""):gsub("\n%s*```%s*$", "")
        if before_md ~= clean then changed = true end
        
        for _, tag in ipairs(h_tags) do
            local pat_full = "^%s*<" .. tag .. "[^>]*>%s*(.-)%s*</" .. tag .. ">%s*$"
            local val = clean:match(pat_full)
            if val then clean = val; changed = true end
            
            local pat_end = "%s*</" .. tag .. ">%s*$"
            if clean:match(pat_end) then clean = clean:gsub(pat_end, ""); changed = true end
            
            local pat_start = "^%s*<" .. tag .. "[^>]*>%s*"
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
        local s, e = content_to_process:find("\n%s*</tool_call%s*>", tag_end + 1)
        if s then
            close_start = content_to_process:find("</tool_call", s)
            close_end = e
        else
            close_start, close_end = content_to_process:find("</tool_call%s*>", tag_end + 1)
        end
        
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
    local start_line = get_attr(tag_str, "start") or get_attr(tag_str, "line")
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

    -- Fallback agressivo: Se a IA mandou o parametro dentro de uma tag interna em vez do atributo
    if not path or path == "" then
        local inner_path = clean_inner:match("<path>(.-)</path>")
        if inner_path then path = vim.trim(inner_path) end
    end
    if not query or query == "" then
        local inner_query = clean_inner:match("<query>(.-)</query>")
        if inner_query then query = vim.trim(inner_query) end
    end
    if not start_line or start_line == "" then
        local inner_start = clean_inner:match("<start>(.-)</start>") or clean_inner:match("<line>(.-)</line>")
        if inner_start then start_line = vim.trim(inner_start) end
    end
    if not end_line or end_line == "" then
        local inner_end = clean_inner:match("<end>(.-)</end>")
        if inner_end then end_line = vim.trim(inner_end) end
    end

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
--------------------- ./lua/multi_context/ecosystem/lsp_manager.lua : ---------------------
local M = {}
local StateManager = require('multi_context.core.state_manager')
local i18n = require('multi_context.i18n')

local EXTENSION_MAP = {
    ["rs"] = "rust_analyzer",
    ["py"] = "pyright",
    ["go"] = "gopls",
    ["ts"] = "ts_ls",
    ["tsx"] = "ts_ls",
    ["js"] = "ts_ls",
    ["jsx"] = "ts_ls",
    ["lua"] = "lua_ls",
    ["c"] = "clangd",
    ["cpp"] = "clangd",
    ["cs"] = "omnisharp",
    ["java"] = "jdtls",
    ["php"] = "intelephense",
    ["rb"] = "solargraph",
    ["html"] = "html",
    ["css"] = "cssls"
}

M._get_lsp_name = function(path)
    local ext = path:match("^.+%.(.+)$")
    if not ext then return nil end
    return EXTENSION_MAP[ext]
end

M.ensure_lsp_for_file = function(path)
    if not path or path == "" then return false end
    
    local lsp_name = M._get_lsp_name(path)
    if not lsp_name then return false end -- Linguagem não mapeada
    
    local state = StateManager.get('react')
    if not state.rejected_lsps then state.rejected_lsps = {} end
    
    -- JIT Gatekeeper: Usuário já recusou antes?
    if state.rejected_lsps[lsp_name] then return false end

    -- Degradation Graceful: Tem Mason instalado?
    local has_mason, registry = pcall(require, "mason-registry")
    if not has_mason then return false end

    local ok, pkg = pcall(function() return registry.get_package(lsp_name) end)
    if not ok or not pkg then return false end

    -- Já está instalado? Segue o jogo.
    if pkg:is_installed() then return true end

    -- Interceptação! Pausa a IA e pergunta ao usuário
    local filename = vim.fn.fnamemodify(path, ":t")
    local msg = i18n.t("lsp_prompt_install", filename, lsp_name)
    local choice = vim.fn.confirm(msg, i18n.t("confirm_opts"):gsub("&Todos\n", ""), 1)

    -- Se escolheu "Não" (2) ou Cancelou (0)
    if choice == 2 or choice == 0 then
        state.rejected_lsps[lsp_name] = true
        return false
    end

    -- Inicia instalação via Mason
    vim.notify(i18n.t("lsp_installing", lsp_name), vim.log.levels.INFO)
    pkg:install()

    -- Segura o Event Loop sincronamente (mas permitindo background jobs do Mason rodarem)
    -- Timeout de 60 segundos
    vim.wait(60000, function() return pkg:is_installed() end, 100)

    if pkg:is_installed() then
        vim.notify(i18n.t("lsp_installed", lsp_name), vim.log.levels.INFO)
        -- Tenta forçar o attachment recarregando o buffer se ele existir
        local bufnr = vim.fn.bufnr(path)
        if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
            vim.api.nvim_buf_call(bufnr, function()
                vim.cmd("silent! doautocmd BufReadPost " .. vim.fn.fnameescape(path))
            end)
        end
        return true
    else
        vim.notify(i18n.t("lsp_failed", lsp_name), vim.log.levels.ERROR)
        return false
    end
end

return M
--------------------- ./lua/multi_context/ecosystem/lsp_bridge.lua : ---------------------
local M = {}

M._find_symbol_col = function(line_text, symbol)
    if not line_text or not symbol then return nil end
    local plain_symbol = symbol:gsub("([^%w])", "%%%1")
    local start_pos = string.find(line_text, plain_symbol)
    if start_pos then
        -- LSP usa indexação 0-based
        return start_pos - 1
    end
    return nil
end

M.get_definition = function(path, line, symbol)
    local full_path = path
    local root = vim.fn.system("git rev-parse --show-toplevel")
    if vim.v.shell_error == 0 then
        root = root:gsub("\n", "")
        if full_path:sub(1,1) ~= "/" then
            full_path = root .. "/" .. full_path
        end
    end

    local uri = vim.uri_from_fname(full_path)
    local lnum = tonumber(line)
    if not lnum then return "ERRO: Atributo 'line' inválido" end
    -- Neovim UI usa 1-based, LSP usa 0-based.
    lnum = lnum - 1

    local params = {
        textDocument = { uri = uri },
        position = { line = lnum, character = 0 }
    }

    local bufnr = vim.fn.bufadd(full_path)
    if bufnr and bufnr ~= 0 then
        local lines = {}
        if vim.api.nvim_buf_is_loaded(bufnr) then
            lines = vim.api.nvim_buf_get_lines(bufnr, lnum, lnum+1, false)
        else
            if vim.fn.filereadable(full_path) == 1 then
                local f_lines = vim.fn.readfile(full_path)
                if f_lines[lnum+1] then table.insert(lines, f_lines[lnum+1]) end
            end
        end
        -- Injeta a coluna se encontrar a palavra chave na linha
        if lines[1] then
            local col = M._find_symbol_col(lines[1], symbol)
            if col then params.position.character = col end
        end
    end

    -- Realiza a chamada silenciosa para o servidor LSP acoplado a este arquivo
    local responses = vim.lsp.buf_request_sync(bufnr, "textDocument/definition", params, 2000)
    
    if not responses or vim.tbl_isempty(responses) then
        return "Nenhuma definição encontrada para o símbolo via LSP."
    end
    
    -- Processa o JSON complexo de retorno do LSP e formata como string pro LLM
    for client_id, response in pairs(responses) do
        if response.result and not vim.tbl_isempty(response.result) then
            local result = response.result
            if not vim.tbl_islist(result) then result = { result } end
            
            local def = result[1]
            local target_uri = def.uri or def.targetUri
            local range = def.range or def.targetSelectionRange
            local target_path = vim.uri_to_fname(target_uri)
            local target_line = range.start.line
            
            local lines = {}
            if vim.fn.filereadable(target_path) == 1 then
                lines = vim.fn.readfile(target_path)
            end
            
            local output = {"=== LSP Go To Definition ===", "Arquivo: " .. target_path}
            
            -- Extrai a função apontada e um bloco de 15 linhas
            local s_idx = math.max(1, target_line - 2)
            local e_idx = math.min(#lines, target_line + 15)
            for i = s_idx, e_idx do
                local prefix = (i == target_line + 1) and ">> " or "   "
                table.insert(output, prefix .. i .. " | " .. lines[i])
            end
            
            return table.concat(output, "\n")
        end
    end
    
    return "Falha ao processar definição via LSP."
end

M.get_references = function(path, line, symbol)
    local full_path = vim.fn.fnamemodify(path, ":p")
    local root = vim.fn.system("git rev-parse --show-toplevel")
    if vim.v.shell_error == 0 then
        root = root:gsub("\n", "")
        if path:sub(1,1) ~= "/" then full_path = root .. "/" .. path end
    end

    local uri = vim.uri_from_fname(full_path)
    local lnum = tonumber(line)
    if not lnum then return "ERRO: Atributo 'line' inválido" end
    lnum = lnum - 1

    local params = {
        textDocument = { uri = uri },
        position = { line = lnum, character = 0 },
        context = { includeDeclaration = true }
    }

    local bufnr = vim.fn.bufadd(full_path)
    if bufnr and bufnr ~= 0 then
        local lines = {}
        if vim.api.nvim_buf_is_loaded(bufnr) then
            lines = vim.api.nvim_buf_get_lines(bufnr, lnum, lnum+1, false)
        else
            if vim.fn.filereadable(full_path) == 1 then
                local f_lines = vim.fn.readfile(full_path)
                if f_lines[lnum+1] then table.insert(lines, f_lines[lnum+1]) end
            end
        end
        if lines[1] then
            local col = M._find_symbol_col(lines[1], symbol)
            if col then params.position.character = col end
        end
    end

    local responses = vim.lsp.buf_request_sync(bufnr, "textDocument/references", params, 2000)
    
    if not responses or vim.tbl_isempty(responses) then
        return "Nenhuma referência encontrada para o símbolo via LSP."
    end
    
    local output = {"=== LSP References ==="}
    local refs_count = 0
    for client_id, response in pairs(responses) do
        if response.result and not vim.tbl_isempty(response.result) then
            for _, ref in ipairs(response.result) do
                local target_uri = ref.uri
                local target_path = vim.uri_to_fname(target_uri)
                local target_line = ref.range.start.line
                table.insert(output, string.format("- %s : Linha %d", target_path, target_line + 1))
                refs_count = refs_count + 1
                if refs_count > 50 then
                    table.insert(output, "... [Truncado (Muitas referencias)]")
                    return table.concat(output, "\n")
                end
            end
        end
    end
    
    if refs_count == 0 then return "Nenhuma referência encontrada para o símbolo via LSP." end
    return table.concat(output, "\n")
end

M.get_document_symbols = function(path)
    local full_path = vim.fn.fnamemodify(path, ":p")
    local root = vim.fn.system("git rev-parse --show-toplevel")
    if vim.v.shell_error == 0 then
        root = root:gsub("\n", "")
        if path:sub(1,1) ~= "/" then full_path = root .. "/" .. path end
    end

    local uri = vim.uri_from_fname(full_path)
    local bufnr = vim.fn.bufadd(full_path)
    local params = { textDocument = { uri = uri } }
    
    local responses = vim.lsp.buf_request_sync(bufnr, "textDocument/documentSymbol", params, 2000)
    if not responses or vim.tbl_isempty(responses) then
        return "Nenhum símbolo encontrado via LSP para este arquivo."
    end
    
    local output = {"=== LSP Document Symbols (" .. path .. ") ==="}
    for client_id, response in pairs(responses) do
        if response.result and not vim.tbl_isempty(response.result) then
            local function parse_symbols(symbols, indent)
                for _, sym in ipairs(symbols) do
                    local kind = sym.kind or "?"
                    local name = sym.name or "?"
                    local range = sym.range or sym.selectionRange
                    if range then
                        table.insert(output, indent .. "- [" .. kind .. "] " .. name .. " (Linha " .. (range.start.line + 1) .. ")")
                    end
                    if sym.children then
                        parse_symbols(sym.children, indent .. "  ")
                    end
                end
            end
            parse_symbols(response.result, "")
            break
        end
    end
    return table.concat(output, "\n")
end


return M
--------------------- ./lua/multi_context/ecosystem/squads.lua : ---------------------
local M = {}
M.squads_file = vim.fn.stdpath("config") .. "/mctx_squads.json"

M.load_squads = function()
    if vim.fn.filereadable(M.squads_file) == 0 then
        local default_squads = {
            squad_dev = {
                description = "Tactical Engineering Unit (End-to-End Delivery)",
                collective_purpose = "MISSION OBJECTIVE: You are an autonomous assembly line. Your collective goal is to implement, rigorously test, and safely version-control the requested feature.\nCHAIN OF COMMAND: 1. The Coder MUST execute the logic. 2. The QA MUST ruthlessly verify edge cases and LSP diagnostics. 3. The DevOps MUST finalize the process with atomic semantic commits.\nRESTRICTION: Do not bypass the QA verification stage under any circumstances. Code that has not been diagnosed and tested is considered toxic.",
                tasks = {
                    { agent = "tech_lead", instruction = "INITIATE PIPELINE: Analyze the human request. Decompose the requirements, enforce the strict Coder -> QA -> DevOps chain, and ensure the pipeline does not stop until the code is committed.", chain = {"coder", "qa", "devops"} }
                }
            }
        }
        vim.fn.writefile({vim.fn.json_encode(default_squads)}, M.squads_file)
    end

    local file = io.open(M.squads_file, "r")
    if not file then return {} end
    local content = file:read("*a")
    file:close()
    local ok, parsed = pcall(vim.fn.json_decode, content)
    parsed = ok and parsed or {}

    local ok_ag, ag_mod = pcall(require, "multi_context.agents")
    local agents = ok_ag and ag_mod.load_agents() or {}
    local val = { low = 1, medium = 2, high = 3 }
    local rev = { [1] = "low", [2] = "medium",[3] = "high" }
    
    for _, sq_def in pairs(parsed) do
        local max_lvl = 1
        if sq_def.tasks then
            for _, t in ipairs(sq_def.tasks) do
                if t.agent then
                    local lvl = (agents[t.agent] and agents[t.agent].abstraction_level) and val[agents[t.agent].abstraction_level] or 3
                    if lvl > max_lvl then max_lvl = lvl end
                end
                if type(t.chain) == "table" then
                    for _, ag in ipairs(t.chain) do
                        local lvl = (agents[ag] and agents[ag].abstraction_level) and val[agents[ag].abstraction_level] or 3
                        if lvl > max_lvl then max_lvl = lvl end
                    end
                end
            end
        end
        sq_def.abstraction_level = rev[max_lvl]
    end
    return parsed
end

M.get_squad_names = function()
    local squads = M.load_squads()
    local names = {}
    for name, _ in pairs(squads) do table.insert(names, name) end
    table.sort(names)
    return names
end

return M
--------------------- ./lua/multi_context/ecosystem/tools_manager.lua : ---------------------
local M = {}
M.tools = {}

M.reset = function() M.tools = {} end

M.load_tools = function(dir_path)
    M.reset()
    if not dir_path then dir_path = vim.fn.stdpath("config") .. "/mctx_tools" end
    if vim.fn.isdirectory(dir_path) == 0 then return end

    local files = vim.fn.globpath(dir_path, "*", false, true)
    
    for _, file in ipairs(files) do
        if file:match("%.lua$") then
            local chunk, err = loadfile(file)
            if chunk then
                local ok, result = pcall(chunk)
                if ok and type(result) == "table" and type(result.name) == "string" and type(result.execute) == "function" then
                    M.tools[result.name] = result
                end
            end
        elseif vim.fn.executable(file) == 1 then
            -- POLYGLOT SKILL: Script executavel genérico (Bash, Fish, JS, Python)
            local name = vim.fn.fnamemodify(file, ":t:r")
            local desc = "Script externo: " .. name
            local params = {}
            
            local lines = vim.fn.readfile(file, "", 20)
            for _, line in ipairs(lines) do
                local d = line:match("DESC:%s*(.*)")
                if d then desc = vim.trim(d) end
                
                local p_name, p_type, p_req, p_desc = line:match("PARAM:%s*(%S+)%s*|%s*(%S+)%s*|%s*(%S+)%s*|%s*(.*)")
                if p_name then
                    table.insert(params, { 
                        name = vim.trim(p_name), type = vim.trim(p_type), 
                        required = (vim.trim(p_req) == "true"), desc = vim.trim(p_desc) 
                    })
                end
            end
            
            M.tools[name] = {
                name = name,
                description = desc,
                parameters = params,
                execute = function(args)
                    local env_vars = "env "
                    if args then
                        for k, v in pairs(args) do
                            env_vars = env_vars .. string.format("MCTX_%s=%s ", string.upper(k), vim.fn.shellescape(tostring(v)))
                        end
                    end
                    return vim.fn.system(env_vars .. vim.fn.shellescape(file))
                end
            }
        end
    end
end

M.get_tools = function() return M.tools end
return M
--------------------- ./lua/multi_context/ecosystem/native_tools.lua : ---------------------
local M = {}
local i18n = require('multi_context.i18n')

local _cached_root = nil
local function get_repo_root()
    if _cached_root ~= nil then return _cached_root == false and nil or _cached_root end
    vim.fn.system("git rev-parse --show-toplevel")
    if vim.v.shell_error ~= 0 then _cached_root = false; return nil end
    _cached_root = vim.fn.system("git rev-parse --show-toplevel"):gsub("\n", "")
    return _cached_root
end

local function resolve_path(path)
    if not path or path == "" then return nil end
    path = vim.trim(path)
    if path:sub(1, 1) == "/" then return path end
    local root = get_repo_root() or vim.fn.getcwd()

    local root_name = vim.fn.fnamemodify(root, ":t")
    if path:sub(1, #root_name + 1) == root_name .. "/" then
        path = path:sub(#root_name + 2)
    end
    return root .. "/" .. path
end

M.list_files = function()
    local root = get_repo_root()
    if not root then return i18n.t("err_not_git") end
    local files = vim.fn.system("git -C " .. vim.fn.shellescape(root) .. " ls-files")
    return i18n.t("git_tracked_files") .. files
end

M.read_file = function(path)
    local full_path = resolve_path(path)
    if not full_path then return i18n.t("err_path_req") end
    if vim.fn.filereadable(full_path) == 0 then return i18n.t("err_file_not_found", full_path) end
    
    local lines = vim.fn.readfile(full_path)
    local numbered_lines = {}
    for i, line in ipairs(lines) do
        table.insert(numbered_lines, string.format("%d | %s", i, line))
    end
    
    return table.concat(numbered_lines, "\n")
end

M.edit_file = function(path, content)
    local full_path = resolve_path(path)
    if not full_path then return i18n.t("err_path_req") end
    
    local dir = vim.fn.fnamemodify(full_path, ":h")
    if vim.fn.isdirectory(dir) == 0 then vim.fn.mkdir(dir, "p") end

    content = content:gsub("\r", "")
    content = content:gsub("^%s*```[%w_]*\n", ""):gsub("\n%s*```%s*$", "")
    
    local lines = vim.split(content, "\n", {plain=true})
    -- Fase 39: JIT Provisioning de LSP
    require("multi_context.ecosystem.lsp_manager").ensure_lsp_for_file(full_path)

    local bufnr = vim.fn.bufnr(full_path)
    
    if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
        vim.api.nvim_buf_call(bufnr, function() vim.cmd("silent! write") end)
    else
        if vim.fn.writefile(lines, full_path) == -1 then
            return i18n.t("err_perm_save", full_path)
        end
    end
    vim.notify(i18n.t("file_saved", full_path), vim.log.levels.INFO)
    return i18n.t("succ_file_saved", full_path)
end

M.run_shell = function(cmd)
    if not cmd or cmd == "" then return i18n.t("err_cmd_req") end
    local root = get_repo_root() or vim.fn.getcwd()
    cmd = vim.trim(cmd)
    local bash_script = string.format("cd %s && %s", vim.fn.shellescape(root), cmd)
        local out_t = {}
    local status_code = 0
    local job_id = vim.fn.jobstart({'bash', '-c', bash_script}, {
        stdout_buffered = true, stderr_buffered = true,
        on_stdout = function(_, data) if data then for _, l in ipairs(data) do if l ~= "" then table.insert(out_t, l) end end end end,
        on_stderr = function(_, data) if data then for _, l in ipairs(data) do if l ~= "" then table.insert(out_t, l) end end end end,
        on_exit = function(_, code) status_code = code end
    })
    if job_id > 0 then vim.wait(60000, function() return vim.fn.jobwait({job_id}, 0)[1] ~= -1 end, 50) end
    local out = table.concat(out_t, "\n")
    local status = status_code ~= 0 and i18n.t("fail_code", status_code) or i18n.t("success")
    return i18n.t("shell_output", cmd, status, out)
end

M.search_code = function(query)
    local root = get_repo_root()
    if not root then return i18n.t("err_not_git") end
    if not query or query == "" then return i18n.t("err_query_req") end
    local cmd
    if vim.fn.executable("rg") == 1 then
        cmd = string.format("rg -n -i -- %s %s", vim.fn.shellescape(query), vim.fn.shellescape(root))
    else
        cmd = string.format("git -C %s grep -n -i -I -- %s", vim.fn.shellescape(root), vim.fn.shellescape(query))
    end
    local out = vim.fn.system(cmd)
    if out == "" then return i18n.t("no_results", query) end
    if #out > 3000 then out = out:sub(1, 3000) .. "\n\n" .. i18n.t("warn_truncated") end
    return i18n.t("search_results") .. out
end

M.replace_lines = function(path, start_line, end_line, content)
    local full_path = resolve_path(path)
    if not full_path then return i18n.t("err_path_req") end
    start_line, end_line = tonumber(start_line), tonumber(end_line)
    if not start_line or not end_line then return i18n.t("err_lines_num") end
    
    -- Fase 39: JIT Provisioning de LSP
    require("multi_context.ecosystem.lsp_manager").ensure_lsp_for_file(full_path)

    local bufnr = vim.fn.bufnr(full_path)
    local lines = {}
    if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
        lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    else
        if vim.fn.filereadable(full_path) == 0 then return i18n.t("err_file_not_found_simple") end
        lines = vim.fn.readfile(full_path)
    end
    
    if start_line < 1 then start_line = 1 end
    if end_line > #lines then end_line = #lines end
    if start_line > #lines + 1 then start_line = #lines + 1 end
    
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
    vim.notify(i18n.t("edit_applied", full_path), vim.log.levels.INFO)
    return i18n.t("succ_edit_lines", start_line, end_line)
end

M.get_diagnostics = function(path)
    if not path or path == "" or path == "nil" then
        return i18n.t("err_path_req_diag")
    end

    path = vim.trim(path)
    local full_path = resolve_path(path)
    if not full_path then return i18n.t("err_path_invalid") end
    
    -- Fase 39: JIT Provisioning de LSP
    require("multi_context.ecosystem.lsp_manager").ensure_lsp_for_file(full_path)

    local bufnr = vim.fn.bufnr(full_path)
    if bufnr == -1 then
        if vim.fn.filereadable(full_path) == 0 then return i18n.t("err_file_not_found", full_path) end
        bufnr = vim.fn.bufadd(full_path)
        if bufnr == 0 then return i18n.t("err_load_file", full_path) end
        vim.fn.bufload(bufnr)
    end

    local has_lsp = vim.lsp.buf_is_attached and vim.lsp.buf_is_attached(bufnr)
    if not has_lsp then
        local clients = vim.lsp.get_clients and vim.lsp.get_clients({bufnr = bufnr}) or {}
        has_lsp = #clients > 0
    end

    if has_lsp then
        vim.wait(50, function() return false end, 10)
    end

    local diagnostics = vim.diagnostic.get(bufnr)
    if not diagnostics or #diagnostics == 0 then
        if not has_lsp then return i18n.t("warn_no_lsp", full_path) end
        return i18n.t("diag_clean", full_path)
    end

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

    local result = i18n.t("diag_for", full_path) .. table.concat(out_lines, "\n")

    if #result > MAX_BYTES then
        result = result:sub(1, MAX_BYTES) .. i18n.t("diag_trunc_1", #diagnostics, count)
    elseif #diagnostics > MAX_DIAGS then
        result = result .. i18n.t("diag_trunc_2", #diagnostics, MAX_DIAGS)
    end

    return result
end

M.apply_diff = function(path, diff_content)
    local full_path = resolve_path(path)
    if not full_path then return i18n.t("err_path_req") end
    if vim.fn.executable("patch") == 0 then return "ERRO: O comando patch nao esta instalado no sistema local. Use as ferramentas replace_lines ou edit_file em vez disso." end
    if vim.fn.executable("patch") == 0 then return "ERRO: O comando patch nao esta instalado no sistema local. Use as ferramentas replace_lines ou edit_file em vez disso." end
    
    -- Fase 39: JIT Provisioning de LSP
    require("multi_context.ecosystem.lsp_manager").ensure_lsp_for_file(full_path)

    local bufnr = vim.fn.bufnr(full_path)
    local lines = {}
    
    if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
        lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        vim.fn.writefile(lines, full_path)
    else
        if vim.fn.filereadable(full_path) == 0 then return i18n.t("err_file_not_found_simple") end
    end
    
    diff_content = diff_content:gsub("\r", "")
    diff_content = diff_content:gsub("^%s*```[%w_]*\n", ""):gsub("\n%s*```%s*$", "")
    
    local tmp_patch = os.tmpname()
    vim.fn.writefile(vim.split(diff_content, "\n", {plain=true}), tmp_patch)
    
        local cmd = {"patch", "--force", "-u", full_path, "-i", tmp_patch}
    local out_t = {}
    local status = 0
    local job_id = vim.fn.jobstart(cmd, {
        stdout_buffered = true, stderr_buffered = true,
        on_stdout = function(_, data) if data then for _, l in ipairs(data) do if l ~= "" then table.insert(out_t, l) end end end end,
        on_stderr = function(_, data) if data then for _, l in ipairs(data) do if l ~= "" then table.insert(out_t, l) end end end end,
        on_exit = function(_, code) status = code end
    })
    if job_id > 0 then vim.wait(15000, function() return vim.fn.jobwait({job_id}, 0)[1] ~= -1 end, 50) end
    local out = table.concat(out_t, "\n")
    
    os.remove(tmp_patch)
    os.remove(full_path .. ".orig")
    os.remove(full_path .. ".rej")
    
    if status ~= 0 then return i18n.t("fail_diff", status, out) end
    
    if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
        local new_lines = vim.fn.readfile(full_path)
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)
        vim.api.nvim_buf_call(bufnr, function() vim.cmd("silent! write") end)
    end
    
    vim.notify(i18n.t("diff_applied", full_path), vim.log.levels.INFO)
    return i18n.t("succ_diff", full_path)
end

M.git_status = function()
    local root = get_repo_root()
    if not root then return i18n.t("err_not_git") end
    local out = vim.fn.system("git -C " .. vim.fn.shellescape(root) .. " status -s")
    if vim.v.shell_error ~= 0 then return i18n.t("err_git_status", out) end
    if out == "" then return i18n.t("git_status_clean") end
    return i18n.t("git_status_header") .. out
end

M.git_branch = function(branch_name, create_new)
    local root = get_repo_root()
    if not root then return i18n.t("err_not_git") end
    if not branch_name or branch_name == "" then return i18n.t("err_branch_req") end
    local flag = ""
    if create_new == true or create_new == "true" then flag = "-b " end
    local cmd = string.format("git -C %s checkout %s%s", vim.fn.shellescape(root), flag, vim.fn.shellescape(branch_name))
    local out = vim.fn.system(cmd)
    if vim.v.shell_error ~= 0 then return i18n.t("fail_branch", out) end
    return i18n.t("succ_branch", out)
end

M.git_commit = function(files_str, message)
    local root = get_repo_root()
    if not root then return i18n.t("err_not_git") end
    if not files_str or files_str == "" then return i18n.t("err_files_req") end
    if not message or message == "" then return i18n.t("err_msg_req") end
    
    if files_str:match("^%s*%.%s*$") or files_str:match("%*") or files_str:match("%-A") or files_str:match("%-%-all") then
        return i18n.t("err_git_add_all")
    end
    
    local files = vim.split(files_str, ",", {trimempty=true})
    if #files == 0 then return i18n.t("err_no_valid_files") end
    
    local escaped_files = {}
    for _, f in ipairs(files) do table.insert(escaped_files, vim.fn.shellescape(vim.trim(f))) end
    
    local add_cmd = string.format("git -C %s add %s", vim.fn.shellescape(root), table.concat(escaped_files, " "))
    local add_out = vim.fn.system(add_cmd)
    if vim.v.shell_error ~= 0 then return i18n.t("err_git_add", add_out) end
    
    local commit_cmd = string.format("git -C %s commit -m %s", vim.fn.shellescape(root), vim.fn.shellescape(message))
    local commit_out = vim.fn.system(commit_cmd)
    if vim.v.shell_error ~= 0 then return i18n.t("err_git_commit", commit_out) end
    
    return i18n.t("succ_commit", commit_out)
end


M.get_agents_info = function()
    local agents = require('multi_context.agents').load_agents()
    local out = {"=== AGENTES DISPONÍVEIS E SUAS FERRAMENTAS ==="}
    for name, data in pairs(agents) do
        table.insert(out, "- @" .. name .. " [Nível: " .. (data.abstraction_level or "high") .. "]: " .. table.concat(data.skills or {}, ", "))
    end
    return table.concat(out, "\n")
end

M.get_project_stack = function(buf)
    local root = get_repo_root() or vim.fn.getcwd()
    local out = {"=== PROJECT STACK & ENVIRONMENT ==="}
    
    local os_info = vim.loop.os_uname()
    table.insert(out, "SO: " .. os_info.sysname .. " " .. os_info.release .. " (" .. os_info.machine .. ")")
    table.insert(out, "Shell: " .. vim.o.shell)

    if buf and vim.api.nvim_buf_is_valid(buf) then
        local expandtab = vim.bo[buf].expandtab
        local shiftwidth = vim.bo[buf].shiftwidth
        table.insert(out, "Indentação do Buffer Atual: " .. (expandtab and "Espaços" or "Tabs") .. " (Tamanho: " .. shiftwidth .. ")")

        local clients = vim.lsp.get_clients and vim.lsp.get_clients({bufnr = buf}) or {}
        if #clients > 0 then
            local lsp_names = {}
            for _, c in ipairs(clients) do table.insert(lsp_names, c.name) end
            table.insert(out, "LSP Ativo Neste Arquivo: Sim (" .. table.concat(lsp_names, ", ") .. ")")
        else
            table.insert(out, "LSP Ativo Neste Arquivo: Não")
        end
    end

    local markers = {"Makefile", "package.json", "Cargo.toml", "requirements.txt", "pom.xml", "go.mod", "tests/", "spec/", "docker-compose.yml"}
    local found_markers = {}
    for _, m in ipairs(markers) do
        if vim.fn.glob(root .. "/" .. m) ~= "" then table.insert(found_markers, m) end
    end
    if #found_markers > 0 then
        table.insert(out, "Marcadores de Ecossistema Encontrados: " .. table.concat(found_markers, ", "))
    end

    return table.concat(out, "\n")
end

M.get_git_env = function()
    local root = get_repo_root()
    if not root then return i18n.t("err_not_git") end

    local out = {"=== GIT ENVIRONMENT ==="}
    local branch = vim.fn.system("git -C " .. vim.fn.shellescape(root) .. " branch --show-current"):gsub("\n", "")
    table.insert(out, "Branch atual: " .. (branch == "" and "Detached HEAD" or branch))

    local status_ahead_behind = vim.fn.system("git -C " .. vim.fn.shellescape(root) .. " rev-list --left-right --count origin/" .. branch .. "..." .. branch .. " 2>/dev/null")
    if vim.v.shell_error == 0 then
        local parts = vim.split(status_ahead_behind, "\t")
        if #parts == 2 then
            table.insert(out, "Commits: " .. vim.trim(parts[2]) .. " ahead, " .. vim.trim(parts[1]) .. " behind origin")
        end
    end

    local is_merge = vim.fn.filereadable(root .. "/.git/MERGE_HEAD") == 1
    local is_rebase = vim.fn.isdirectory(root .. "/.git/rebase-merge") == 1 or vim.fn.isdirectory(root .. "/.git/rebase-apply") == 1
    
    if is_merge then table.insert(out, "⚠️ ESTADO CRÍTICO: MERGE EM PROGRESSO (Resolva os conflitos antes de prosseguir)") end
    if is_rebase then table.insert(out, "⚠️ ESTADO CRÍTICO: REBASE EM PROGRESSO") end

    return table.concat(out, "\n")
end


M.deep_dive = function(target_id)
    if not target_id or target_id == "" then 
        return "Erro: Parâmetro target_id é obrigatório." 
    end
    local archiver = require('multi_context.core.archiver')
    return archiver.deep_dive(target_id)
end


M.read_block_content = function(ids_str)
    if not ids_str or ids_str == "" then return "Erro: Nenhum ID fornecido." end
    local target_ids = vim.split(ids_str, ",", { trimempty = true })
    local session = require('multi_context.core.session')
    local msgs = session.get_messages()
    local found = {}
    
    for _, msg in ipairs(msgs) do
        if msg.metadata and msg.metadata.id then
            for _, t_id in ipairs(target_ids) do
                if msg.metadata.id == vim.trim(t_id) then
                    table.insert(found, string.format("[ID: %s]\n%s\n", msg.metadata.id, msg.content))
                end
            end
        end
    end
    
    if #found == 0 then return "Nenhum bloco correspondente aos IDs fornecidos foi encontrado na memória." end
    return table.concat(found, "\n")
end

M.archive_blocks = function(ids_str, macro_summary)
    if not ids_str or ids_str == "" then return "Erro: Nenhum ID fornecido." end
    local target_ids = vim.split(ids_str, ",", { trimempty = true })
    local StateManager = require('multi_context.core.state_manager')
    local session = require('multi_context.core.session')
    local msgs = StateManager.get('session_messages') or {}
    
    for _, msg in ipairs(msgs) do
        if msg.metadata and msg.metadata.id then
            for _, t_id in ipairs(target_ids) do
                if msg.metadata.id == vim.trim(t_id) then
                    msg.metadata.status = "archived"
                end
            end
        end
    end
    StateManager.set('session_messages', msgs)
    
    session.add_message("assistant", macro_summary, {
        id = "summary_" .. os.date("%H%M%S"),
        type = "summary",
        status = "active",
        covers = ids_str
    })
    
    return "Sucesso: Blocos arquivados e resumo gerado."
end

M.update_context_md = function(content)
    if not content or content == "" then return "Erro: Conteudo vazio." end
    local root = get_repo_root()
    if not root then return "Erro: Nao foi possivel determinar a raiz do projeto." end
    local path = root .. "/CONTEXT.md"
    local lines = {}
    if vim.fn.filereadable(path) == 1 then
        lines = vim.fn.readfile(path)
    end
    table.insert(lines, "")
    for _, l in ipairs(vim.split(content, "\n", {plain=true})) do
        table.insert(lines, l)
    end
    vim.fn.writefile(lines, path)
    return "SUCESSO: CONTEXT.md atualizado em " .. path
end



return M
--------------------- ./lua/multi_context/ecosystem/injectors.lua : ---------------------
local M = {}
local api = vim.api

local function fuzzy_match(str, pattern)
    if pattern == "" then return true end
    pattern = pattern:lower():gsub(".", function(c) return c .. ".*" end)
    return str:lower():match(pattern) ~= nil
end

M.get_native_injectors = function()
    local ctx = require('multi_context.utils.context_builders')
    return {
        { name = "current_buffer", description = "Código do buffer/arquivo ativo", execute = ctx.get_current_buffer },
        { name = "buffers", description = "Código de todos os buffers abertos", execute = ctx.get_all_buffers_content },
        { name = "git_diff", description = "Alterações não commitadas", execute = ctx.get_git_diff },
        { name = "tree", description = "Árvore do diretório atual", execute = ctx.get_tree_context },
        { name = "folder", description = "Arquivos da pasta atual", execute = ctx.get_folder_context },
        { name = "repo", description = "Todos os arquivos no Git", execute = ctx.get_repo_context }
    }
end

M.get_custom_injectors = function()
    local custom = {}
    local dir = vim.fn.stdpath("config") .. "/mctx_injectors"
    if vim.fn.isdirectory(dir) == 1 then
        local files = vim.fn.globpath(dir, "*", false, true)
        for _, file in ipairs(files) do
            if file:match("%.lua$") then
                local chunk = loadfile(file)
                if chunk then
                    local ok, res = pcall(chunk)
                    if ok and type(res) == "table" and type(res.name) == "string" and type(res.execute) == "function" then
                        table.insert(custom, res)
                    end
                end
            elseif vim.fn.executable(file) == 1 then
                local name = vim.fn.fnamemodify(file, ":t:r")
                table.insert(custom, {
                    name = name,
                    description = "Injetor externo: " .. name,
                    execute = function() return vim.fn.system(vim.fn.shellescape(file)) end
                })
            end
        end
    end
    return custom
end

M.get_all_injectors = function()
    local all = {}
    for _, inj in ipairs(M.get_native_injectors()) do all[inj.name] = inj end
    for _, inj in ipairs(M.get_custom_injectors()) do all[inj.name] = inj end
    return all
end

M.selector_buf = nil; M.selector_win = nil; M.parent_win = nil
M.api_list = {}; M.filtered_list = {}; M.current_selection = 1

M.open_selector = function()
    local all = M.get_all_injectors()
    M.api_list = {}
    for k, _ in pairs(all) do table.insert(M.api_list, k) end
    table.sort(M.api_list)
    if #M.api_list == 0 then return end
    
    M.parent_win = api.nvim_get_current_win()
    M.filtered_list = vim.deepcopy(M.api_list)
    M.current_selection = 1
    
    M.selector_buf = api.nvim_create_buf(false, true)
    M.selector_win = api.nvim_open_win(M.selector_buf, true, {
        relative = "cursor", row = 1, col = 0, width = 35, height = math.min(10, #M.api_list + 2),
        style = "minimal", border = "rounded",
    })
    vim.bo[M.selector_buf].buftype = "nofile"
    
    api.nvim_buf_set_lines(M.selector_buf, 0, -1, false, { "> ", "---" })
    M._render_list()
    M._keymaps()
    
    vim.cmd("startinsert!")
    api.nvim_win_set_cursor(M.selector_win, {1, 2})
end

M._update_filter = function(query)
    M.filtered_list = {}
    for _, v in ipairs(M.api_list) do
        if fuzzy_match(v, query) then table.insert(M.filtered_list, v) end
    end
    M.current_selection = 1
    M._render_list()
end

M._render_list = function()
    if not M.selector_buf or not api.nvim_buf_is_valid(M.selector_buf) then return end
    local lines = {}
    for i, name in ipairs(M.filtered_list) do
        local cursor = (i == M.current_selection) and "❯ " or "  "
        table.insert(lines, cursor .. name)
    end
    api.nvim_buf_set_lines(M.selector_buf, 2, -1, false, lines)
    
    local ns = api.nvim_create_namespace("mc_injectors")
    api.nvim_buf_clear_namespace(M.selector_buf, ns, 2, -1)
    if #M.filtered_list > 0 then
        api.nvim_buf_add_highlight(M.selector_buf, ns, "ContextSelectorCurrent", M.current_selection + 1, 0, -1)
    end
end

M._keymaps = function()
    if not M.selector_buf or not api.nvim_buf_is_valid(M.selector_buf) then return end
    
    api.nvim_create_autocmd("TextChangedI", {
        buffer = M.selector_buf,
        callback = function()
            local line = api.nvim_buf_get_lines(M.selector_buf, 0, 1, false)[1]
            local query = line:gsub("^> %s*", ""):gsub("^>", "")
            M._update_filter(query)
        end
    })

    local function mk(k, fn) 
        api.nvim_buf_set_keymap(M.selector_buf, "i", k, "", { callback = fn, noremap = true, silent = true })
        api.nvim_buf_set_keymap(M.selector_buf, "n", k, "", { callback = fn, noremap = true, silent = true })
    end
    
    mk("<C-j>", function() M._move(1) end); mk("<Down>", function() M._move(1) end)
    mk("<C-k>", function() M._move(-1) end); mk("<Up>", function() M._move(-1) end)
    mk("<CR>", M._select)
    mk("<Esc>", M._close)
end

M._move = function(dir)
    if #M.filtered_list == 0 then return end
    local n = M.current_selection + dir
    if n >= 1 and n <= #M.filtered_list then M.current_selection = n; M._render_list() end
end

M._select = function()
    local name = M.filtered_list[M.current_selection]
    if not name then M._close(); return end
    local all = M.get_all_injectors()
    local injector = all[name]
    
    M._close_win_only()
    
    if M.parent_win and api.nvim_win_is_valid(M.parent_win) then
        api.nvim_set_current_win(M.parent_win)
        
        local content = ""
        if injector and type(injector.execute) == "function" then
            content = injector.execute() or ""
        end
        
        local target_buf = api.nvim_win_get_buf(M.parent_win)
        content = M.process_injection(content, target_buf)
        local content_lines = vim.split(content, "\n", {plain = true})
        local row, col = unpack(api.nvim_win_get_cursor(0))
        local line = api.nvim_get_current_line()
        
        local prefix = string.sub(line, 1, col + 1)
        local suffix = string.sub(line, col + 2)
        if prefix:sub(-1) == "\\" then prefix = prefix:sub(1, -2) end
        
        api.nvim_set_current_line(prefix .. suffix)
        
        api.nvim_buf_set_lines(api.nvim_win_get_buf(M.parent_win), row, row, false, content_lines)
        
        api.nvim_win_set_cursor(0, {row + #content_lines, #(content_lines[#content_lines])})
        
        vim.cmd("startinsert")
    end
end

M._close_win_only = function()
    if M.selector_win and api.nvim_win_is_valid(M.selector_win) then api.nvim_win_close(M.selector_win, true) end
    M.selector_buf = nil; M.selector_win = nil
end

M._close = function()
    M._close_win_only()
    if M.parent_win and api.nvim_win_is_valid(M.parent_win) then 
        api.nvim_set_current_win(M.parent_win)
        vim.cmd("startinsert") 
    end
end
M.process_injection = function(content_returned, bufnr)
    if type(content_returned) == "string" then
        return content_returned
    elseif type(content_returned) == "table" then
        local lines = {}
        local watchdog = require("multi_context.core.dynamic_watchdog")
        local blocks_to_dispatch = {}
        for _, item in ipairs(content_returned) do
            if item.title and item.content then
                local block_id = "inj_" .. os.date("%H%M%S") .. "_" .. tostring(math.random(1000, 9999))
                table.insert(lines, "<block id=\"" .. block_id .. "\" type=\"context_injection\">")
                table.insert(lines, "<abstract>")
                table.insert(lines, "<summary>Indexando: " .. item.title .. "...</summary>")
                table.insert(lines, "</abstract>")
                table.insert(lines, "<content>")
                for _, l in ipairs(vim.split(item.content, "\n", {plain=true})) do table.insert(lines, l) end
                table.insert(lines, "</content>")
                table.insert(lines, "</block>")
                table.insert(blocks_to_dispatch, { id = block_id, content = item.content })
            end
        end
        if #blocks_to_dispatch > 0 then
            vim.schedule(function() watchdog.dispatch_parallel_jit_tasks(bufnr, blocks_to_dispatch) end)
        end
        return table.concat(lines, "\n")
    end
    return ""
end
return M
--------------------- ./lua/multi_context/ecosystem/tool_runner.lua : ---------------------
local M = {}
local tools = require('multi_context.ecosystem.native_tools')
local StateManager = require('multi_context.core.state_manager')
local i18n = require('multi_context.i18n')

local valid_tools = {
    list_files = true, read_file = true, search_code = true,
    edit_file = true, run_shell = true, replace_lines = true, apply_diff = true,
    rewrite_chat_buffer = true, get_diagnostics = true, spawn_swarm = true, switch_agent = true,
    lsp_definition = true, lsp_references = true, lsp_document_symbols = true, git_status = true, git_branch = true, git_commit = true, get_agents_info = true, get_project_stack = true, get_git_env = true,
    read_block_content = true, archive_blocks = true
}

local allowed_commands = {"^ls", "^cat", "^npm", "^cargo", "^pytest", "^git status"}
local function is_dangerous(cmd)
    if not cmd then return false end
    if cmd:match("[;&|]") or cmd:match("`") or cmd:match("$(") then return true end
    for _, pat in ipairs(allowed_commands) do if cmd:match(pat) then return false end end
    return true
end

M.execute = function(tool_data, is_autonomous, approve_all_ref, buf)
    local name = tool_data.name
    local clean_inner = tool_data.inner

    if name == "git_push" or name == "git_reset" or name == "git_rebase" or
       (name == "run_shell" and (clean_inner:match("git push") or clean_inner:match("git reset") or clean_inner:match("git rebase"))) then
        local err_msg = i18n.t("err_git_destructive")
        local b_id = "err_" .. os.date("%H%M%S") .. "_" .. tostring(math.random(1000, 9999))
        local out = string.format('<block id="%s" type="tool_result" role="user" status="active">\n<content>\n>[Sistema]: ⛔ ERRO - %s\n</content>\n</block>', b_id, err_msg)
        return out, false, false, nil, nil
    end

    local skills_manager = require('multi_context.ecosystem.tools_manager')
    local custom_skills = skills_manager.get_tools()
    local is_custom_skill = custom_skills[name] ~= nil

    if not valid_tools[name] and not is_custom_skill then
        local err_msg = i18n.t("tool_not_found", tostring(name))
        local b_id = "err_" .. os.date("%H%M%S") .. "_" .. tostring(math.random(1000, 9999))
        local out = string.format('<block id="%s" type="tool_result" role="user" status="active">\n<content>\n>[Sistema]: ERRO - %s\n</content>\n</block>', b_id, err_msg)
        return out, false, false, nil, nil
    end

    local agents = require('multi_context.agents').load_agents()
    local active_agent = StateManager.get('react').active_agent
    local is_authorized = false

    if active_agent and agents[active_agent] and agents[active_agent].skills then
        local ontology = require('multi_context.ecosystem.ontology')
        local resolved = ontology.resolve_agent_skills(agents[active_agent].skills)
        if resolved.tools_set[name] then is_authorized = true end
    else
        is_authorized = true 
    end

    if not is_authorized then
        local err_msg = i18n.t("op_denied", tostring(active_agent), tostring(name))
        local b_id = "err_" .. os.date("%H%M%S") .. "_" .. tostring(math.random(1000, 9999))
        local out = string.format('<block id="%s" type="tool_result" role="user" status="active">\n<content>\n>[Sistema]: ⛔ ERRO - %s\n</content>\n</block>', b_id, err_msg)
        return out, false, false, nil, nil
    end

    local choice = 1
    if not approve_all_ref.value then
        if is_autonomous then
            if name == "run_shell" and is_dangerous(clean_inner) then
                vim.notify(i18n.t("danger_cmd"), vim.log.levels.ERROR)
                choice = vim.fn.confirm(i18n.t("allow_danger") .. clean_inner, i18n.t("confirm_opts"), 2)
            elseif name == "rewrite_chat_buffer" then
                choice = vim.fn.confirm(i18n.t("allow_rewrite"), i18n.t("confirm_opts"), 1)
            else choice = 3; approve_all_ref.value = true end
        else
            choice = vim.fn.confirm(i18n.t("allow_tool", tostring(name)), i18n.t("confirm_opts"), 1)
        end
    end

    if choice == 3 then approve_all_ref.value = true; choice = 1 end
    if choice == 4 or choice == 0 then
        local b_id = "err_" .. os.date("%H%M%S") .. "_" .. tostring(math.random(1000, 9999))
        local out = string.format('<block id="%s" type="tool_result" role="user" status="active">\n<content>\n>[Sistema]: Cancelado pelo usuário.\n</content>\n</block>', b_id)
        return out, true, false, nil, nil
    end

    local result = ""
    local should_continue_loop = false
    local pending_rewrite_content = nil
    local backup_made = nil

    if choice == 2 then
        result = i18n.t("denied_user")
        local b_id = "err_" .. os.date("%H%M%S") .. "_" .. tostring(math.random(1000, 9999))
        local out = string.format('<block id="%s" type="tool_result" role="user" status="active">\n<content>\n>[Sistema]: ERRO - %s\n</content>\n</block>', b_id, result)
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
            result = i18n.t("skill_err") .. tostring(skill_res)
        end
    elseif name == "rewrite_chat_buffer" then
        backup_made = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        local backup_file = vim.fn.stdpath("data") .. "/mctx_backup_" .. os.date("%Y%m%d_%H%M%S") .. ".mctx"
        vim.fn.writefile(backup_made, backup_file)
        pending_rewrite_content = clean_inner
        result = i18n.t("buf_rewritten")
    elseif name == "list_files" then 
        should_continue_loop = true; result = tools.list_files()
    elseif name == "read_file" then 
        should_continue_loop = true; result = tools.read_file(tool_data.path)
    elseif name == "search_code" then 
        should_continue_loop = true; result = tools.search_code(tool_data.query)
    elseif name == "edit_file" then 
        result = tools.edit_file(tool_data.path, clean_inner)
        if is_autonomous and result:match("SUCESSO") or result:match("SUCCESS") then result = result .. "\n\n[Auto-LSP]:\n" .. tools.get_diagnostics(tool_data.path) end
    elseif name == "run_shell" then 
        result = tools.run_shell(clean_inner)
    elseif name == "replace_lines" then 
        result = tools.replace_lines(tool_data.path, tool_data.start_line, tool_data.end_line, clean_inner)
        if is_autonomous and result:match("SUCESSO") or result:match("SUCCESS") then result = result .. "\n\n[Auto-LSP]:\n" .. tools.get_diagnostics(tool_data.path) end
    elseif name == "apply_diff" then
        result = tools.apply_diff(tool_data.path, clean_inner)
        if is_autonomous and result:match("SUCESSO") or result:match("SUCCESS") then result = result .. "\n\n[Auto-LSP]:\n" .. tools.get_diagnostics(tool_data.path) end
    elseif name == "git_status" then
        should_continue_loop = true; result = tools.git_status()
    elseif name == "git_branch" then
        local new_branch = (tool_data.inner and tool_data.inner:match("<create_new>true</create_new>")) and true or false
        local branch_name = tool_data.inner and tool_data.inner:match("<branch_name>(.-)</branch_name>") or clean_inner
        should_continue_loop = true; result = tools.git_branch(branch_name, new_branch)
    elseif name == "git_commit" then
        local files_str = tool_data.inner and tool_data.inner:match("<files>(.-)</files>") or ""
        local msg = tool_data.inner and tool_data.inner:match("<message>(.-)</message>") or clean_inner
        should_continue_loop = true; result = tools.git_commit(files_str, msg)
    elseif name == "get_agents_info" then
        should_continue_loop = true; result = tools.get_agents_info()
    elseif name == "get_project_stack" then
        should_continue_loop = true; result = tools.get_project_stack(buf)
    elseif name == "get_git_env" then
        should_continue_loop = true; result = tools.get_git_env()
    elseif name == "lsp_definition" then
        should_continue_loop = true; result = require('multi_context.ecosystem.lsp_bridge').get_definition(tool_data.path, tool_data.start_line, clean_inner)
    elseif name == "lsp_references" then
        should_continue_loop = true; result = require('multi_context.ecosystem.lsp_bridge').get_references(tool_data.path, tool_data.start_line, clean_inner)
    elseif name == "lsp_document_symbols" then
        should_continue_loop = true; result = require('multi_context.ecosystem.lsp_bridge').get_document_symbols(tool_data.path)
    elseif name == "get_diagnostics" then 
        should_continue_loop = true; result = tools.get_diagnostics(tool_data.path)
    elseif name == "read_block_content" then
        local ids = tool_data.inner and tool_data.inner:match("<target_ids>(.-)</target_ids>") or clean_inner
        should_continue_loop = true; result = tools.read_block_content(ids)
    elseif name == "archive_blocks" then
        local ids = tool_data.inner and tool_data.inner:match("<target_ids>(.-)</target_ids>") or ""
        local summary = tool_data.inner and tool_data.inner:match("<macro_summary>(.-)</macro_summary>") or clean_inner
        should_continue_loop = true; result = tools.archive_blocks(ids, summary)
    elseif name == "spawn_swarm" then
        local swarm = require('multi_context.core.swarm_manager')
        local swarm_ok, swarm_err = swarm.init_swarm(clean_inner)
        if swarm_ok then
            swarm.on_swarm_complete = require('multi_context').OnSwarmComplete
            vim.defer_fn(function() swarm.dispatch_next() end, 100)
            result = i18n.t("swarm_started")
            should_continue_loop = false
        else
            result = swarm_err or i18n.t("swarm_err_json")
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
        local block_id = "tool_" .. os.date("%H%M%S") .. "_" .. tostring(math.random(1000, 9999))
        output = string.format('<block id="%s" type="tool_result" role="user" status="active">\n<content>\n>[Sistema]: Resultado:\n```text\n%s\n```\n</content>\n</block>', block_id, result)
    end

    return output, false, should_continue_loop, pending_rewrite_content, backup_made
end

return M
--------------------- ./lua/multi_context/ecosystem/ontology.lua : ---------------------
local M = {}
M.skills_file = vim.fn.stdpath("config") .. "/mctx_semantic_skills.json"

M.load_semantic_skills = function()
    local defaults = {
        swarm_orchestration = {
            purpose = "CAPABILITY: Agentic Task Decomposition & Swarm Routing.\nTRIGGER: Use exclusively when a complex task requires multiple steps, parallel execution, or specialized knowledge.\nPROTOCOL: Inspect available agents (Workforce Matrix) and route the workload precisely. Do not hoard tasks. You are an orchestrator, not a worker.",
            tools = {"spawn_swarm", "get_agents_info"}
        },
        code_refactoring = {
            purpose = "CAPABILITY: Surgical Code Manipulation & File I/O.\nTRIGGER: Use to alter, append, or delete source code within the local file system.\nPROTOCOL: You are strictly forbidden from guessing file structures. If you do not know the exact line numbers, read the file first. Prioritize minimal `replace_lines` over full file overwrites to prevent syntax corruption and save token bandwidth.",
            tools = {"read_file", "edit_file", "replace_lines", "apply_diff"}
        },
        code_investigation = {
            purpose = "CAPABILITY: Deep Codebase Reconnaissance & Semantic RAG (LSP/Ripgrep).\nTRIGGER: Use immediately upon receiving a task to map unknowns before acting.\nPROTOCOL: Query the Language Server Protocol (LSP) for definitions and references to map blast radius before changing critical functions. Understand the OS and stack context to avoid environment conflicts.",
            tools = {"read_file", "search_code", "list_files", "get_project_stack", "lsp_definition", "lsp_references", "lsp_document_symbols"}
        },
        quality_assurance = {
            purpose = "CAPABILITY: Sandboxed Execution & Diagnostic Validation.\nTRIGGER: Use to prove code correctness dynamically.\nPROTOCOL: Run shell commands to execute test runners (pytest, jest, cargo test). Always query LSP diagnostics after a coder edits a file to ensure zero syntax regressions.",
            tools = {"run_shell", "get_diagnostics"}
        },
        git_automation = {
            purpose = "CAPABILITY: Repository State & Version Control Management.\nTRIGGER: Use to snapshot safe codebase states or branch workflows.\nPROTOCOL: Always assess the environment (`get_git_env`) for active rebases or merge conflicts before acting. Execute granular, deterministic version control operations.",
            tools = {"git_status", "git_branch", "git_commit", "get_git_env"}
        },
        manage_project_knowledge = {
            purpose = "CAPABILITY: Long Term Memory & Project Heuristics.\nTRIGGER: Use when you discover a chronic bug, make an architectural decision, or establish a new standard.\nPROTOCOL: Edit the CONTEXT.md file surgically using update_context_md.",
            tools = {"update_context_md"}
        }
    }
    if vim.fn.filereadable(M.skills_file) == 0 then
        vim.fn.writefile({vim.fn.json_encode(defaults)}, M.skills_file)
        return defaults
    end
    local file = io.open(M.skills_file, 'r')
    if not file then return defaults end
    local content = file:read('*a')
    file:close()
    local ok, parsed = pcall(vim.fn.json_decode, content)
    if not ok or type(parsed) ~= 'table' then return defaults end
    local changed = false
    for k, v in pairs(defaults) do
        if not parsed[k] then
            parsed[k] = v
            changed = true
        end
    end
    if changed then vim.fn.writefile({vim.fn.json_encode(parsed)}, M.skills_file) end
    return parsed
end
M.resolve_agent_skills = function(agent_skills_list)
    local semantics = M.load_semantic_skills()
    local resolved = { semantic_skills = {}, raw_tools = {}, tools_set = {} }
    
    for _, item in ipairs(agent_skills_list or {}) do
        if semantics[item] then
            table.insert(resolved.semantic_skills, { name = item, purpose = semantics[item].purpose })
            for _, t in ipairs(semantics[item].tools or {}) do
                if not resolved.tools_set[t] then
                    resolved.tools_set[t] = true
                    table.insert(resolved.raw_tools, t)
                end
            end
        else
            if not resolved.tools_set[item] then
                table.insert(resolved.semantic_skills, { name = item, purpose = "Direct tool access: " .. item })
                resolved.tools_set[item] = true
                table.insert(resolved.raw_tools, item)
            end
        end
    end
    return resolved
end
return M
--------------------- ./lua/multi_context/ui/controls_view.lua : ---------------------
local config = require('multi_context.config')
local i18n = require('multi_context.i18n')
local api = vim.api

local M = {}

M.state = {
    sections = {},
    apis = {}, default_api = "", fallback_mode = true,
    watchdog = {}, horizon = 4000, tolerance = 1.0,
    identity = "User", max_loops = 15,
    agents = {}, expanded_agents = {},
    semantic_skills = {}, expanded_semantic_skills = {},
    all_tools = {}, all_injectors = {}, squads = {},
    appearance = {}, history_files = {},
    api_keys_status = {}, master_prompt = "",
    debug_mode = false, clipboard_api = nil
}

M.line_map = {}
M.buf = nil; M.win = nil

M.reset_state = function()
    if M.state and M.state.sections then
        for _, s in ipairs(M.state.sections) do s.expanded = false end
    end
    M.state.expanded_agents = {}
    M.state.expanded_semantic_skills = {}
end

M.init_state = function()
    M.reset_state()
    M.state.sections = {
        { id = "apis", title = i18n.t("cc_apis_title"), desc = i18n.t("cc_apis_desc"), expanded = false },
        { id = "swarm", title = i18n.t("cc_swarm_title"), desc = i18n.t("cc_swarm_desc"), expanded = false },
        { id = "watchdog", title = i18n.t("cc_watchdog_title"), desc = i18n.t("cc_watchdog_desc"), expanded = false },
        { id = "limits", title = i18n.t("cc_limits_title"), desc = i18n.t("cc_limits_desc"), expanded = false },
        { id = "gatekeeper", title = i18n.t("cc_gatekeeper_title"), desc = i18n.t("cc_gatekeeper_desc"), expanded = false },
        { id = "semantic_skills", title = i18n.t("cc_semantic_skills_title"), desc = i18n.t("cc_semantic_skills_desc"), expanded = false },
        { id = "system_tools", title = i18n.t("cc_system_tools_title"), desc = i18n.t("cc_system_tools_desc"), expanded = false },
        { id = "injectors", title = i18n.t("cc_injectors_title"), desc = i18n.t("cc_injectors_desc"), expanded = false },
        { id = "squads", title = i18n.t("cc_squads_title"), desc = i18n.t("cc_squads_desc"), expanded = false },
        { id = "appearance", title = i18n.t("cc_app_title"), desc = i18n.t("cc_app_desc"), expanded = false },
        { id = "history", title = i18n.t("cc_history_title"), desc = i18n.t("cc_history_desc"), expanded = false },
        { id = "vault", title = i18n.t("cc_vault_title"), desc = i18n.t("cc_vault_desc"), expanded = false },
        { id = "telemetry", title = i18n.t("cc_telemetry_title"), desc = i18n.t("cc_telemetry_desc"), expanded = false }
    }
    
    local cfg = config.load_api_config() or { apis = {} }
    M.state.apis = vim.deepcopy(cfg.apis)
    M.state.default_api = cfg.default_api or ""
    M.state.fallback_mode = cfg.fallback_mode ~= false

    M.state.watchdog = vim.deepcopy(config.options.watchdog or {})
    M.state.horizon = config.options.cognitive_horizon or 4000
    M.state.tolerance = config.options.user_tolerance or 1.0
    M.state.auto_inject_context_md = config.options.auto_inject_context_md == true
    M.state.identity = config.options.user_name or "User"
    M.state.max_loops = 15
    M.state.appearance = vim.deepcopy(config.options.appearance or { width = 0.8, height = 0.8, border = "rounded" })
    M.state.debug_mode = config.options.debug_mode == true

    local agents = require('multi_context.agents')
    M.state.agents = agents.load_agents() or {}
    
    local ontology = require('multi_context.ecosystem.ontology')
    pcall(function() M.state.semantic_skills = ontology.load_semantic_skills() or {} end)

    local skills_mgr = require('multi_context.ecosystem.tools_manager')
    pcall(skills_mgr.load_tools)
    M.state.all_tools = skills_mgr.get_tools() or {}
    
    local native_tools = {"list_files", "read_file", "search_code", "edit_file", "run_shell", "replace_lines", "apply_diff", "rewrite_chat_buffer", "get_diagnostics", "spawn_swarm", "switch_agent", "lsp_definition", "lsp_references", "lsp_document_symbols", "git_status", "git_branch", "git_commit", "deep_dive", "update_context_md", "update_context_md"}
    for _, t in ipairs(native_tools) do M.state.all_tools[t] = { name = t, is_native = true } end
    
    local injectors_mgr = require('multi_context.ecosystem.injectors')
    M.state.all_injectors = injectors_mgr.get_all_injectors() or {}
    for _, inj in ipairs(injectors_mgr.get_native_injectors()) do
        if M.state.all_injectors[inj.name] then M.state.all_injectors[inj.name].is_native = true end
    end
    
    local squads_mgr = require('multi_context.ecosystem.squads')
    pcall(function() M.state.squads = squads_mgr.load_squads() or {} end)
    
    local root = vim.fn.system("git rev-parse --show-toplevel")
    if vim.v.shell_error == 0 then root = root:gsub("\n", "") else root = vim.fn.getcwd() end
    local chat_dir = root .. "/.mctx_chats"
    M.state.history_files = {}
    if vim.fn.isdirectory(chat_dir) == 1 then
        local files = vim.fn.split(vim.fn.system("ls -1t " .. vim.fn.shellescape(chat_dir)), "\n")
        for i, f in ipairs(files) do
            if i > 10 then break end
            if f:match("%.mctx$") then table.insert(M.state.history_files, f) end
        end
    end

    M.state.api_keys_status = {}
    local keys = config.load_api_keys() or {}
    for _, api_cfg in ipairs(M.state.apis) do
        local k = keys[api_cfg.name]
        if k and k ~= "" and not k:match("^sk%-%.%.%.") and not k:match("^AIzaSy%.%.%.") and not k:match("^sk%-ant%-%.%.%.") then
            M.state.api_keys_status[api_cfg.name] = i18n.t("cc_configured")
        else
            M.state.api_keys_status[api_cfg.name] = i18n.t("cc_missing")
        end
    end
    M.state.master_prompt = cfg.master_prompt or config.options.master_prompt or "Você é um Engenheiro de Software Autônomo no Neovim."
end

M.toggle_section = function(idx)
    if M.state.sections[idx] then M.state.sections[idx].expanded = not M.state.sections[idx].expanded end
end

M.get_footer_hint = function(action)
    if not action then return i18n.t("cc_hint_default") end
    local t = action.type
    if t == "section" or t == "agent_expand" or t == "semantic_skill_expand" then return i18n.t("cc_hint_expand") end
    if t == "toggle_fallback" or t == "api_spawn" or t == "api_bg_pool" or t == "agent_skill_toggle" or t == "semantic_skill_tool_toggle" or t == "api_select" or t == "wd_mode" or t == "wd_strategy" or t == "wd_bg_api" or t == "toggle_debug" or t == "api_level_swarm" or t == "app_border" then
        return i18n.t("cc_hint_toggle")
    end
    if t == "wd_horizon" or t == "wd_tolerance" or t == "wd_percent" or t == "wd_fixed" or t == "limit_identity" or t == "limit_loops" or t == "agent_level" or t == "app_width" or t == "app_height" or t == "edit_master_prompt" then
        return i18n.t("cc_hint_edit_val")
    end
    if t == "edit_tool" or t == "edit_injector" or t == "edit_squad" or t == "edit_vault" then 
        return i18n.t("cc_hint_edit_src") 
    end
    if t == "create_agent" or t == "create_tool" or t == "create_semantic_skill" or t == "create_injector" or t == "create_squad" or t == "load_history" or t == "edit_agent_prompt" or t == "delete_agent" or t == "edit_semantic_skill_prompt" or t == "delete_semantic_skill" then 
        return i18n.t("cc_hint_cr") 
    end
    return i18n.t("cc_hint_default")
end

M.update_footer = function(cursor_line)
    if not M.win or not api.nvim_win_is_valid(M.win) then return end
    local action = M.line_map[cursor_line]
    local hint = M.get_footer_hint(action)
    
    if vim.fn.has("nvim-0.10") == 1 then
        pcall(api.nvim_win_set_config, M.win, { footer = " " .. vim.trim(hint) .. " ", footer_pos = "center" })
    else
        vim.bo[M.buf].modifiable = true
        local last = api.nvim_buf_line_count(M.buf)
        api.nvim_buf_set_lines(M.buf, last - 1, last, false, { hint })
        vim.bo[M.buf].modifiable = false
    end
end

local function format_row(label, value, total_width)
    local label_len = vim.fn.strdisplaywidth(label)
    local value_len = vim.fn.strdisplaywidth(value)
    local dots_len = total_width - label_len - value_len - 2
    if dots_len < 1 then dots_len = 1 end
    return label .. " " .. string.rep("·", dots_len) .. " " .. value
end

local function add_line(lines, text, action) table.insert(lines, text); if action then M.line_map[#lines] = action end end

M.render = function()
    M.line_map = {}
    local lines = {}
    local w = 62

    add_line(lines, "", nil)

    for s_idx, sec in ipairs(M.state.sections) do
        local prefix = sec.expanded and "[-] " or "[+] "
        add_line(lines, prefix .. (sec.title or ""), { type = "section", idx = s_idx })
        
        if not sec.expanded and sec.desc then
            add_line(lines, "    " .. sec.desc, nil)
            add_line(lines, "", nil)
        elseif sec.expanded then
            if sec.id == "apis" then
                add_line(lines, format_row(i18n.t("cc_fallback_motor"), M.state.fallback_mode and "[ ON ]" or "[ OFF ]", w), { type = "toggle_fallback" })
                add_line(lines, i18n.t("cc_providers_list"), nil)
                for i, a in ipairs(M.state.apis) do
                    local mark = (a.name == M.state.default_api) and "[ ✓ ]" or "[   ]"
                    add_line(lines, format_row("    ├─ " .. a.name, mark, w), { type = "api_select", name = a.name, idx = i })
                    local bg_mark = a.allow_background and "[ ON ]" or "[ OFF ]"
                    add_line(lines, format_row("      └─ " .. i18n.t("cc_bg_pool_title"), bg_mark, w), { type = "api_bg_pool", idx = i })
                                    end
            elseif sec.id == "swarm" then
                add_line(lines, i18n.t("cc_swarm_perm"), nil)
                for i, a in ipairs(M.state.apis) do
                    local mark = a.allow_spawn and "[ ON ]" or "[ OFF ]"
                    add_line(lines, format_row("    " .. i .. ". " .. a.name, mark, w), { type = "api_spawn", idx = i })
                    add_line(lines, format_row("      └─ Abstraction Level", "[ " .. (a.abstraction_level or "medium") .. " ]", w), { type = "api_level_swarm", idx = i })
                end
            elseif sec.id == "watchdog" then
                local wd = M.state.watchdog
                local m_disp = wd.mode and (wd.mode:sub(1,1):upper() .. wd.mode:sub(2)) or "Off"
                add_line(lines, format_row(i18n.t("cc_wd_status"), "[ " .. m_disp .. " ]", w), { type = "wd_mode" })
                add_line(lines, format_row(i18n.t("cc_wd_trigger"), M.state.horizon .. " tokens", w), { type = "wd_horizon" })
                add_line(lines, format_row(i18n.t("cc_wd_tolerance"), tostring(M.state.tolerance), w), { type = "wd_tolerance" })
                add_line(lines, "", nil)
                
                local strat = "Semântico"
                if wd.strategy == "percent" then strat = "Percentual" elseif wd.strategy == "fixed" then strat = "Fixo" elseif wd.strategy == "dynamic" then strat = "Dinâmico" end
                add_line(lines, format_row(i18n.t("cc_wd_strategy"), "[ " .. strat .. " ]", w), { type = "wd_strategy" })
                
                if wd.strategy == "percent" then
                    add_line(lines, format_row(i18n.t("cc_wd_percent"), math.floor((wd.percent or 0.3) * 100) .. "%", w), { type = "wd_percent" })
                elseif wd.strategy == "fixed" then
                    add_line(lines, format_row(i18n.t("cc_wd_fixed"), (wd.fixed_target or 1500) .. " tokens", w), { type = "wd_fixed" })
                elseif wd.strategy == "dynamic" then
                    local bg_api = wd.background_api or "[ Selecione ]"
                    add_line(lines, format_row("      └─ Background API", "[ " .. bg_api .. " ]", w), { type = "wd_bg_api" })
                end
            elseif sec.id == "limits" then
                add_line(lines, format_row(i18n.t("cc_limit_id"), "[ " .. M.state.identity .. " ]", w), { type = "limit_identity" })
                add_line(lines, format_row(i18n.t("cc_limit_loops"), M.state.max_loops, w), { type = "limit_loops" })
                add_line(lines, format_row(i18n.t("cc_auto_inject_ctx"), M.state.auto_inject_context_md and "[ ON ]" or "[ OFF ]", w), { type = "toggle_auto_inject" })
            elseif sec.id == "gatekeeper" then
                add_line(lines, i18n.t("cc_gk_hint"), nil)
                local agent_names = {}
                for n, _ in pairs(M.state.agents) do table.insert(agent_names, n) end
                table.sort(agent_names)

                local sem_skills_keys = {}
                for sk, _ in pairs(M.state.semantic_skills) do table.insert(sem_skills_keys, sk) end
                table.sort(sem_skills_keys)

                for _, ag_name in ipairs(agent_names) do
                    local is_exp = M.state.expanded_agents[ag_name]
                    add_line(lines, "    " .. (is_exp and "[-] " or "[+] ") .. ag_name, { type = "agent_expand", name = ag_name })
                    if is_exp then
                        local ag_data = M.state.agents[ag_name]
                        local ag_skills = ag_data.skills or {}
                        
                        for _, sn in ipairs(sem_skills_keys) do
                            local has_skill = vim.tbl_contains(ag_skills, sn)
                            add_line(lines, format_row("      ├─ " .. sn, has_skill and "[ ✓ ]" or "[   ]", w), { type = "agent_skill_toggle", agent = ag_name, skill = sn })
                        end
                        add_line(lines, format_row("      ├─ Abstraction Level", "[ " .. (ag_data.abstraction_level or "high") .. " ]", w), { type = "agent_level", name = ag_name })
                        add_line(lines, i18n.t("cc_edit_sys_prompt"), { type = "edit_agent_prompt", name = ag_name })
                        add_line(lines, i18n.t("cc_delete_agent"), { type = "delete_agent", name = ag_name })
                    end
                end
                add_line(lines, i18n.t("cc_create_agent"), { type = "create_agent" })
            
            elseif sec.id == "semantic_skills" then
                local sem_skills_keys = {}
                for sk, _ in pairs(M.state.semantic_skills) do table.insert(sem_skills_keys, sk) end
                table.sort(sem_skills_keys)

                local tool_names = {}
                for tn, _ in pairs(M.state.all_tools) do table.insert(tool_names, tn) end
                table.sort(tool_names)

                for _, sn in ipairs(sem_skills_keys) do
                    local is_exp = M.state.expanded_semantic_skills[sn]
                    add_line(lines, "    " .. (is_exp and "[-] " or "[+] ") .. sn, { type = "semantic_skill_expand", name = sn })
                    if is_exp then
                        local sk_data = M.state.semantic_skills[sn]
                        local purpose = sk_data.purpose or ""
                        local trunc_purpose = purpose:sub(1, 40):gsub("\n", " ") .. "..."
                        add_line(lines, format_row("      ├─ Purpose", trunc_purpose, w), nil)
                        add_line(lines, i18n.t("cc_edit_skill_purpose"), { type = "edit_semantic_skill_prompt", name = sn })
                        add_line(lines, i18n.t("cc_delete_skill"), { type = "delete_semantic_skill", name = sn })
                        add_line(lines, "      ├─ Tools:", nil)
                        
                        for _, tn in ipairs(tool_names) do
                            local has_tool = vim.tbl_contains(sk_data.tools or {}, tn)
                            add_line(lines, format_row("        ├─ " .. tn, has_tool and "[ ✓ ]" or "[   ]", w), { type = "semantic_skill_tool_toggle", skill = sn, tool = tn })
                        end
                    end
                end
                add_line(lines, i18n.t("cc_create_semantic_skill"), { type = "create_semantic_skill" })
                
            elseif sec.id == "system_tools" then
                add_line(lines, i18n.t("cc_system_tools_hint"), nil)
                local tool_names = {}
                for tn, _ in pairs(M.state.all_tools) do table.insert(tool_names, tn) end
                table.sort(tool_names)
                
                for _, tn in ipairs(tool_names) do
                    local tl = M.state.all_tools[tn]
                    add_line(lines, format_row("    ├─ " .. tn, tl.is_native and "[ " .. i18n.t("cc_native_f") .. " ]" or "[ " .. i18n.t("cc_custom") .. " ]", w), { type = "edit_tool", name = tn })
                end
                add_line(lines, i18n.t("cc_create_tool"), { type = "create_tool" })

            elseif sec.id == "injectors" then
                add_line(lines, i18n.t("cc_inj_hint"), nil)
                local inj_names = {}
                for iname, _ in pairs(M.state.all_injectors) do table.insert(inj_names, iname) end
                table.sort(inj_names)
                
                for _, iname in ipairs(inj_names) do
                    local inj = M.state.all_injectors[iname]
                    add_line(lines, format_row("    ├─ " .. iname, inj.is_native and "[ " .. i18n.t("cc_native_m") .. " ]" or "[ " .. i18n.t("cc_custom") .. " ]", w), { type = "edit_injector", name = iname })
                end
                add_line(lines, i18n.t("cc_create_inj"), { type = "create_injector" })
            elseif sec.id == "squads" then
                add_line(lines, i18n.t("cc_sq_hint"), nil)
                local sq_names = {}
                for sn, _ in pairs(M.state.squads) do table.insert(sq_names, sn) end
                table.sort(sq_names)
                
                for _, sn in ipairs(sq_names) do
                    local sq = M.state.squads[sn]
                    add_line(lines, format_row("    ├─ @" .. sn, "[ " .. i18n.t("cc_squad") .. " ]", w), { type = "edit_squad", name = sn })
                    if sq.tasks then
                        for _, t in ipairs(sq.tasks) do
                            local chain_str = t.agent or "tech_lead"
                            if type(t.chain) == "table" and #t.chain > 0 then chain_str = chain_str .. " ➔ " .. table.concat(t.chain, " ➔ ") end
                            add_line(lines, "      └─ " .. chain_str, nil)
                        end
                    end
                end
                add_line(lines, i18n.t("cc_create_squad"), { type = "create_squad" })
            elseif sec.id == "appearance" then
                local app = M.state.appearance
                add_line(lines, format_row(i18n.t("cc_app_width"), tostring(app.width), w), { type = "app_width" })
                add_line(lines, format_row(i18n.t("cc_app_height"), tostring(app.height), w), { type = "app_height" })
                add_line(lines, format_row(i18n.t("cc_app_border"), "[ " .. (app.border or "rounded") .. " ]", w), { type = "app_border" })
            elseif sec.id == "history" then
                add_line(lines, i18n.t("cc_hist_hint"), nil)
                if #M.state.history_files == 0 then
                    add_line(lines, i18n.t("cc_hist_none"), nil)
                else
                    for _, f in ipairs(M.state.history_files) do
                        add_line(lines, format_row("    ├─ " .. f, "[ " .. i18n.t("cc_load") .. " ]", w), { type = "load_history", file = f })
                    end
                end
            elseif sec.id == "vault" then
                add_line(lines, i18n.t("cc_vault_hint"), nil)
                for _, a in ipairs(M.state.apis) do
                    local st = M.state.api_keys_status[a.name] or i18n.t("cc_missing")
                    add_line(lines, format_row("    ├─ " .. a.name, "[ " .. st .. " ]", w), { type = "edit_vault" })
                end
                add_line(lines, "", nil)
                add_line(lines, format_row(i18n.t("cc_master_prompt"), "[ " .. i18n.t("cc_edit") .. " ]", w), { type = "edit_master_prompt" })
            elseif sec.id == "telemetry" then
                add_line(lines, format_row(i18n.t("cc_telemetry_log"), M.state.debug_mode and "[ ON ]" or "[ OFF ]", w), { type = "toggle_debug" })
            end
            add_line(lines, "", nil)
        end
    end

    while #lines < 22 do table.insert(lines, "") end
    if vim.fn.has("nvim-0.10") == 0 then
        table.insert(lines, string.rep("─", w + 2))
        table.insert(lines, " ")
    end
    return lines
end

M.update_buffer = function()
    if not M.buf or not api.nvim_buf_is_valid(M.buf) then return end
    vim.bo[M.buf].modifiable = true
    api.nvim_buf_set_lines(M.buf, 0, -1, false, M.render())
    vim.bo[M.buf].modifiable = false
    vim.bo[M.buf].modified = false
    pcall(function() require('multi_context.ui.highlights').apply_controls(M.buf) end)
    pcall(function() M.update_footer(api.nvim_win_get_cursor(M.win)[1]) end)
end

M._edit_agent_prompt = function(name)
    local ag = M.state.agents[name]
    if not ag then return end
    local tmp_path = vim.fn.stdpath("data") .. "/mctx_agent_" .. name .. "_" .. os.date("%H%M%S") .. ".md"
    vim.fn.writefile(vim.split(ag.system_prompt or "", "\n"), tmp_path)
    
    pcall(api.nvim_win_close, M.win, true)
    vim.cmd("edit " .. tmp_path)
    
    api.nvim_create_autocmd("BufWritePost", {
        buffer = api.nvim_get_current_buf(),
        callback = function()
            local lines = vim.fn.readfile(tmp_path)
            local agents = require('multi_context.agents').load_agents()
            if agents[name] then
                agents[name].system_prompt = table.concat(lines, "\n")
                local agents_file = vim.fn.stdpath("config") .. "/mctx_agents.json"
                vim.fn.writefile({vim.fn.json_encode(agents)}, agents_file)
                vim.notify(i18n.t("cc_sys_prompt_updated", name), vim.log.levels.INFO)
            end
        end
    })
end

M._edit_skill_prompt = function(name)
    local sk = M.state.semantic_skills[name]
    if not sk then return end
    local tmp_path = vim.fn.stdpath("data") .. "/mctx_skill_" .. name .. "_" .. os.date("%H%M%S") .. ".txt"
    vim.fn.writefile(vim.split(sk.purpose or "", "\n"), tmp_path)
    pcall(api.nvim_win_close, M.win, true)
    vim.cmd("edit " .. tmp_path)
    
    api.nvim_create_autocmd("BufWritePost", {
        buffer = api.nvim_get_current_buf(),
        callback = function()
            local lines = vim.fn.readfile(tmp_path)
            local ontology = require('multi_context.ecosystem.ontology')
            local skills_v2 = ontology.load_semantic_skills()
            if skills_v2[name] then
                skills_v2[name].purpose = table.concat(lines, "\n")
                local skills_file = vim.fn.stdpath("config") .. "/mctx_semantic_skills.json"
                vim.fn.writefile({vim.fn.json_encode(skills_v2)}, skills_file)
                vim.notify(i18n.t("cc_sys_prompt_updated", name), vim.log.levels.INFO)
            end
        end
    })
end

M.handle_cr = function()
    local action = M.line_map[api.nvim_win_get_cursor(0)[1]]
    if not action then return end
    
    if action.type == "section" then 
        M.toggle_section(action.idx); M.update_buffer()
    elseif action.type == "agent_expand" then 
        M.state.expanded_agents[action.name] = not M.state.expanded_agents[action.name]; M.update_buffer()
    elseif action.type == "semantic_skill_expand" then 
        M.state.expanded_semantic_skills[action.name] = not M.state.expanded_semantic_skills[action.name]; M.update_buffer()
    elseif action.type == "delete_agent" then
        local choice = vim.fn.confirm(i18n.t("cc_delete_agent_prompt", action.name), i18n.t("cc_yes") .. "\n" .. i18n.t("cc_no"), 2)
        if choice == 1 then
            M.state.agents[action.name] = nil; M.state.expanded_agents[action.name] = nil
            M.save_config(); vim.notify(i18n.t("cc_deleted"), vim.log.levels.INFO); M.update_buffer()
        end
    elseif action.type == "delete_semantic_skill" then
        local choice = vim.fn.confirm(i18n.t("cc_delete_skill_prompt", action.name), i18n.t("cc_yes") .. "\n" .. i18n.t("cc_no"), 2)
        if choice == 1 then
            M.state.semantic_skills[action.name] = nil; M.state.expanded_semantic_skills[action.name] = nil
            M.save_config(); vim.notify(i18n.t("cc_deleted"), vim.log.levels.INFO); M.update_buffer()
        end
    elseif action.type == "edit_agent_prompt" then
        M._edit_agent_prompt(action.name)
    elseif action.type == "edit_semantic_skill_prompt" then
        M._edit_skill_prompt(action.name)
    elseif action.type == "create_tool" then
        vim.ui.input({ prompt = i18n.t("cc_create_skill_pmpt") }, function(input)
            if not input or input == "" then return end
            input = input:gsub("%.lua$", "")
            local dir = vim.fn.stdpath("config") .. "/mctx_tools"
            if vim.fn.isdirectory(dir) == 0 then vim.fn.mkdir(dir, "p") end
            local path = dir .. "/" .. input .. ".lua"
            
            local boilerplate = {
                "return {",
                "    name = '" .. input .. "',",
                "    description = '" .. i18n.t("cc_skill_desc_ph") .. "',",
                "    parameters = {",
                "        { name = 'arg1', type = 'string', required = true, desc = '" .. i18n.t("cc_skill_arg_ph") .. "' }",
                "    },",
                "    execute = function(args)",
                "        return '" .. i18n.t("cc_skill_res_ph") .. "'",
                "    end",
                "}"
            }
            vim.fn.writefile(boilerplate, path)
            pcall(api.nvim_win_close, M.win, true)
            vim.cmd("edit " .. path)
            vim.notify(i18n.t("cc_skill_created"), vim.log.levels.INFO)
        end)
    elseif action.type == "create_injector" then
        vim.ui.input({ prompt = i18n.t("cc_create_inj_pmpt") }, function(input)
            if not input or input == "" then return end
            input = input:gsub("%.lua$", "")
            local dir = vim.fn.stdpath("config") .. "/mctx_injectors"
            if vim.fn.isdirectory(dir) == 0 then vim.fn.mkdir(dir, "p") end
            local path = dir .. "/" .. input .. ".lua"
            local boilerplate = {
                "return {", "    name = '" .. input .. "',", "    description = '" .. i18n.t("cc_inj_desc_ph") .. "',",
                "    execute = function()", "        return '" .. i18n.t("cc_inj_res_ph") .. "'", "    end", "}"
            }
            vim.fn.writefile(boilerplate, path)
            pcall(api.nvim_win_close, M.win, true)
            vim.cmd("edit " .. path)
            vim.notify(i18n.t("cc_inj_created"), vim.log.levels.INFO)
        end)
    elseif action.type == "create_agent" then
        vim.ui.input({ prompt = i18n.t("cc_create_agent_pmpt") }, function(input)
            if not input or input == "" then return end
            if not M.state.agents[input] then
                M.state.agents[input] = { system_prompt = i18n.t("cc_agent_sys_ph"), abstraction_level = "high", skills = {} }
                M.save_config(); vim.notify(i18n.t("cc_create_agent_notify", input), vim.log.levels.INFO); M.update_buffer()
            end
        end)
    elseif action.type == "create_semantic_skill" then
        vim.ui.input({ prompt = i18n.t("cc_create_semantic_skill_pmpt") }, function(input)
            if not input or input == "" then return end
            if not M.state.semantic_skills[input] then
                M.state.semantic_skills[input] = { purpose = "Nova Skill Semântica / New Semantic Skill", tools = {} }
                M.save_config(); vim.notify(string.format(i18n.t("cc_semantic_skill_created"), input), vim.log.levels.INFO); M.update_buffer()
            end
        end)
    elseif action.type == "create_squad" then
        vim.ui.input({ prompt = i18n.t("cc_create_squad_pmpt") }, function(input)
            if not input or input == "" then return end
            if not M.state.squads[input] then
                M.state.squads[input] = { description = "Novo esquadrão / New squad", tasks = { { agent = "tech_lead", instruction = "Instrução inicial", chain = {"coder"} } } }
                local squads_file = vim.fn.stdpath("config") .. "/mctx_squads.json"
                vim.fn.writefile({vim.fn.json_encode(M.state.squads)}, squads_file)
                vim.notify(i18n.t("cc_squad_created", input), vim.log.levels.INFO)
                M.update_buffer()
            end
        end)
    elseif action.type == "load_history" then
        local root = vim.fn.system("git rev-parse --show-toplevel")
        if vim.v.shell_error == 0 then root = root:gsub("\n", "") else root = vim.fn.getcwd() end
        local filepath = root .. "/.mctx_chats/" .. action.file
        if vim.fn.filereadable(filepath) == 1 then
            pcall(api.nvim_win_close, M.win, true)
            vim.cmd("edit " .. filepath)
            require('multi_context.utils.utils').load_workspace_state(api.nvim_get_current_buf())
            require('multi_context.ui.chat_view').create_popup(api.nvim_get_current_buf())
        end
    end
end

M.handle_space = function()
    local action = M.line_map[api.nvim_win_get_cursor(0)[1]]
    if not action then return end

    if action.type == "api_select" then M.state.default_api = action.name
    elseif action.type == "toggle_fallback" then M.state.fallback_mode = not M.state.fallback_mode
    elseif action.type == "api_bg_pool" then M.state.apis[action.idx].allow_background = not M.state.apis[action.idx].allow_background
        elseif action.type == "api_spawn" then M.state.apis[action.idx].allow_spawn = not M.state.apis[action.idx].allow_spawn
    elseif action.type == "api_level_swarm" then
        local cycles = { high = "medium", medium = "low", low = "high" }
        local ap = M.state.apis[action.idx]
        ap.abstraction_level = cycles[ap.abstraction_level or "medium"] or "medium"
    elseif action.type == "wd_mode" then
        local cycles = { off = "ask", ask = "auto", auto = "off" }
        M.state.watchdog.mode = cycles[M.state.watchdog.mode or "off"] or "off"
    elseif action.type == "wd_strategy" then
        local cycles = { semantic = "percent", percent = "fixed", fixed = "dynamic", dynamic = "semantic" }
        M.state.watchdog.strategy = cycles[M.state.watchdog.strategy or "semantic"] or "semantic"
    elseif action.type == "wd_bg_api" then
        local apis = M.state.apis
        if #apis > 0 then
            local curr_idx = 0
            for i, a in ipairs(apis) do if a.name == M.state.watchdog.background_api then curr_idx = i; break end end
            local next_idx = (curr_idx % #apis) + 1
            M.state.watchdog.background_api = apis[next_idx].name
        end
    elseif action.type == "agent_skill_toggle" then
        local ag = M.state.agents[action.agent]
        if not ag.skills then ag.skills = {} end
        local found_idx = nil
        for i, s in ipairs(ag.skills) do if s == action.skill then found_idx = i; break end end
        if found_idx then table.remove(ag.skills, found_idx) else table.insert(ag.skills, action.skill) end
    elseif action.type == "semantic_skill_tool_toggle" then
        local sk = M.state.semantic_skills[action.skill]
        if not sk.tools then sk.tools = {} end
        local found_idx = nil
        for i, t in ipairs(sk.tools) do if t == action.tool then found_idx = i; break end end
        if found_idx then table.remove(sk.tools, found_idx) else table.insert(sk.tools, action.tool) end
    elseif action.type == "app_border" then
        local borders = { rounded = "single", single = "double", double = "solid", solid = "shadow", shadow = "none", none = "rounded" }
        M.state.appearance.border = borders[M.state.appearance.border or "rounded"] or "rounded"
    elseif action.type == "toggle_auto_inject" then
        M.state.auto_inject_context_md = not M.state.auto_inject_context_md
    elseif action.type == "toggle_debug" then
        M.state.debug_mode = not M.state.debug_mode
    end
    M.update_buffer()
end

M.handle_edit = function()
    local action = M.line_map[api.nvim_win_get_cursor(0)[1]]
    if not action then return end

    local function prompt_str(msg, callback)
        vim.ui.input({ prompt = msg }, function(input) if input and input ~= "" then callback(input); M.update_buffer() end end)
    end
    local function prompt_num(msg, callback) prompt_str(msg, function(i) local n = tonumber(i); if n then callback(n) end end) end

    if action.type == "wd_horizon" then prompt_num(i18n.t("cc_prompt_wd_horizon"), function(n) M.state.horizon = n end)
    elseif action.type == "wd_tolerance" then prompt_num(i18n.t("cc_prompt_wd_tolerance"), function(n) M.state.tolerance = n end)
    elseif action.type == "wd_percent" then prompt_num(i18n.t("cc_prompt_wd_percent"), function(n) M.state.watchdog.percent = n / 100 end)
    elseif action.type == "wd_fixed" then prompt_num(i18n.t("cc_prompt_wd_fixed"), function(n) M.state.watchdog.fixed_target = n end)
    elseif action.type == "limit_identity" then prompt_str(i18n.t("cc_prompt_identity"), function(s) M.state.identity = s end)
    elseif action.type == "limit_loops" then prompt_num(i18n.t("cc_prompt_loops"), function(n) M.state.max_loops = n end)
    elseif action.type == "agent_level" then
        local cycles = { high = "medium", medium = "low", low = "high" }
        local ag = M.state.agents[action.name]
        ag.abstraction_level = cycles[ag.abstraction_level or "high"] or "high"
        M.update_buffer()
    elseif action.type == "app_width" then prompt_num(i18n.t("cc_prompt_width"), function(n) M.state.appearance.width = n end)
    elseif action.type == "app_height" then prompt_num(i18n.t("cc_prompt_height"), function(n) M.state.appearance.height = n end)
    elseif action.type == "edit_master_prompt" then prompt_str(i18n.t("cc_prompt_master"), function(s) M.state.master_prompt = s end)
    end
end

M.handle_open_file = function()
    local action = M.line_map[api.nvim_win_get_cursor(0)[1]]
    if not action then return end
    
    if action.type == "agent_expand" or action.type == "edit_agent_prompt" then
        M._edit_agent_prompt(action.name)
        return
    elseif action.type == "semantic_skill_expand" or action.type == "edit_semantic_skill_prompt" then
        M._edit_skill_prompt(action.name)
        return
    end

    local path = nil
    if action.type == "edit_tool" then
        if M.state.all_tools[action.name].is_native then
            vim.notify(i18n.t("cc_core_tool_warn"), vim.log.levels.WARN); return
        end
        path = vim.fn.stdpath("config") .. "/mctx_tools/" .. action.name .. ".lua"
    elseif action.type == "edit_injector" then
        if M.state.all_injectors[action.name].is_native then
            vim.notify(i18n.t("cc_core_inj_warn"), vim.log.levels.WARN); return
        end
        path = vim.fn.stdpath("config") .. "/mctx_injectors/" .. action.name .. ".lua"
    elseif action.type == "edit_squad" then
        path = vim.fn.stdpath("config") .. "/mctx_squads.json"
    elseif action.type == "edit_vault" then
        path = config.options.api_keys_path
    end
    
    if path and vim.fn.filereadable(path) == 1 then
        pcall(api.nvim_win_close, M.win, true)
        vim.cmd("edit " .. path)
    end
end

M.handle_dd = function()
    local action = M.line_map[api.nvim_win_get_cursor(0)[1]]
    if action and (action.type == "api_select" or action.type == "api_spawn") then
        M.state.clipboard_api = table.remove(M.state.apis, action.idx); M.update_buffer()
    end
end

M.handle_p = function()
    if not M.state.clipboard_api then return end
    local action = M.line_map[api.nvim_win_get_cursor(0)[1]]
    local idx = #M.state.apis + 1
    if action and (action.type == "api_select" or action.type == "api_spawn") then idx = action.idx + 1 end
    table.insert(M.state.apis, idx, M.state.clipboard_api)
    M.state.clipboard_api = nil; M.update_buffer()
end

M.save_config = function()
    local cfg = config.load_api_config() or { apis = {} }
    cfg.apis = M.state.apis
    cfg.default_api = M.state.default_api
    cfg.fallback_mode = M.state.fallback_mode
    
    cfg.watchdog = vim.deepcopy(M.state.watchdog)
    cfg.cognitive_horizon = M.state.horizon
    cfg.user_tolerance = M.state.tolerance
    cfg.auto_inject_context_md = M.state.auto_inject_context_md
    cfg.appearance = vim.deepcopy(M.state.appearance)
    cfg.master_prompt = M.state.master_prompt
    cfg.debug_mode = M.state.debug_mode
    config.save_api_config(cfg)
    
    config.options.user_name = M.state.identity
    config.options.appearance = vim.deepcopy(M.state.appearance)
    config.options.master_prompt = M.state.master_prompt
    config.options.debug_mode = M.state.debug_mode
    config.options.watchdog = vim.deepcopy(M.state.watchdog)
    config.options.cognitive_horizon = M.state.horizon
    config.options.user_tolerance = M.state.tolerance
    config.options.auto_inject_context_md = M.state.auto_inject_context_md
    
    local agents_file = vim.fn.stdpath("config") .. "/mctx_agents.json"
    local raw_json = vim.fn.json_encode(M.state.agents)
    vim.fn.writefile({raw_json}, agents_file)
    pcall(function() vim.fn.system(string.format("echo %s | jq . > %s", vim.fn.shellescape(raw_json), agents_file)) end)

    local skills_file = vim.fn.stdpath("config") .. "/mctx_semantic_skills.json"
    local raw_skills = vim.fn.json_encode(M.state.semantic_skills)
    vim.fn.writefile({raw_skills}, skills_file)
    pcall(function() vim.fn.system(string.format("echo %s | jq . > %s", vim.fn.shellescape(raw_skills), skills_file)) end)

    M._last_saved_cfg = cfg
    vim.notify(i18n.t("cc_saved"), vim.log.levels.INFO)
end

M.open_panel = function()
    M.init_state()
    for _, b in ipairs(api.nvim_list_bufs()) do if api.nvim_buf_get_name(b):match("MultiContext_Controls$") then pcall(api.nvim_buf_delete, b, { force = true }) end end
    M.buf = api.nvim_create_buf(false, true)
    vim.bo[M.buf].buftype = 'acwrite'
    vim.bo[M.buf].bufhidden = 'wipe'
    vim.bo[M.buf].swapfile = false
    api.nvim_buf_set_name(M.buf, "MultiContext_Controls")
    
    local w, h = 76, 28
    local win_opts = { relative = 'editor', width = w, height = h, row = math.floor((vim.o.lines - h) / 2), col = math.floor((vim.o.columns - w) / 2), border = 'rounded', style = 'minimal' }
    
    if vim.fn.has("nvim-0.9") == 1 then win_opts.title = " MultiContext AI 🤖[v1.4] "; win_opts.title_pos = "center" end
    
    M.win = api.nvim_open_win(M.buf, true, win_opts)
    vim.wo[M.win].cursorline = true; vim.wo[M.win].wrap = false; vim.wo[M.win].number = true; vim.wo[M.win].relativenumber = true
    M.update_buffer()
    
    local km = { noremap = true, silent = true }
    local function map(k, f) api.nvim_buf_set_keymap(M.buf, "n", k, "", { callback = f, noremap = true, silent = true }) end
    
    map("<CR>", M.handle_cr); map("<Space>", M.handle_space); map("c", M.handle_edit); map("e", M.handle_open_file); map("dd", M.handle_dd); map("p", M.handle_p)
    api.nvim_buf_set_keymap(M.buf, "n", "q", ":q!<CR>", km)
    
    api.nvim_create_autocmd("BufWriteCmd", { buffer = M.buf, callback = M.save_config })
    api.nvim_create_autocmd("CursorMoved", { buffer = M.buf, callback = function() if not api.nvim_buf_is_valid(M.buf) or not api.nvim_win_is_valid(M.win) then return end; M.update_footer(api.nvim_win_get_cursor(M.win)[1]) end })
end

return M
--------------------- ./lua/multi_context/ui/highlights.lua : ---------------------
local api = vim.api
local M = {}

M.define_groups = function()
    vim.cmd("highlight default ContextHeader gui=bold guifg=#FF4500 guibg=NONE")
    vim.cmd("highlight default ContextCurrentBuffer gui=bold guifg=#FFA500 guibg=NONE")
    vim.cmd("highlight default ContextUpdateMessages gui=bold guifg=#FFA500 guibg=NONE")
    vim.cmd("highlight default ContextBoldText gui=bold guifg=#FFA500 guibg=NONE")
    vim.cmd("highlight default ContextApiInfo gui=bold guifg=#FFA500 guibg=NONE")
    
    vim.cmd("highlight default link ContextUITitle ContextApiInfo")
    vim.cmd("highlight default link ContextUISection ContextHeader")
    vim.cmd("highlight default link ContextUIActive ContextBoldText")
    vim.cmd("highlight default link ContextUIData ContextBoldText")

    vim.cmd("highlight default ContextUser gui=bold guifg=#B22222 guibg=NONE")
    vim.cmd("highlight default link ContextUIInactive ContextUser")

    vim.cmd("highlight default ContextUserAI gui=bold guifg=#0000CD guibg=NONE")

    vim.cmd("highlight default ContextUIHelp guifg=#696969 guibg=NONE")
    vim.cmd("highlight default ContextUIDot guifg=#404040 guibg=NONE")
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
        vim.cmd("syntax match ContextUser '^## .* >>.*'")
        vim.cmd("syntax match ContextUserAI '^## IA.*'")
        vim.cmd("syntax match ContextApiInfo '^## API atual:.*'")
        vim.cmd("syntax region ContextCodeBlock start='^```' end='^```'")
        vim.cmd("highlight default link ContextCodeBlock String")
        vim.cmd("syntax region ContextBold matchgroup=ContextBoldText start='\\*\\*' end='\\*\\*'")
        vim.cmd("highlight default link ContextBold ContextBoldText")
        
        -- Ocultação de XML de Arquivamento
        vim.cmd("syntax match ContextBlockTag \"<block[^>]*>\" conceal")
        vim.cmd("syntax match ContextBlockEndTag \"</block>\" conceal")

        -- FASE 43.5: Ocultação de tags da Ontologia (abstract, content, etc)
        vim.cmd("syntax match ContextOntologyTag \"<\\/\\?\\(abstract\\|content\\|key_words\\|summary\\)[^>]*>\" conceal")
				vim.cmd("syntax sync fromstart")

    end)
end

M.apply_controls = function(buf)
    if not api.nvim_buf_is_valid(buf) then return end
    vim.api.nvim_buf_call(buf, function()
        M.define_groups()
        vim.cmd("syntax clear")
        vim.cmd("syntax match ContextUITitle '^===.*==='")
        vim.cmd("syntax match ContextUITitle 'MultiContext AI.*'")
        vim.cmd("syntax match ContextUIHelp '^.*<CR>.*<Space>.*'")
        vim.cmd("syntax match ContextUIHelp '^.*Use j/k para navegar.*'")
        vim.cmd("syntax match ContextUISection '^▶.*'")
        vim.cmd("syntax match ContextUISection '^▼.*'")
        vim.cmd("syntax match ContextUIDot '\\.\\.\\.*'")
        vim.cmd("syntax match ContextUIDot '··*'")
        vim.cmd("syntax match ContextUIActive '●'")
        vim.cmd("syntax match ContextUIActive '\\[ ON \\]'")
        vim.cmd("syntax match ContextUIActive '\\[ ✓ \\]'")
        vim.cmd("syntax match ContextUIActive '\\[ Ask \\]'")
        vim.cmd("syntax match ContextUIActive '\\[ Auto \\]'")
        vim.cmd("syntax match ContextUIActive '\\[ Semântico \\]'")
        vim.cmd("syntax match ContextUIActive '\\[ Percentual \\]'")
        vim.cmd("syntax match ContextUIActive '\\[ Fixo \\]'")
        vim.cmd("syntax match ContextUIActive '\\[ Dinâmico \\]'")
        vim.cmd("syntax match ContextUIInactive '○'")
        vim.cmd("syntax match ContextUIInactive '\\[ OFF \\]'")
        vim.cmd("syntax match ContextUIInactive '\\[   \\]'")
        vim.cmd("syntax match ContextUIInactive '\\[ Off \\]'")
        vim.cmd("syntax match ContextUIData '\\d\\+ tokens'")
        vim.cmd("syntax match ContextUIData '\\d\\+%%'")
        vim.cmd("syntax match ContextUIData '1\\.\\d\\+'")
    end)
end

return M
--------------------- ./lua/multi_context/ui/scroller.lua : ---------------------
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






--------------------- ./lua/multi_context/ui/chat_view.lua : ---------------------
local api = vim.api
local M   = {}

M.popup_buf = nil
M.popup_win = nil
M.code_buf_before_popup = nil
M.swarm_buffers = {}
M.current_swarm_index = 1

function M.create_popup(initial_content_or_bufnr)
    if not (M.popup_win and api.nvim_win_is_valid(M.popup_win)) then
        local cur = api.nvim_get_current_buf()
        if vim.bo[cur].buftype == "" then
            M.code_buf_before_popup = cur
        end
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
    api.nvim_buf_set_keymap(buf, "n", "<CR>", "<Cmd>lua require('multi_context.core.event_bus').emit('USER_SUBMIT', { buf = vim.api.nvim_get_current_buf() })<CR>", km)
    api.nvim_buf_set_keymap(buf, "i", "<C-CR>", "<Esc><Cmd>lua require('multi_context.core.event_bus').emit('USER_SUBMIT', { buf = vim.api.nvim_get_current_buf() })<CR>", km)
    api.nvim_buf_set_keymap(buf, "n", "<C-CR>", "<Cmd>lua require('multi_context.core.event_bus').emit('USER_SUBMIT', { buf = vim.api.nvim_get_current_buf() })<CR>", km)
    api.nvim_buf_set_keymap(buf, "i", "<S-CR>", "<Esc><Cmd>lua require('multi_context.core.event_bus').emit('USER_SUBMIT', { buf = vim.api.nvim_get_current_buf() })<CR>", km)
    api.nvim_buf_set_keymap(buf, "n", "<S-CR>", "<Cmd>lua require('multi_context.core.event_bus').emit('USER_SUBMIT', { buf = vim.api.nvim_get_current_buf() })<CR>", km)
    api.nvim_buf_set_keymap(buf, "n", "<A-b>", "<Cmd>lua require('multi_context.utils.utils').copy_code_block()<CR>", km)
    api.nvim_buf_set_keymap(buf, "i", "<A-b>", "<Esc><Cmd>lua require('multi_context.utils.utils').copy_code_block()<CR>a", km)
    api.nvim_buf_set_keymap(buf, "n", "q", "<Cmd>q<CR>", km)
    api.nvim_buf_set_keymap(buf, "n", "<Tab>", "<Cmd>lua require('multi_context.ui.chat_view').cycle_swarm_buffer(1)<CR>", km)
    api.nvim_buf_set_keymap(buf, "n", "<S-Tab>", "<Cmd>lua require('multi_context.ui.chat_view').cycle_swarm_buffer(-1)<CR>", km)
    
    api.nvim_buf_set_keymap(buf, "n", "<C-x>", "<Cmd>lua require('multi_context.core.react_orchestrator').abort_stream(true)<CR>", km)
    api.nvim_buf_set_keymap(buf, "i", "<C-x>", "<Esc><Cmd>lua require('multi_context.core.react_orchestrator').abort_stream(true)<CR>", km)

    api.nvim_buf_set_keymap(buf, "i", "@", "@<Esc><Cmd>lua require('multi_context.agents').open_agent_selector()<CR>", km)
    api.nvim_buf_set_keymap(buf, "i", "\\", "\\<Esc><Cmd>lua require('multi_context.ecosystem.injectors').open_selector()<CR>", km)

    api.nvim_buf_set_keymap(buf, "n", "<A-x>", "<Cmd>lua require('multi_context.core.react_orchestrator').ExecuteTools(nil, vim.api.nvim_get_current_buf())<CR>", km)
    api.nvim_buf_set_keymap(buf, "i", "<A-x>", "<Esc><Cmd>lua require('multi_context.core.react_orchestrator').ExecuteTools(nil, vim.api.nvim_get_current_buf())<CR>", km)

    local app = config.options.appearance or {}
    local width  = math.ceil(vim.o.columns * (tonumber(app.width) or 0.8))
    local height = math.ceil(vim.o.lines   * (tonumber(app.height) or 0.8))
    local row    = math.ceil((vim.o.lines   - height) / 2)
    local col    = math.ceil((vim.o.columns - width)  / 2)

    local win = api.nvim_open_win(buf, true, {
        relative  = 'editor',
        width     = width,
        height    = height,
        row       = row,
        col       = col,
        style     = 'minimal',
        border    = app.border or 'rounded',
        title     = require("multi_context.i18n").t("chat_title", 0),
        title_pos = 'center',
    })
    M.popup_win = win
    
    -- Ocultação NATIVA do Neovim para XML
    vim.wo[win].conceallevel = 2
    vim.wo[win].concealcursor = "nc"

    api.nvim_create_autocmd({"TextChanged", "TextChangedI", "TextChangedP"}, {
        buffer = buf,
        callback = function()
            require('multi_context.ui.chat_view').update_title()
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
    local first_line = vim.fn.getline(vim.v.foldstart)
    
    -- FASE 43.5: Distinguindo "Abstracts" Cognitivos de "Arquivos Mortos"
    if first_line:match("<abstract>") then
        local summary_text = ""
        for i = vim.v.foldstart, vim.v.foldend do
            local l = vim.fn.getline(i)
            if l:match("<summary>") then
                summary_text = vim.trim(l:gsub("<[^>]+>", ""))
                break
            end
        end
        return " 🧠 [Cognitive Abstract] " .. summary_text
    else
        local preview = ""
        for i = vim.v.foldstart, vim.v.foldend do
            local l = vim.fn.getline(i)
            l = l:gsub("<[^>]+>", "")
            if l:match("%S") then
                preview = vim.trim(l)
                break
            end
        end
        return " 📦[" .. lines_count .. " linhas arquivadas] " .. preview
    end
end

function M.create_folds(buf)
    if not buf or not vim.api.nvim_buf_is_valid(buf) then return end
    vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(buf) then return end
        local windows = vim.fn.win_findbuf(buf)
        for _, win in ipairs(windows) do
            if vim.api.nvim_win_is_valid(win) then
                vim.api.nvim_win_call(win, function()
                    vim.wo.foldmethod = "manual"
                    vim.wo.foldenable = true
                    vim.wo.foldtext = "v:lua.require('multi_context.ui.chat_view').fold_text()"
                    pcall(vim.cmd, 'normal! zE')

                    local total_lines = vim.api.nvim_buf_line_count(buf)
                    local fold_stack = {}
                    local fold_cmds = {}

										local all_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false) -- ✅ O(1) chamada C-API
                    for lnum = 1, total_lines do
											local line = all_lines[lnum]
                        if line then
                            if line:match('<block[^>]*status="archived"') then
                                table.insert(fold_stack, { type = "block", start = lnum })
                            elseif line:match('<abstract>') then
                                table.insert(fold_stack, { type = "abstract", start = lnum })
                            end
                            
                            if line:match('</block>') then
                                for i = #fold_stack, 1, -1 do
                                    if fold_stack[i].type == "block" then
                                        local start_fold = fold_stack[i].start
                                        if lnum > start_fold then
                                            table.insert(fold_cmds, string.format("%d,%dfold", start_fold, lnum))
                                            table.insert(fold_cmds, string.format("%dfoldclose", start_fold))
                                        end
                                        table.remove(fold_stack, i)
                                        break
                                    end
                                end
                            elseif line:match('</abstract>') then
                                for i = #fold_stack, 1, -1 do
                                    if fold_stack[i].type == "abstract" then
                                        local start_fold = fold_stack[i].start
                                        if lnum > start_fold then
                                            table.insert(fold_cmds, string.format("%d,%dfold", start_fold, lnum))
                                            table.insert(fold_cmds, string.format("%dfoldclose", start_fold))
                                        end
                                        table.remove(fold_stack, i)
                                        break
                                    end
                                end
                            end
                        end
                    end
                    
                    -- Agrupa dezenas de dobras em uma única execução em C para performance extrema
                    if #fold_cmds > 0 then
                        pcall(vim.cmd, table.concat(fold_cmds, " | "))
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

function M.update_title()
    if not M.popup_win or not vim.api.nvim_win_is_valid(M.popup_win) then return end
    local ok, conf = pcall(vim.api.nvim_win_get_config, M.popup_win)
    if ok and conf.relative and conf.relative ~= "" then
        local utils = require('multi_context.utils.utils')
        local active_buf = M.popup_buf
        if M.swarm_buffers and #M.swarm_buffers > 0 and M.current_swarm_index then
            local sb = M.swarm_buffers[M.current_swarm_index]
            if sb and sb.buf and vim.api.nvim_buf_is_valid(sb.buf) then
                active_buf = sb.buf
            end
        end
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
            new_title = require("multi_context.i18n").t("chat_title", tokens)
        end
        local config = require("multi_context.config")
        if config.options.auto_inject_context_md and utils.get_context_md_path() then
            new_title = new_title .. "[📖 CONTEXT.md: Active] "
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

    local lines = { 
        require("multi_context.i18n").t("swarm_worker_title"), 
        require("multi_context.i18n").t("agent_label") .. agent_name, 
        require("multi_context.i18n").t("api_label") .. (api_name or require("multi_context.i18n").t("unknown")), 
        "" 
    }
    if initial_instruction then
        for _, l in ipairs(vim.split(initial_instruction, "\n", {plain=true})) do table.insert(lines, l) end
    end
    table.insert(lines, "")
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    if not M.swarm_buffers then M.swarm_buffers = {} end
    table.insert(M.swarm_buffers, { buf = buf, name = agent_name, status = "Rodando" })
    local km = { noremap = true, silent = true }
    vim.api.nvim_buf_set_keymap(buf, "n", "q", "<Cmd>q<CR>", km)
    vim.api.nvim_buf_set_keymap(buf, "n", "<Tab>", "<Cmd>lua require('multi_context.ui.chat_view').cycle_swarm_buffer(1)<CR>", km)
    vim.api.nvim_buf_set_keymap(buf, "n", "<S-Tab>", "<Cmd>lua require('multi_context.ui.chat_view').cycle_swarm_buffer(-1)<CR>", km)
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

local EventBus = require('multi_context.core.event_bus')
EventBus.on("UI_APPEND_CHUNK", function(payload)
    if not payload.buf or not vim.api.nvim_buf_is_valid(payload.buf) then return end
    if type(payload.chunk) ~= "string" or payload.chunk == "" then return end
    local lines_to_add = vim.split(payload.chunk, "\n", {plain = true})
    local count = vim.api.nvim_buf_line_count(payload.buf)
    local last_line = vim.api.nvim_buf_get_lines(payload.buf, count - 1, count, false)[1] or ""
    lines_to_add[1] = last_line .. lines_to_add[1]
    vim.api.nvim_buf_set_lines(payload.buf, count - 1, count, false, lines_to_add)
    if M.popup_win and vim.api.nvim_win_is_valid(M.popup_win) then M.update_title() end
end)
EventBus.on("UI_SWARM_WORKER_UPDATE", function(payload)
    if not payload.buf or not vim.api.nvim_buf_is_valid(payload.buf) then return end
    local lines = vim.split(payload.text, "\n", {plain=true})
    vim.api.nvim_buf_set_lines(payload.buf, 4, -1, false, lines)
end)
EventBus.on("UI_TERMINATE_TURN", function(payload)
    local M_pop = require('multi_context.ui.chat_view')
    local buf = M_pop.popup_buf
    if not buf or not vim.api.nvim_buf_is_valid(buf) then return end
    local next_prompt_lines = { "", "## API atual: " .. payload.current_api, "## " .. payload.user_name .. " >> " }
    if payload.queued_tasks and payload.queued_tasks ~= "" then
        if not payload.is_queue_mode then table.insert(next_prompt_lines, require("multi_context.i18n").t("checkpoint")) end
        for _, q_line in ipairs(vim.split(payload.queued_tasks, "\n")) do table.insert(next_prompt_lines, q_line) end
    end
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, next_prompt_lines)
    M_pop.create_folds(buf)
    require('multi_context.ui.highlights').apply_chat(buf)
    M_pop.update_title()
    if M_pop.popup_win and vim.api.nvim_win_is_valid(M_pop.popup_win) then
        pcall(vim.api.nvim_win_set_cursor, M_pop.popup_win, { vim.api.nvim_buf_line_count(buf), 0 })
        vim.cmd("normal! zz"); vim.cmd("startinsert!")
    end
    if payload.auto_trigger then
        vim.cmd("stopinsert")
        vim.defer_fn(function() require('multi_context.core.event_bus').emit('USER_SUBMIT', { buf = buf }) end, 100)
    end
end)
EventBus.on("UI_SET_LINES_PARTIAL", function(payload)
    if not payload.buf or not vim.api.nvim_buf_is_valid(payload.buf) then return end
    vim.api.nvim_buf_set_lines(payload.buf, payload.start_idx, payload.end_idx, false, payload.lines)
end)
EventBus.on("UI_SET_LINES", function(payload)
    if not payload.buf or not vim.api.nvim_buf_is_valid(payload.buf) then return end
    vim.api.nvim_buf_set_lines(payload.buf, 0, -1, false, payload.lines)
end)
EventBus.on("UI_APPEND_LINES", function(payload)
    if not payload.buf or not vim.api.nvim_buf_is_valid(payload.buf) then return end
    vim.api.nvim_buf_set_lines(payload.buf, -1, -1, false, payload.lines)
    require('multi_context.ui.highlights').apply_chat(payload.buf)
end)
EventBus.on("UI_ARCHIVIST_DONE", function(payload)
    if not payload.buf or not vim.api.nvim_buf_is_valid(payload.buf) then return end
    local p = require('multi_context.ui.chat_view')
    require('multi_context.ui.highlights').apply_chat(payload.buf)
    p.create_folds(payload.buf)
    p.update_title()
end)
EventBus.on("UI_UPDATE_TITLE", function() require('multi_context.ui.chat_view').update_title() end)
EventBus.on("UI_START_STREAMING", function(payload)
    local p = require('multi_context.ui.chat_view')
    require('multi_context.ui.scroller').start_streaming(payload.buf, p.popup_win)
end)
EventBus.on("UI_STOP_STREAMING", function(payload) require('multi_context.ui.scroller').stop_streaming(payload.buf) end)
EventBus.on("UI_CHUNK_RECEIVED", function(payload)
    local p = require('multi_context.ui.chat_view')
    require('multi_context.ui.scroller').on_chunk_received(payload.buf, p.popup_win)
end)

return M
--------------------- ./lua/multi_context/agents.lua : ---------------------
local api = vim.api
local M = {}

M.agents_file = vim.fn.stdpath("config") .. "/mctx_agents.json"

local function fuzzy_match(str, pattern)
    if pattern == "" then return true end
    pattern = pattern:lower():gsub(".", function(c) return c .. ".*" end)
    return str:lower():match(pattern) ~= nil
end

M.load_agents = function()
    local agents_file = vim.fn.stdpath("config") .. "/mctx_agents.json"
    M.agents_file = agents_file
    if vim.fn.filereadable(agents_file) == 0 then vim.fn.writefile({"{}"}, agents_file) end
    local file = io.open(agents_file, "r")
    if not file then return {} end
    local content = file:read("*a")
    file:close()
    local ok, parsed = pcall(vim.fn.json_decode, content)
    if not ok or type(parsed) ~= "table" then parsed = {} end
    local changed = false
    
    if not parsed["tech_lead"] then 
        parsed["tech_lead"] = { 
            system_prompt = "ROLE: Apex Swarm Orchestrator (Agentic Router).\nDIRECTIVE: You are the singular authority responsible for task decomposition, matchmaking, and delegation across the multi-agent system. You operate at the strategic level.\nOPERATIONAL BOUNDARIES:\n1. STRICTLY PROHIBITED: You MUST NOT write code, execute shell commands, or read files directly.\n2. NO CONVERSATION: You MUST NOT answer in plain text, explanations, or markdown tables.\n3. MANDATORY PROTOCOL: You MUST strictly and only use the <tool_call name=\"spawn_swarm\"> tag to route tasks to specialized sub-agents or squads. Any deviation from this strict delegation structure is a catastrophic system failure.", 
            abstraction_level = "high", 
            skills = {"swarm_orchestration"} 
        }
        changed = true 
    end
    
    if not parsed["architect"] then 
        parsed["architect"] = { 
            system_prompt = "ROLE: Principal Systems Architect.\nDIRECTIVE: Design robust, scalable, and highly cohesive software architectures. Your outputs are the blueprints that Execution Units (Coders) will follow.\nOPERATIONAL BOUNDARIES:\n1. MANDATORY PARADIGMS: Enforce SOLID principles, DRY, and strict Test-Driven Development (TDD) planning.\n2. NO IMPLEMENTATION: Do not write functional production code yourself. Write deep structural analysis, class/module interfaces, and rigid test specifications.\n3. PROTOCOL: Execute Deep Codebase Reconnaissance exhaustively before proposing an architecture to ensure strict compatibility with the existing stack.", 
            abstraction_level = "high", 
            skills = {"code_investigation"} 
        }
        changed = true 
    end

    if not parsed["coder"] then 
        parsed["coder"] = { 
            system_prompt = "ROLE: Autonomous Software Engineer (Execution Unit).\nDIRECTIVE: Implement features and patch bugs with surgical precision based on provided blueprints or explicit requests.\nOPERATIONAL BOUNDARIES:\n1. SURGICAL PRECISION: Do not rewrite entire files if a targeted line replacement is sufficient. Minimize I/O footprint.\n2. CODE QUALITY: Write highly efficient, deterministic, and self-documenting code. Never leave TODOs unless explicitly instructed.\n3. PROTOCOL: If operating under TDD, you MUST ensure logic aligns exactly with test constraints. Modify the codebase securely using your authorized Surgical Code Manipulation skills.", 
            abstraction_level = "high", 
            skills = {"code_refactoring", "code_investigation"} 
        }
        changed = true 
    end

    if not parsed["qa"] then 
        parsed["qa"] = { 
            system_prompt = "ROLE: Quality Assurance & Security Auditor.\nDIRECTIVE: Act as a ruthless gatekeeper for code quality. You do not trust the Coder's output until mathematically and syntactically proven secure.\nOPERATIONAL BOUNDARIES:\n1. MANDATORY CHECKS: Hunt for edge cases, memory leaks, security vulnerabilities, and unhandled exceptions.\n2. LSP ENFORCEMENT: You MUST verify LSP diagnostics. Code with syntax errors or warnings is strictly unacceptable.\n3. PROTOCOL: Execute sandboxed test suites, validate terminal outputs, and enforce the highest industry standards before signing off on any delegated task.", 
            abstraction_level = "high", 
            skills = {"quality_assurance", "code_investigation"} 
        }
        changed = true 
    end

    if not parsed["devops"] then 
        parsed["devops"] = { 
            system_prompt = "ROLE: DevOps & Git Operations Commander.\nDIRECTIVE: Manage the version control lifecycle with absolute safety and atomic tracking.\nOPERATIONAL BOUNDARIES:\n1. ATOMICITY: Craft pure Semantic Commits (feat, fix, refactor). Never group unrelated changes into a single commit.\n2. ZERO DESTRUCTION: Destructive operations (reset --hard, force push) are strictly outside your operational clearance unless explicitly forced by the human user.\n3. PROTOCOL: Always check the repository state, branch cleanly, stage surgically, and document all Git operations in your final deployment report.", 
            abstraction_level = "high", 
            skills = {"git_automation"} 
        }
        changed = true 
    end

    if changed then vim.fn.writefile({vim.fn.json_encode(parsed)}, agents_file) end
    for _, agent in pairs(parsed) do if not agent.abstraction_level then agent.abstraction_level = "high" end end
    return parsed
end

M.get_delegable_entities = function()
    local agents = M.load_agents()
    local ok, sq = pcall(require, "multi_context.ecosystem.squads")
    local squads = ok and sq.load_squads() or {}
    local list = {}
    for n, _ in pairs(agents) do table.insert(list, "[A] " .. n) end
    for n, _ in pairs(squads) do table.insert(list, "[S] " .. n) end
    table.sort(list)
    return list
end

M.get_agent_names = function()
    local agents = M.load_agents()
    local names = {}
    for name, _ in pairs(agents) do table.insert(names, name) end
    table.sort(names)
    return names
end

M.selector_buf = nil; M.selector_win = nil; M.parent_win = nil
M.api_list = {}; M.filtered_list = {}; M.current_selection = 1

M.open_agent_selector = function()
    M.api_list = M.get_delegable_entities()
    if #M.api_list == 0 then return end
    
    M.parent_win = api.nvim_get_current_win()
    M.filtered_list = vim.deepcopy(M.api_list)
    M.current_selection = 1
    
    M.selector_buf = api.nvim_create_buf(false, true)
    M.selector_win = api.nvim_open_win(M.selector_buf, true, {
        relative = "cursor", row = 1, col = 0, width = 30, height = math.min(10, #M.api_list + 2),
        style = "minimal", border = "rounded",
    })
    vim.bo[M.selector_buf].buftype = "nofile"
    
    api.nvim_buf_set_lines(M.selector_buf, 0, -1, false, { "> ", "---" })
    M._render_list()
    M._keymaps()
    
    vim.cmd("startinsert!")
    api.nvim_win_set_cursor(M.selector_win, {1, 2})
end

M._update_filter = function(query)
    M.filtered_list = {}
    for _, v in ipairs(M.api_list) do
        if fuzzy_match(v, query) then table.insert(M.filtered_list, v) end
    end
    M.current_selection = 1
    M._render_list()
end

M._render_list = function()
    if not M.selector_buf or not api.nvim_buf_is_valid(M.selector_buf) then return end
    local lines = {}
    for i, name in ipairs(M.filtered_list) do
        local cursor = (i == M.current_selection) and "❯ " or "  "
        table.insert(lines, cursor .. name)
    end
    api.nvim_buf_set_lines(M.selector_buf, 2, -1, false, lines)
    
    local ns = api.nvim_create_namespace("mc_agents")
    api.nvim_buf_clear_namespace(M.selector_buf, ns, 2, -1)
    if #M.filtered_list > 0 then
        api.nvim_buf_add_highlight(M.selector_buf, ns, "ContextSelectorCurrent", M.current_selection + 1, 0, -1)
    end
end

M._keymaps = function()
    if not M.selector_buf or not api.nvim_buf_is_valid(M.selector_buf) then return end
    
    api.nvim_create_autocmd("TextChangedI", {
        buffer = M.selector_buf,
        callback = function()
            local line = api.nvim_buf_get_lines(M.selector_buf, 0, 1, false)[1]
            local query = line:gsub("^> %s*", ""):gsub("^>", "")
            M._update_filter(query)
        end
    })

    local function mk(k, fn) 
        api.nvim_buf_set_keymap(M.selector_buf, "i", k, "", { callback = fn, noremap = true, silent = true })
        api.nvim_buf_set_keymap(M.selector_buf, "n", k, "", { callback = fn, noremap = true, silent = true })
    end
    
    mk("<C-j>", function() M._move(1) end); mk("<Down>", function() M._move(1) end)
    mk("<C-k>", function() M._move(-1) end); mk("<Up>", function() M._move(-1) end)
    mk("<CR>", M._select)
    mk("<Esc>", M._close)
end

M._move = function(dir)
    if #M.filtered_list == 0 then return end
    local n = M.current_selection + dir
    if n >= 1 and n <= #M.filtered_list then M.current_selection = n; M._render_list() end
end

M._select = function()
    local item = M.filtered_list[M.current_selection]
    if not item then M._close(); return end
    local name = item:sub(5)
    M._close_win_only()
    if M.parent_win and api.nvim_win_is_valid(M.parent_win) then
        api.nvim_set_current_win(M.parent_win)
        local row, col = unpack(api.nvim_win_get_cursor(0))
        local line = api.nvim_get_current_line()
        local new_line = string.sub(line, 1, col + 1) .. name .. string.sub(line, col + 2)
        api.nvim_set_current_line(new_line)
        api.nvim_win_set_cursor(0, {row, col + 1 + #name})
        vim.cmd("startinsert")
    end
end

M._close_win_only = function()
    if M.selector_win and api.nvim_win_is_valid(M.selector_win) then api.nvim_win_close(M.selector_win, true) end
    M.selector_buf = nil; M.selector_win = nil
end

M._close = function()
    M._close_win_only()
    if M.parent_win and api.nvim_win_is_valid(M.parent_win) then 
        api.nvim_set_current_win(M.parent_win)
        vim.cmd("startinsert") 
    end
end

return M
--------------------- ./lua/multi_context/init.lua : ---------------------
local api = vim.api
local utils = require('multi_context.utils.utils')
local popup = require('multi_context.ui.chat_view')
local commands = require('multi_context.commands')
local config = require('multi_context.config')
local react_orchestrator = require('multi_context.core.react_orchestrator')

local M = {}
M.popup_buf = popup.popup_buf
M.popup_win = popup.popup_win
M.current_workspace_file = nil

M.setup = function(opts)
    if config and config.setup then config.setup(opts) end
    react_orchestrator.setup()
end

M.OnSwarmComplete = function(summary)
    local p = require('multi_context.ui.chat_view')
    local buf = p.popup_buf
    if not buf or not api.nvim_buf_is_valid(buf) then return end

    if p.swarm_buffers and #p.swarm_buffers > 0 then
        p.current_swarm_index = 1
        if p.popup_win and api.nvim_win_is_valid(p.popup_win) then
            api.nvim_win_set_buf(p.popup_win, p.swarm_buffers[1].buf)
            p.update_title()
        end
    end

    local cfg = require('multi_context.config')
    local user_prefix = "## " .. (cfg.options.user_name or "User") .. " >>"
    
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

    if p.popup_win and api.nvim_win_is_valid(p.popup_win) then
        api.nvim_win_set_cursor(p.popup_win, {api.nvim_buf_line_count(buf), 0})
        vim.cmd("normal! zz")
    end

    vim.defer_fn(function() require('multi_context.core.event_bus').emit('USER_SUBMIT', { buf = buf }) end, 100)
end

M.ContextChatFull = commands.ContextChatFull
M.ContextChatSelection = commands.ContextChatSelection
M.ContextChatFolder = commands.ContextChatFolder
M.ContextChatHandler = commands.ContextChatHandler
M.ContextChatRepo = commands.ContextChatRepo
M.ContextChatGit = commands.ContextChatGit
M.ContextControls = commands.ContextControls
M.ContextApis = commands.ContextControls
M.ContextTree = commands.ContextTree
M.ContextBuffers = commands.ContextBuffers
M.TogglePopup = commands.TogglePopup

M.ContextUndo = function()
    local p = require('multi_context.ui.chat_view')
    local buf = p.popup_buf
    if not buf or not api.nvim_buf_is_valid(buf) then buf = api.nvim_get_current_buf() end
    if require('multi_context.core.state_manager').get('react').last_backup then
        api.nvim_buf_set_lines(buf, 0, -1, false, require('multi_context.core.state_manager').get('react').last_backup)
        require('multi_context.ui.highlights').apply_chat(buf)
        p.create_folds(buf)
        p.update_title()
        vim.notify(require("multi_context.i18n").t("chat_restored"), vim.log.levels.INFO)
    else
        vim.notify(require("multi_context.i18n").t("no_backup"), vim.log.levels.WARN)
    end
end

M.ToggleWorkspaceView = function()
    local ui_popup = require('multi_context.ui.chat_view')
    local is_popup = (ui_popup.popup_win and vim.api.nvim_win_is_valid(ui_popup.popup_win) and vim.api.nvim_get_current_win() == ui_popup.popup_win)
    if is_popup then
        vim.api.nvim_win_hide(ui_popup.popup_win)
        local new_filename, content = utils.build_workspace_content(ui_popup.popup_buf, M.current_workspace_file)
        M.current_workspace_file = utils.export_to_workspace(content, new_filename)
    else
        local cur_buf = vim.api.nvim_get_current_buf()
        if vim.api.nvim_buf_get_name(cur_buf):match("%.mctx$") then
            M.current_workspace_file = vim.api.nvim_buf_get_name(cur_buf)
            utils.load_workspace_state(cur_buf)
            ui_popup.create_popup(cur_buf)
        else
            vim.notify(require("multi_context.i18n").t("not_workspace"), vim.log.levels.WARN)
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

vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
        if require('multi_context.llm.transport')._temp_files then for _, f in ipairs(require('multi_context.llm.transport')._temp_files) do pcall(os.remove, f) end end
    end
})

vim.cmd([[
command! -range Context lua require('multi_context').ContextChatHandler(<line1>, <line2>)
command! -nargs=0 ContextUndo lua require('multi_context').ContextUndo()
command! -nargs=0 ContextFolder lua require('multi_context').ContextChatFolder()
command! -nargs=0 ContextRepo lua require('multi_context').ContextChatRepo()
command! -nargs=0 ContextGit lua require('multi_context').ContextChatGit()
command! -nargs=0 ContextControls lua require('multi_context').ContextControls()
command! -nargs=0 ContextApis lua require('multi_context').ContextControls()
command! -nargs=0 ContextTree lua require('multi_context').ContextTree()
command! -nargs=0 ContextBuffers lua require('multi_context').ContextBuffers()
command! -nargs=0 ContextToggle lua require('multi_context').TogglePopup()
command! -nargs=0 ContextReloadTools lua require('multi_context.ecosystem.tools_manager').load_tools(); vim.notify('Skills customizadas recarregadas!', vim.log.levels.INFO)
]])

return M
--------------------- ./lua/multi_context/utils/utils.lua : ---------------------
-- lua/multi_context/utils.lua
local M   = {}
local api = vim.api

M.get_context_md_path = function()
    local root = vim.fn.system("git rev-parse --show-toplevel")
    if vim.v.shell_error == 0 then root = root:gsub("\n", "") else root = vim.fn.getcwd() end
    local path = root .. "/CONTEXT.md"
    if vim.fn.filereadable(path) == 1 then return path end
    return nil
end

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
    
    local session_id = existing_filename and string.match(existing_filename, "chat_(%d+_%d+).mctx")
    local created_at = os.date("%Y-%m-%dT%H:%M:%S")
    local updated_at = os.date("%Y-%m-%dT%H:%M:%S")

    -- Se já for uma sessão antiga, extraímos o ID/Creation e removemos a tag suja
    local existing_session = content:match("<mctx_session(.-)/>")
    if existing_session then
        local old_id = existing_session:match('id="([^"]+)"')
        local old_created = existing_session:match('created="([^"]+)"')
        if old_id then session_id = old_id end
        if old_created then created_at = old_created end
        content = content:gsub("<mctx_session.-/>%s*", "")
    end
    
    if not session_id then session_id = os.date("%Y%m%d_%H%M%S") end
    
    -- Limpa estado do swarm antigo e substitui
    content = content:gsub("<swarm_state>.-</swarm_state>%s*", "")
    
    local swarm = require('multi_context.core.swarm_manager')
    local popup = require('multi_context.ui.chat_view')
    
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
    
    local header = string.format('<mctx_session id="%s" created="%s" updated="%s" />\n', session_id, created_at, updated_at)
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
    
    local swarm_state_str = content:match("<swarm_state>%s*(.-)%s*</swarm_state>")
    if swarm_state_str then
        local ok, parsed = pcall(vim.fn.json_decode, swarm_state_str)
        if ok and type(parsed) == "table" then
            local swarm = require('multi_context.core.swarm_manager')
            local popup = require('multi_context.ui.chat_view')
            
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
    
    local fname_esc = vim.fn.fnameescape(filename)
    local ok = pcall(vim.cmd, "edit " .. fname_esc)
    if not ok then vim.cmd("split " .. fname_esc) end
    
    local new_buf = vim.api.nvim_get_current_buf()
    vim.bo[new_buf].filetype = "multicontext_chat"
    
    local lines = M.split_lines(content)
    vim.api.nvim_buf_set_lines(new_buf, 0, -1, false, lines)
    vim.bo[new_buf].modified = true
    
    local last_line = vim.api.nvim_buf_line_count(new_buf)
    vim.api.nvim_win_set_cursor(0, { last_line, 0 })
    vim.cmd("stopinsert")
    
    require('multi_context.ui.highlights').apply_chat(new_buf)
    require('multi_context.ui.chat_view').create_folds(new_buf)
    
    local km = { noremap = true, silent = true }
    vim.api.nvim_buf_set_keymap(new_buf, "i", "@", "@<Esc><Cmd>lua require('multi_context.agents').open_agent_selector()<CR>", km)
    api.nvim_buf_set_keymap(new_buf, "i", "\\", "\\<Esc><Cmd>lua require('multi_context.ecosystem.injectors').open_selector()<CR>", km)
    vim.api.nvim_buf_set_keymap(new_buf, "n", "<A-x>", "<Cmd>lua require('multi_context.core.react_orchestrator').ExecuteTools(nil, vim.api.nvim_get_current_buf())<CR>", km)
    vim.api.nvim_buf_set_keymap(new_buf, "i", "<A-x>", "<Esc><Cmd>lua require('multi_context.core.react_orchestrator').ExecuteTools(nil, vim.api.nvim_get_current_buf())<CR>", km)

    require('multi_context.core.event_bus').emit("WORKSPACE_SAVED", { file = filename })
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
M.get_git_diff            = function()  return require('multi_context.utils.context_builders').get_git_diff() end
M.get_tree_context        = function()  return require('multi_context.utils.context_builders').get_tree_context() end
M.get_all_buffers_content = function()  return require('multi_context.utils.context_builders').get_all_buffers_content() end
M.find_last_user_line     = function(b) return require('multi_context.core.conversation').find_last_user_line(b) end
M.load_api_config         = function()  return require('multi_context.config').load_api_config() end
M.load_api_keys           = function()  return require('multi_context.config').load_api_keys() end
M.set_selected_api        = function(n) return require('multi_context.config').set_selected_api(n) end
M.get_api_names           = function()  return require('multi_context.config').get_api_names() end
M.get_current_api         = function()  return require('multi_context.config').get_current_api() end

return M






--------------------- ./lua/multi_context/utils/memory_tracker.lua : ---------------------
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






--------------------- ./lua/multi_context/utils/context_builders.lua : ---------------------
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
        -- Proteção: Ignorar o buffer do próprio chat para evitar recursão
        if api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].filetype ~= 'multicontext_chat' then
            local name = api.nvim_buf_get_name(bufnr)
                        local line_count = api.nvim_buf_line_count(bufnr)
            local limit = math.min(line_count, 5000)
            local lines = api.nvim_buf_get_lines(bufnr, 0, limit, false)
            if line_count > 5000 then table.insert(lines, "--- [TRUNCADO: Máximo de 5000 linhas atingido para evitar OOM] ---") end
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
    
    -- Se quem invocou isso foi o Injetor por dentro do chat, nós pegamos o buffer de código subjacente!
    if vim.bo[buf].filetype == 'multicontext_chat' then
        local pcall_ok, popup = pcall(require, 'multi_context.ui.chat_view')
        if pcall_ok and popup.code_buf_before_popup and api.nvim_buf_is_valid(popup.code_buf_before_popup) then
            buf = popup.code_buf_before_popup
        end
    end
    
    local lines = api.nvim_buf_get_lines(buf, 0, -1, false)
    local numbered = {}
    for i, l in ipairs(lines) do 
        table.insert(numbered, string.format("%d | %s", i, l)) 
    end
    
    local name = vim.fn.fnamemodify(api.nvim_buf_get_name(buf), ":t")
    if name == "" then name = "Buffer_Sem_Nome" end
    
    return "=== BUFFER: " .. name .. " ===\n" .. table.concat(numbered, "\n")
end

M.get_visual_selection = function(line1, line2)
    local buf = api.nvim_get_current_buf()
    
    if vim.bo[buf].filetype == 'multicontext_chat' then
        local pcall_ok, popup = pcall(require, 'multi_context.ui.chat_view')
        if pcall_ok and popup.code_buf_before_popup and api.nvim_buf_is_valid(popup.code_buf_before_popup) then
            buf = popup.code_buf_before_popup
        end
    end
    
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
--------------------- ./doc/multicontext.txt : ---------------------
*multicontext.txt*    MultiContext AI - Engenheiro de Software Autônomo

Autor: Nardi <rnardi@ufsb.edu.br>
Licença: MIT
Versão: 2.3

==============================================================================
SUMÁRIO                                                *multicontext-contents*

1. Introdução ...................................... |multicontext-intro|
2. Comandos Principais ............................. |multicontext-commands|
3. Navegação (LSP & Ripgrep) ....................... |multicontext-navigation|
4. O Agente DevOps (Git Automation) ................ |multicontext-devops|
5. Centro de Comando (Controls) .................... |multicontext-controls|
6. Ontologia Semântica e MCP ....................... |multicontext-mcp|
7. Esquadrões (Squads) e Orquestração .............. |multicontext-squads|
8. Just-in-Time LSP (Auto-Setup) ................... |multicontext-jit-lsp|
9. Arquitetura 2.0 e Blindagem ..................... |multicontext-arch|

==============================================================================
1. INTRODUÇÃO                                             *multicontext-intro*

O MultiContext AI não é um mero auto-completar. É um plugin nativo de Neovim 
focado em delegar a orquestração do projeto a enxames de inteligência
artificial (Swarm). A IA usa ferramentas locais (LSP, Ripgrep, shell, diffs)
para criar, testar e salvar o código na sua máquina sem sair do editor.

Em sua versão mais recente (2.3+), o plugin introduz integração com o
Model Context Protocol (MCP), provisionamento de infraestrutura (JIT LSP) e
a capacidade de invocar esquadrões inteiros de agentes (Meta-Agent Squads)
de forma autônoma.

==============================================================================
2. COMANDOS PRINCIPAIS                                 *multicontext-commands*

*`:ContextControls`*
    Abre o Centro de Comando Virtual (agora com 13 módulos). Daqui, configure 
    sua API, ligue/desligue permissões, crie Skills Semânticas, System Tools,
    Injectors ou gerencie Esquadrões de IA.

*`:ContextToggle`*
    Abre/esconde a janela de Chat Dinâmica no painel principal.

*`:ContextUndo`*
    Restaura o chat para o exato momento antes do Watchdog engatilhar a compressão.

Atalhos no Chat:
    *`@`* (Modo Inserção)  Abre o Fuzzy Finder de Agentes/Squads (ex: @coder, @squad_dev).
    *`\`* (Modo Inserção)  Abre o seletor de Injectors (cole Git Log, LSP Erros).
    *`<Tab>` / `<S-Tab>`*  No Modo Normal, cicla entre os buffers paralelos do Swarm.

==============================================================================
3. NAVEGAÇÃO CIRÚRGICA (LSP & RIPGREP)               *multicontext-navigation*

Diferente de sistemas RAG complexos, o MultiContext atua como um humano:
- *Ripgrep*: A IA busca palavras-chave globalmente usando `rg`.
- *LSP Nativo*: A IA dá "Go to Definition" ou busca Referências consumindo
  o Language Server ativo no Neovim, o que gera uma economia colossal de tokens.

==============================================================================
4. O AGENTE DEVOPS E GIT                                *multicontext-devops*

Ao invocar o `@devops`, o Agente assume responsabilidades de versionamento.
Ele pode usar as ferramentas `git_status`, `git_branch` e `git_commit`. 
Por segurança, a IA está travada localmente e não pode invocar "git add ."
(sendo obrigada a citar os arquivos explicitamente), garantindo commits puros.

==============================================================================
5. CENTRO DE COMANDO (CONTROLS)                        *multicontext-controls*

Use `j` / `k` para navegar no painel `:ContextControls`.
Pressione `<Space>` para alternar estados `[ON / OFF]` e ferramentas de 
cada Agente (Gatekeeper IAM). Use `e` para editar um script (Skill) ou `c` 
para alterar valores limitadores. O painel é totalmente blindado contra 
erros E37 e possui um Rodapé Dinâmico guiando as interações em tempo real.

==============================================================================
6. ONTOLOGIA SEMÂNTICA E MCP                               *multicontext-mcp*

Alinhado às diretrizes do Model Context Protocol (MCP), o MultiContext separa
comportamentos de ferramentas brutas:

*System Tools (MCP)*: Catálogo imutável de binários e scripts do sistema 
(ex: `run_shell`, `edit_file`, scripts bash customizados).

*Semantic Skills*: São os comportamentos e "Regras de Engajamento" da IA.
Exemplo: A skill `database_admin` engloba a System Tool `run_shell`. 
Ao apertar `e` sobre uma Semantic Skill no painel, você edita o PROPÓSITO dela
em um buffer isolado. No Gatekeeper de Agentes, você delega Skills Semânticas,
impedindo que a IA alucine ferramentas sem entender as diretrizes de uso.

==============================================================================
7. ESQUADRÕES (SQUADS) E ORQUESTRAÇÃO                   *multicontext-squads*

Além de agentes individuais, você pode invocar *Meta-Agent Squads*.
- Exemplo: Chamar `@squad_frontend` engatilha uma pipeline definida no painel
  onde o Tech Lead delega a um Coder, que repassa para o QA.

*Coreografia On-The-Fly (Flags no Prompt)*:
    *`--queue`* : Encadeamento sequencial. O agente atual passa o bastão para 
              o próximo automaticamente ao finalizar sua tarefa.
    *`--moa`*   : Orquestração Semântica (Mixture of Agents). Você cita vários
              agentes num prompt complexo e o `@tech_lead` assume o controle,
              subdividindo e roteando as tarefas em paralelo.

==============================================================================
8. JUST-IN-TIME LSP (AUTO-SETUP)                      *multicontext-jit-lsp*

Se a IA precisar ler o projeto ou diagnosticar um arquivo numa linguagem que 
não está devidamente configurada no seu Neovim (ex: `.go` ou `.rs`):
1. O motor pausa a execução da IA.
2. Interage com o usuário pedindo autorização para instalar o LSP via `Mason.nvim`.
3. Uma vez instalado, o LSP é atachado dinamicamente (JIT) ao buffer.
Isso previne a fadiga de alertas e garante uma experiência zero-friction.

==============================================================================
9. ARQUITETURA 2.0 E BLINDAGEM COGNITIVA               *multicontext-arch*

O MultiContext V2.0+ opera sob uma arquitetura limpa e orientada a eventos (PubSub).
A interface do Neovim é 100% reativa, desenhando na tela apenas quando o 
Core (Cérebro) emite eventos. 

Além disso, o sistema conta com Blindagem Cognitiva (Guardrails de Recency Bias)
que previne ativamente alucinações (como a invenção de ferramentas) e força
respostas puras em XML, garantindo máxima economia de tokens e estabilidade.

vim:tw=78:ts=8:ft=help:norl:
--------------------- ./doc/tags : ---------------------
!_TAG_FILE_ENCODING	utf-8	//
`:ContextControls`	multicontext.txt	/*`:ContextControls`*
`:ContextToggle`	multicontext.txt	/*`:ContextToggle`*
`:ContextUndo`	multicontext.txt	/*`:ContextUndo`*
`@`	multicontext.txt	/*`@`*
`\`	multicontext.txt	/*`\\`*
multicontext-arch	multicontext.txt	/*multicontext-arch*
multicontext-commands	multicontext.txt	/*multicontext-commands*
multicontext-contents	multicontext.txt	/*multicontext-contents*
multicontext-controls	multicontext.txt	/*multicontext-controls*
multicontext-devops	multicontext.txt	/*multicontext-devops*
multicontext-intro	multicontext.txt	/*multicontext-intro*
multicontext-navigation	multicontext.txt	/*multicontext-navigation*
multicontext.txt	multicontext.txt	/*multicontext.txt*
--------------------- ./README.md : ---------------------
![Neovim](https://img.shields.io/badge/Neovim-0.8+-green.svg?style=for-the-badge&logo=neovim)
![Lua](https://img.shields.io/badge/Lua-100%25-blue.svg?style=for-the-badge&logo=lua)
![Release](https://img.shields.io/badge/Version-v2.4--Final-blue.svg?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)

## 📖 Overview

**MultiContext AI** is a native, asynchronous, and high-performance Neovim plugin that integrates **autonomous** Artificial Intelligence assistants directly into the editor (inspired by the *Claude Code* and *Devin* paradigms).

Unlike conventional autocomplete plugins, MultiContext acts as a cutting-edge software engineer: it navigates your system using **LSP and Ripgrep**, edits files surgically via Unified Diff, runs terminal tests, concludes its work by performing pure Semantic Commits using the **@devops** persona, and processes complex architectural rules in its native training language (**English**) while outputting answers in your preferred UI language.

All of this is supported by an asynchronous multithreaded **Swarm Architecture** and governed by a virtual **Master Command Center** inside your Neovim. 

In its **v2.4+** release, it achieves true **Model Context Protocol (MCP)** alignment, introducing a Semantic Ontology that cleanly separates Agent Behaviors from Raw System Tools, dynamic **Meta-Agent Squads**, **Just-in-Time LSP Setup** for a zero-friction development experience, and **Active Semantic Indexing with a Cognitive Load Balancer** to parse massive contexts without UI freezes.

---

## 🚀 The Power of the Autonomous Engineer

| Icon | Feature | Description |
|:---:|---|---|
| 🎛️ | **Command Center (Virtual UI)** | Centralized 13-section grid panel (`:ContextControls`) with a *Dynamic Footer*. Manage APIs, Telemetry, Watchdog limits, and deep IAM permissions entirely from your keyboard. |
| 🧬 | **Semantic Ontology (MCP)** | Clean architecture separating **Semantic Skills** (Agent behaviors, guardrails, and military rules of engagement) from **System Tools** (Raw binary executables like `bash` or `read_file`). |
| 🌍 | **Native Cognition & i18n** | Heavy orchestration rules run in **English** in the Backend (yielding zero LLM logic hallucinations) while the UI and Chat output adapt to your preferred language (e.g., pt-BR or en). |
| 🧩 | **Context Injectors (`\`)** | Compose prompts in a live fuzzy menu. Inject the File Tree, global LSP Errors, or Git Logs directly below your cursor without ruining your text. |
| 🐝 | **Swarm Architecture** | The `@tech_lead` invokes specialized teams (@coder, @qa, @devops) operating in a parallel asynchronous carousel. Includes **On-the-fly Choreography** (`--queue` and `--moa` flags). |
| 👥 | **Meta-Agent Squads** | Trigger predefined groups of agents (e.g., `@squad_dev`) that follow strict execution pipelines (e.g., Tech Lead ➔ Coder ➔ QA). |
| 🛡️ | **Context Watchdog 2.0** | A predictive tracker (EMA) monitors tokens. If the limit is breached, the `@archivist` performs an aggressive Quadripartite Compression via XML. |
| ⚖️ | **Cognitive Load Balancer** | Distributes semantic background tasks (RAG) across multiple APIs in a Round-Robin pool, enabling massive parallel indexing without hitting rate limits. |
| 🍿 | **Zero-Freeze UX (Popcorn Patching)** | Massive file dumps are injected instantly as provisional `<abstract>` tags. The background APIs process the files and asynchronously patch the UI in real-time. |
| 🔍 | **LSP & Ripgrep Navigation** | We abandoned noisy RAG. The AI tracks down code with ultra-fast `rg` and jumps into functions via **Go To Definition** using Neovim's own LSP for maximum token efficiency. |
| 🛠️ | **Just-in-Time LSP Setup** | The AI proactively checks if the target file has an active LSP. If missing, it uses `Mason.nvim` to auto-install and attach it silently before parsing code diagnostics. |
| 👨‍💻 | **Git Automation (@devops)** | At the end of a task, the AI creates branches and surgically commits specific files through a strict Security Gatekeeper (blocking remote pushes). |
| 🧠 | **Cognitive Hardening** | Implements Recency Bias Guardrails and Zero-Skill Awareness to prevent tool hallucinations and strictly enforce XML outputs without markdown wrappers. |
| ⚡ | **V2.0 Event-Driven Core** | Pure Lua PubSub Architecture (EventBus) with Centralized State Management and Session AST, making the UI 100% reactive and decoupled. |
| 🔌 | **Polyglot Extensibility** | Teach custom skills (e.g., Pytest, Jira, Databases) by writing scripts in Bash, Python, or Go, and native `env` bridging will couple them to the AI. |

---

## 💡 Usage Examples

MultiContext AI allows you to compose powerful directives natively. Here are a few ways to drive the AI:

### 1. Basic Single Agent Execution
Ask an agent to do something. The system pauses at a `> [Checkpoint]` afterward to await your feedback.
```text
## User >>
@coder --auto Please refactor the authentication module to use JWT.
```
*(Note: The `--auto` flag grants the agent permission to use tools like `edit_file` without prompting you for `<Y/N>` confirmations).*

### 2. Assembly Line (Sequential Queue)
Use the `--queue` flag to chain multiple agents. The system will pass the baton automatically when the previous agent finishes, creating a hands-free workflow.
```text
## User >>
@coder --auto Implement the new login route.
Then, @qa --auto write integration tests for it.
Finally, @devops create a commit saving the progress. --queue
```

### 3. Semantic Swarm (Mixture of Agents)
Use the `--moa` flag to delegate complex coordination to the `@tech_lead`. It will analyze your semantic request, extract the mentioned agents, and spawn asynchronous sub-buffers natively.
```text
## User >>
@architect analyze this project and create a plan to improve its modularity following TDD.
@tech_lead subdivide the architect's plan into small jobs and distribute them across multiple developer and qa agents.
@devops commit the progress up to here. --moa
```

### 4. Meta-Agent Squad Execution
Instead of typing multiple agents, invoke a pre-configured Squad. The system will unpack it and run its specific pipeline.
```text
## User >>
@squad_frontend --auto Implement the new React dashboard component based on the provided API specs.
```

### 5. Context Injectors (Fuzzy Data)
Press `\` in Insert Mode to open the Injectors Menu. You can seamlessly paste LSP errors, Git Logs, or active buffers directly into your prompt without leaving the chat:
```text
## User >>
@coder Fix the following errors in my project:
=== LINTING ERRORS (LSP) ===
src/main.lua:42:10 [ERROR] undefined variable 'x'
```

### 6. Semantic IAM: Creating a Custom AI Behavior
The plugin allows you to design custom logic without writing Lua. 
1. Open the UI (`:ContextControls`).
2. Go to `[+] SEMANTIC SKILLS` and press `<CR>` on `[ + Create New Semantic Skill ]`.
3. Name it `database_admin`.
4. Press `e` on it to open the Guardrails buffer. Write: *"PROTOCOL: You are a DBA. You only run shell commands to interact with PostgreSQL."* Save the file.
5. In the UI, check `[ ✓ ] run_shell` under your new skill.
6. Go to `[+] AGENTS AND PERMISSIONS`, create `@dba`, and assign the `database_admin` skill to it. Your AI is now a specialized database engineer!

### 7. Managing Permissions and Fallbacks
At any time during your work, type `:ContextControls` to pop up the Master Command Center. From there, you can:
- Change the `Watchdog` tolerance if the context gets too big.
- Edit your API Fallback list (if Claude fails, OpenAI assumes control).
- Toggle specific Cognitive Levels (high/medium/low) for your Swarm routers.

### 8. Massive Parallel Indexing (Zero-Freeze UX)
If you need the AI to analyze your entire codebase without freezing the editor, simply press `\` and select `project_dump`. It will instantly insert provisional abstract tags into your chat while the Cognitive Load Balancer distributes the files to your background APIs.
```text
## User >>
@tech_lead Please review the architecture of these files:
<block id="inj_123" type="context_injection">
  <abstract>
    <summary>Indexing: src/main.lua...</summary>
  </abstract>
...
```
*As you type the rest of your prompt, the tags will asynchronously "pop" and update to their true semantic abstracts in real-time!*

---

## 📦 Installation and Bootstrapping (Lazy.nvim)

MultiContext features an **Auto-Setup**. Upon running it for the first time, it will autonomously create all base configuration files isolated in `~/.config/nvim/`.

```lua
{
    "your-username/multi_context_plugin",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
        user_name = "Your Name",
        language  = "en", -- Supports "en" or "pt-BR" (UI only, logic remains in English)
    },
    keys = {
        { "<leader>mc", "<cmd>ContextToggle<cr>", desc = "Toggle MultiContext Chat" },
        { "<leader>mp", "<cmd>ContextControls<cr>", desc = "Master Command Center" },
    }
}
```

> **Tip**: Right after installation, run `:help multicontext` to open the rich native Neovim manual.

---

## 🧪 Automated Testing and Reliability (TDD)

The engine of this plugin was strictly developed under TDD and is maintained with military-grade resilience (**257 isolated tests passing at 100%**).
```bash
make test_agregate_results
```

```text
======================================================================
🧪 Executing Full Suite (Plenary Isolation)...
======================================================================
...
======================================================================
📊 AGGREGATED GLOBAL SUMMARY (MULTI-CONTEXT)
======================================================================
✅ Success: 257
❌ Failed : 0
💥 Errors : 0
======================================================================
```
--------------------- ./examples/injectors/git_log.lua : ---------------------
return {
    name = "git_log",
    description = "Lista os últimos 10 commits (oneline) do Git",
    execute = function()
        local root = vim.fn.system("git rev-parse --show-toplevel")
        if vim.v.shell_error ~= 0 then return "ERRO: Não é um repositório git." end
        root = root:gsub("\n", "")
        
        local log = vim.fn.system("git -C " .. vim.fn.shellescape(root) .. " log -n 10 --oneline")
        return "=== ÚLTIMOS 10 COMMITS ===\n" .. log
    end
}
--------------------- ./examples/injectors/lsp_errors.lua : ---------------------
return {
    name = "lsp_errors",
    description = "Lista todos os erros e avisos do LSP no workspace ativo",
    execute = function()
        local diags = vim.diagnostic.get(nil)
        if #diags == 0 then return "Nenhum problema encontrado pelo LSP no projeto." end
        
        local severity_names = { [1] = "ERROR", [2] = "WARN", [3] = "INFO", [4] = "HINT" }
        local out = {"=== PROBLEMAS NO PROJETO (LSP) ==="}
        
        for _, d in ipairs(diags) do
            local sev = severity_names[d.severity] or "?"
            local file = vim.api.nvim_buf_get_name(d.bufnr)
            -- Deixa o caminho relativo à raiz para economizar tokens
            file = vim.fn.fnamemodify(file, ":.")
            table.insert(out, string.format("%s:%d:%d [%s] %s", file, d.lnum + 1, d.col + 1, sev, d.message))
        end
        
        return table.concat(out, "\n")
    end
}
--------------------- ./examples/injectors/project_dump.lua : ---------------------
return {
    name = "project_dump",
    description = "Gera um dump completo do projeto (Árvore + Fontes .lua)",
    execute = function()
        local root = vim.fn.system("git rev-parse --show-toplevel")
        if vim.v.shell_error ~= 0 then 
            root = vim.fn.getcwd() 
        else 
            root = root:gsub("\n", "") 
        end
        
        local out = {}
        
        -- Proteção 1: Filtra diretórios de cache e build no comando tree
        local tree_ignore = "'.git|node_modules|__pycache__|build|dist|target|.DS_Store|.mctx_chats'"
        local tree_cmd = "tree -f --noreport -I " .. tree_ignore .. " " .. vim.fn.shellescape(root)
        local tree_out = vim.fn.system(tree_cmd)
        
        -- Fallback de segurança caso o comando 'tree' não exista no sistema
        if vim.v.shell_error ~= 0 and (tree_out:match("not found") or tree_out == "") then
            tree_out = vim.fn.system("find " .. vim.fn.shellescape(root) .. " -maxdepth 3 -not -path '*/.git/*' -not -path '*/node_modules/*'")
        end
        table.insert(out, { title = "Project Tree", content = tree_out })
        
        -- Função de segurança estrita para I/O
        local function read_file_safe(filepath)
            local stat = vim.loop.fs_stat(filepath)
            if not stat then return nil end
            
            -- Proteção 2: Bloqueia arquivos maiores que 100KB para salvar tokens
            if stat.size > 100 * 1024 then
                return "--[ARQUIVO IGNORADO: MAIOR QUE 100KB] --"
            end
            
            -- Proteção 3: Heurística Anti-Binário (Procura por null bytes)
            local fd = vim.loop.fs_open(filepath, "r", 438) -- 438 é 0666 em octal
            if fd then
                local chunk = vim.loop.fs_read(fd, 1024, 0)
                vim.loop.fs_close(fd)
                if chunk and chunk:find("\0") then
                    return "-- [ARQUIVO BINÁRIO IGNORADO] --"
                end
            end
            
            local lines = vim.fn.readfile(filepath)
            return table.concat(lines, "\n")
        end

        local context_md = root .. "/CONTEXT.md"
        if vim.fn.filereadable(context_md) == 1 then
            local content = read_file_safe(context_md)
            if content then
                table.insert(out, { title = "CONTEXT.md", content = content })
            end
        end
        
        -- Proteção 4: Usa git ls-files se for repositório (respeitando o .gitignore estritamente)
        local files = {}
        if vim.fn.isdirectory(root .. "/.git") == 1 then
            local git_files = vim.fn.split(vim.fn.system("git -C " .. vim.fn.shellescape(root) .. " ls-files"), "\n")
            for _, f in ipairs(git_files) do
                if f:match("%.lua$") then
                    table.insert(files, root .. "/" .. f)
                end
            end
        else
            -- Fallback para projetos sem Git
            local find_cmd = "find " .. vim.fn.shellescape(root) .. " -type f -name '*.lua' -not -path '*/.git/*' -not -path '*/node_modules/*' -not -path '*/.mctx_chats/*'"
            files = vim.fn.split(vim.fn.system(find_cmd), "\n")
        end

        for _, f in ipairs(files) do
            if f ~= "" then
                local short_name = f:gsub(root .. "/", "")
                local content = read_file_safe(f)
                
                if content then
                    table.insert(out, { title = short_name, content = content })
                end
            end
        end
        
        return out
    end
}
--------------------- ./Makefile : ---------------------
.PHONY: test test_agregate_results doc

test:
	nvim --headless -i NONE -c "PlenaryBustedDirectory lua/multi_context/tests/"

test_agregate_results:
	@echo "======================================================================"
	@echo "🧪 Executando Suíte Completa e Coletando Falhas em Background..."
	@echo "======================================================================"
	@bash ./run_tests.sh 2>&1 | tee test_output.log || true
	@echo ""
	@echo "======================================================================"
	@echo "🔍 RELATÓRIO DE FALHAS (ISOLADO)"
	@echo "======================================================================"
	@# O .* ignora os códigos de cor ANSI em vermelho que o Plenary injeta
	@grep -A 12 "Fail.*||" test_output.log > failures.log || true
	@if [ -s failures.log ]; then \
		cat failures.log; \
		echo "======================================================================"; \
		echo "❌ ALERTA: Há testes falhando no sistema. Veja os detalhes acima."; \
		rm -f test_output.log failures.log; \
		exit 1; \
	else \
		echo "✅ SUCESSO ABSOLUTO! Não há falhas listadas."; \
		rm -f test_output.log failures.log; \
		exit 0; \
	fi

doc:
	@echo "📚 Gerando as Help Tags nativas do Vimdoc..."
	nvim --headless -i NONE -c "helptags doc/" -c "q"
	@echo "✅ Help Tags geradas!"
--------------------- ./CONTEXT.md : ---------------------
# MultiContext AI - Neovim Plugin

## Overview
MultiContext AI is a native, asynchronous, high-performance plugin for Neovim that integrates autonomous AI assistants directly into the editor (inspired by the Devin/Claude Code paradigm). The plugin enables interaction with multiple specialized agents through a chat interface, providing direct access to the file system, terminal execution, autonomous reasoning loops (ReAct), and active context window management. 

In its **V2.4.3** release, it features an advanced **Swarm Architecture** (Mixture of Agents - MoA), asynchronous state persistence (Stateful Workspaces), **Meta-Agent Squads**, **Quadripartite Memory (Predictive Watchdog)**, a **Pluggable and Editable Skills Ecosystem** provided with community templates, **Context Injectors (\)** for dynamic prompt composition, ultra-fast global search using **Ripgrep**, surgical code navigation via **Neovim LSP** (Go to Definition/References), a **DevOps Agent** for local Git automation, an extensive **Virtual Master Command Center**, **Situational Awareness Tools**, **Just-in-Time LSP Auto-Setup**, an **Cognitive Optimization & Internationalization (i18n) Engine**, **Active Semantic Indexing with a Cognitive Load Balancer**, a **Polymorphic Immutable Ledger** that transparently compresses context via background APIs without destroying historical data, **Enterprise-Grade Security** with Zero-UI Freeze asynchronous execution and strict Sandbox Escape prevention, and a **100% Deterministic Asynchronous Testing Architecture** guaranteeing absolute stability across the entire codebase.

## Technical Architecture

### Core Technologies
- **Language**: Lua (native integration with Neovim).
- **Testing Framework**: `plenary.nvim` (busted) - **281 Unit and Integration Tests (100% Absolute Success Rate)**, featuring severe mock isolation (I/O, Kernel, Network), a custom **Async Barrier** (Queue Draining) for Neovim's Event Loop, and a strict **Restore-Before-Assert** pattern preventing Global State Bleeding.
- **Asynchronous Operations & Networking**: `vim.fn.jobstart` / `vim.fn.jobstop` abstracted via a custom transport module (non-blocking `curl` promises with robust TCP chunking buffers).
- **XML Processing & Ledger**: Fault-tolerant functional parser, featuring implicit tag auto-closing. Chat state is natively structured as an Immutable Ledger using `<block>` tags with relational attributes (`id`, `status`, `covers`). All ReAct loops and user interactions are strictly and idempotently wrapped to preserve AST integrity.
- **Concurrency**: Native *Worker Pool* implementation managing asynchronous HTTP streams without blocking Neovim's main UI thread.
- **State Serialization & Visual Engine**: Metadata Envelopes and JSON-in-XML injection to save and restore Swarm sessions. Leverages Neovim's native `conceallevel` and `foldexpr` to invisibly render XML metadata while cleanly grouping archived history under semantic summaries.

### Directory Structure
```text
lua/multi_context/
├── init.lua              # Main orchestrator, live stream monitoring, and hooks
├── config.lua            # Settings, User Bootstrapping, and Auto-Setup
├── i18n.lua              # Internationalization Engine and Language Fallback (en, pt-BR)
├── agents.lua            # Initializer for the user's mctx_agents.json
├── injectors.lua         # Visual engine (\ menu) and Loader for user's dynamic macros
├── api_client.lua        # Queue router and API fallbacks
├── transport.lua         # HTTP engine (curl), streams, telemetry (debug), and cleanup
├── prompt_parser.lua     # Intent parser and Dynamic Prompt/Skill Assembler
├── tool_parser.lua       # Functional extractor and XML tag sanitizer (Auto-close logic)
├── tool_runner.lua       # Permission Gatekeeper, native executor, and plugin router
├── swarm_manager.lua     # Swarm Brain: queues, workers, ReAct, MoA, Pipelines, and Choreography
├── squads.lua            # Loader and resolver for Meta-Agent Squads
├── skills_manager.lua    # Async loader and external code validator (Hot-Reload)
├── skills_ontology.lua   # Semantic resolution mapping Agent Skills to System Tools (MCP)
├── lsp_utils.lua         # Silent bridge with Neovim LSP (Go to Definition/References)
├── lsp_manager.lua       # JIT LSP Provisioning, Extension Mappings, and Mason.nvim integration
├── react_loop.lua        # Session state manager and Circuit Breaker
├── memory_tracker.lua    # Predictive Watchdog with EMA calculation and Initial Turn Immunity
├── archiver.lua          # Relational compression engine manipulating the AST blocks
├── dynamic_watchdog.lua  # Asynchronous background librarian orchestrator
├── context_builders.lua  # Context extractors injecting strict line numbering (1 | code)
├── context_controls.lua  # Master Command Center (13 Sections: API, IAM, Skills, Tools, Swarm...)
├── tools.lua             # Native tools (read, edit, bash, LSP, Unified Diff, Git, Ripgrep)
├── utils.lua             # Token calculation and Workspace serialization tools
├── ui/
│   ├── popup.lua         # Floating window logic, dynamic styling, carousel, and keymaps
│   ├── scroller.lua      # Smart Auto-Scroll logic and directional tracker
│   └── highlights.lua    # Unified syntax highlights and global palette
├── tests/                # Automated Test Suite (TDD/Plenary) with complex mocks
│   ├── i18n_spec.lua             # Language Engine and Fallback Tests
│   ├── git_tools_spec.lua        # Git Automation and Gatekeeper Tests
│   ├── archiver_spec.lua         # Relational Compression and RAG Tests
│   ├── visual_engine_spec.lua    # Native Folds and Conceal Tests
│   └── ... (plus 40+ files)
└── examples/
    ├── skills/           # Community Skill Templates (Jira, Pytest, SQL)
    └── injectors/        # Community Injector Templates (Project Dump, LSP Errors, Git Log)
```

## Implemented Features and Capabilities

### 1. Dynamic Canvas and Context Injectors (Phase 28)
- **Context Macros**: Pressing the `\` key in Insert Mode opens a virtual fuzzy selector (similar to the `@` command for agents), allowing users to dynamically inject project data directly below the cursor, preserving prompt readability.
- **Local Injector Ecosystem**: Users can program their own connectors by writing a simple Lua/Bash/Python script in `~/.config/nvim/mctx_injectors/`. Community templates are provided for LSP Diagnostics, Project Dumps, and Git Logs.

### 2. Master Command Center and Identity & Access Management (IAM)
- **13-Section Declarative Grid**: A unified interactive interface accessed via `:ContextControls`. Renders visual toggles (`[ ON ]`, `[ ✓ ]`), dots (`· · ·`), and expandable nodes (`[+]/[-]`).
- **Dynamic Anchored Footer**: The panel's footer dynamically instructs the user on which action to take (`<Space>`, `c`, `e`, `<CR>`) depending on cursor position, using Neovim 0.10+ native `footer` API.
- **Interactivity and State Mutation**: Total keyboard control. Allows toggling permissions, editing loop limits, ordering API fallback queues (`dd` and `p`), editing Master Prompts, and toggling telemetry. Features native protection against the `E37` error.
- **Agent Permission Matrix**: Fine-grained control listing every agent, allowing users to toggle specific tools (Skills) individually, enforcing a Principle of Least Privilege saved in `mctx_agents.json`.
- **Advanced Persona Management**: Create, safely delete, and edit an agent's *System Prompt* in an isolated temporary buffer with transparent background *Auto-Save* (`BufWritePost`).
- **Dynamic Entity Factory**: Instant creation of new Skills, Injectors, and Personas via `[ + ]` buttons in the virtual DOM, generating boilerplate code and opening the buffer immediately.

### 3. Advanced Swarm Architecture (MoA, Pipelines, and Choreography)
- **On-the-Fly Choreography (Global Flags)**: Instantly define execution flows directly in your prompt without pre-configuring JSONs:
  - **`--queue`**: Transforms your prompt into an automated Assembly Line. When one agent finishes, the next is automatically invoked without waiting for manual checkpoints.
  - **`--moa`**: Triggers a Semantic Swarm. It groups all mentioned agents and delegates the entire block to the `@tech_lead`, who autonomously reads the intent, generates the `spawn_swarm` JSON, and orchestrates the agents in parallel or pipelines.
- **Tech Lead Delegation**: Deep orchestration via the `spawn_swarm` JSON payload.
- **Dynamic Cognitive Routing (MoA)**: The visual panel allows users to define API **Cognitive Abstraction Levels** (`low/medium/high`). The system automatically checks compatibility between an API's cognitive capacity and an agent's demand, routing tasks to the most suitable idle worker (Directional Fallback/Starvation Prevention).
- **Pipelines and Choreography**: Task reincarnation in execution chains and injection of the `switch_agent` request, allowing an agent to yield control and reconfigure the *in-flight* persona without breaking the async loop.

### 4. Predictive Guardian, Quadripartite Compression, and 3 Engines
- **Watchdog via EMA**: A predictive tracker calculates the geometric Exponential Moving Average (EMA) of generated tokens, adding the weight of the current buffer. Real-time telemetry is displayed on the UI.
- **3 Compression Engines**: Configurable via the interactive panel (Semantic, Percentage, and Fixed limits).
- **The @archivist Persona**: When the limit is breached, the system intercepts the request and summons the Archivist to transmute the entire buffer into a strict XML model (`<genesis>`, `<plan>`, `<journey>`, `<now>`), hyper-compressing memory while retaining critical data.

### 5. Meta-Agent Squads and Pluggable Skills (Community V1.0)
- Transparent compilation of squad mentions (e.g., `@squad_dev`).
- Full Squad management through the panel, visualizing the execution chain and editing the `.json` file.
- Pluggable custom scripts via `~/.config/nvim/mctx_tools/` with Gatekeeper validation, autonomous hot-reload, and scope isolation.

### 6. Unified Diff and Workspace Persistence
- **Visual Resurrection**: The `History and Workspaces` section in the panel automatically lists the latest `.mctx` files saved in the project, allowing users to load complex conversations (and their background Swarm state) with a single `<CR>`.
- State persistence via JSON-in-XML injection.
- Native surgical edits coupled to the UNIX Kernel via `patch --force`.

### 7. Fuzzy Canvas and Predictive UX (Phase 29)
- **Smart Selectors (Telescope-like)**: Invoking `@` (Agents) or `\` (Injectors) operates as a live Fuzzy Finder parsing text in Insert Mode (`TextChangedI`).
- **Smart Placement**: The injection engine protects the user's prompt by placing massive context blocks (dumps, logs) on the line *below* the cursor.

### 8. Polyglot Engine (Language Agnostic)
- **Absolute Freedom**: Skills and Injectors are no longer restricted to `.lua` scripts. The engine now accepts **any executable system script** (`.sh`, `.fish`, `.py`, `.js`, compiled Golang/Rust binaries).
- **Metadata Injection via Comments**: Users document their scripts freely using simple headers (`# DESC: ...` and `# PARAM: target | string | true | desc`).
- **Environment Variable Bridge**: The AI interacts with the user's languages by exporting extracted parameters as POSIX `env` variables (e.g., sends a `query` parameter as `$MCTX_QUERY` directly to the local Bash/Fish script).

### 9. Surgical Navigation and Search (LSP + Ripgrep) (Phase 30)
- **Native Ripgrep**: Intelligent use of `rg` (with safe fallback to `git grep`) via the `search_code` tool, ensuring instant global searches, respecting `.gitignore`, and indexing newly created files.
- **Advanced LSP Integration**: The AI acts like a human inside the IDE. Through the "Silent Bridge", the AI queries Neovim's LSP server (`lsp_definition`, `lsp_references`, `lsp_document_symbols`), finding where classes/functions were defined and extracting *only the relevant code blocks*, drastically saving tokens compared to noisy RAG (Vector DBs).

### 10. Git Automation and DevOps Agent (Phase 31)
- **Autonomous DevOps Agent**: A native persona (`@devops`) dedicated exclusively to version control, tasked with evaluating Diffs and performing pure Semantic Commits.
- **Local Git Tools**: Surgical tools (`git_status`, `git_branch`, `git_commit`) available to manage the working tree and isolate implementations in temporary branches.
- **Security Gatekeeper**: Deep algorithmic locks prevent the AI from running `git add .` (forcing surgical individual file commits) and strictly forbid remote/destructive commands like `git push`, `reset --hard`, or `rebase` without manual UI confirmation.

### 11. Internationalization and Cognitive Optimization (Phase 33)
- **i18n Engine**: A reactive translation dictionary (`en` and `pt-BR`) dynamically feeds the entire interface, system messages, I/O validations, and the Command Center.
- **Cognitive Backend**: Heavy structural rules (Swarm architecture, XML formatting, ReAct logic, Watchdog boundaries) are inherently passed to the LLM in **English**. Since foundation models are primarily trained on English datasets, this effectively reduces structural hallucinations and saves tokens.
- **Adaptive Language Directive**: A conditional `sys_lang_directive` is injected into the prompt. The AI processes complex rules in English but is instructed to output its final thoughts, comments, and code in the user's chosen `config.language`.

### 12. V2.0 Event-Driven Architecture & Session AST (Phase 35)
- **Clean Architecture**: The core logic is fully decoupled from the Neovim UI through a strict PubSub `EventBus`. The UI is 100% reactive, enabling potential headless executions.
- **Centralized State Management**: A Redux-like state manager eradicates global variables and ensures predictable state mutations.
- **Session AST**: Chat history is maintained as an Abstract Syntax Tree in RAM, replacing regex-heavy parsing and allowing structured prompt building.

### 13. Cognitive Hardening & Anti-Hallucination (Phase 36)
- **Recency Bias Guardrails**: Critical formatting rules (like strict XML enforcement without markdown wrappers) are injected at the absolute end of the system prompt, exploiting LLM recency bias for maximum obedience.
- **Zero-Skill Awareness**: Agents focused on planning or philosophy with no assigned tools are explicitly warned that they lack operational capabilities, completely eliminating tool-invention hallucinations.

### 14. Network Resilience & UX Boundary Hardening (Phase 37)
- **HTTP Stream Bufferization**: Robust TCP chunking abstraction that intercepts split JSON payloads during slow network conditions, preventing parser crashes.
- **Directional Fallback**: API Client gracefully hops to the next available provider upon 500/429 errors.
- **Boundary Clamping**: Safe cyclic index limits on Fuzzy Finders preventing Neovim UI crashes (`Index Out of Bounds`).
- **Safe Undo**: The `:ContextUndo` command restores the chat to its exact prior state before an Archivist compression occurs, ensuring safety for long contexts.

### 15. Situational Awareness Tools & Active Context (Phase 38)
- **Just-in-Time Intelligence**: Instead of inflating the System Prompt, agents are equipped with tools to query their environment dynamically, enabling true *ReAct* reasoning.
- **Workforce Matrix (`get_agents_info`)**: Allows `@tech_lead` to query available agents and their precise skills before orchestrating the swarm.
- **Project Heuristics (`get_project_stack`)**: Exposes OS, Base Shell, active LSPs, and indent configurations (Tabs vs Spaces) to prevent syntax/formatting errors across all agents.
- **Deep Git State (`get_git_env`)**: Exposes current branch, commits ahead/behind, and blocks (MERGE_HEAD/REBASE) to the `@devops` agent, avoiding blind commits during conflicts.

### 16. Just-in-Time LSP Auto-Setup (Phase 39)
- **Proactive Infrastructure**: When the AI attempts to edit or run diagnostics on a file, the system checks the target extension (e.g., `.rs`, `.go`) to ensure the proper LSP is active.
- **Mason.nvim Integration**: If the LSP is missing, the AI's execution is paused, and the user is prompted to install it seamlessly via `Mason` (`[S/N]`).
- **Stateful Alert Fatigue Prevention**: Rejected installations are saved in the `StateManager` to ensure the user is not repeatedly bothered during the same session.
- **JIT Attachment**: Successfully installed LSPs are dynamically attached to the buffers (`BufReadPost` hook) without requiring the user to reload the file, allowing the AI to instantly receive accurate syntax errors.

### 17. Semantic Ontology and MCP Alignment (Phases 40 and 41)
- **Model Context Protocol (MCP) Adoption**: The architecture cleanly separates **Semantic Skills** (responsibilities, behaviors, and military rules of engagement) from **System Tools** (raw executable mechanisms like bash or lua scripts).
- **Semantic IAM Dashboard**: The Master Command Center (`:ContextControls`) was visually refactored. The Gatekeeper now assigns high-level Semantic Skills (e.g., `code_refactoring`, `git_automation`) to Agents, rather than giving them blind access to raw tools.
- **Skill Guardrails & Editing**: A dedicated *Semantic Skills* UI section allows users to create new behaviors, map which System Tools they contain, and press `e` to edit their strict `Purpose`, `Trigger`, and `Protocol` in an isolated Neovim buffer. This completely eliminates the UI's cognitive dissonance and prevents raw tool hallucination.
- **Dynamic Tool Resolution**: Behind the scenes, the `skills_ontology` compiler resolves the agent's semantic skills down to a flat array of System Tools just-in-time for the API payload, acting as a flawless auto-wrapper.

### 18. Immutable Ledger, Relational Compression & Asynchronous Librarian (Phase 42)
- **Polymorphic XML Blocks**: The chat history transitioned from destructive string-based garbage collection to an append-only XML ledger. Operations and dialogue are encapsulated in `<block>` tags governed by strict metadata (`id`, `status`, `type`, `covers`), guaranteeing robust parsing and absolute structural integrity.
- **Asynchronous Librarian (Dynamic Watchdog)**: The Predictive Watchdog now features a `dynamic` mode. It transparently delegates semantic summarization to a secondary, user-selected background API (e.g., a faster/cheaper model). This eliminates UI freezes during context compression and preserves the expensive main model's context window.
- **Local RAG Capabilities (`deep_dive` tool)**: Swarm Agents are now equipped with a surgical tool to "unfold" compressed context. By executing `deep_dive` on a summary's target ID, the agent retrieves the original raw data from archived blocks on demand.
- **Native Neovim Visual Engine**: Employs Neovim's built-in `conceal` capabilities to hide raw XML tags from the user, ensuring the interface remains as readable as markdown. It dynamically creates `folds` wrapping archived interactions under their summaries (e.g., `📦 [X archived lines]`), providing a sleek UI experience while ensuring the underlying `.mctx` file remains fully hackable text.

### 19. Active Semantic Indexing & Cognitive Load Balancer (Phase 44)
- **Structured Multi-Block Injectors**: Context macros (like `project_dump`) now return structured arrays of files instead of massive raw strings, automatically encapsulating each file into its own distinct XML `<block>`.
- **Zero-Freeze UX (Provisional Abstracts)**: Massive file dumps no longer clutter the screen or freeze the UI. Files are instantly injected with a provisional `<abstract>` (e.g., `Indexing: src/main.lua...`), which is immediately folded by Neovim's visual engine.
- **Cognitive Load Balancer**: A background routing engine (`dynamic_watchdog`) distributes semantic summarization tasks (RAG) across a designated pool of secondary APIs using a Round-Robin algorithm. This enables massive parallel indexing without hitting rate limits on a single provider.
- **Asynchronous Popcorn Patching**: As the background APIs complete their tasks, the system asynchronously patches the buffer in real-time, replacing the provisional tags with true semantic abstracts (`🧠 [Cognitive Abstract] ...`), without interrupting the user's typing.

### 20. Enterprise-Grade Resilience & Security (Phases 45 and 46)
- **Zero UI-Freeze Async Tools**: Heavy native tools (`run_shell`, `apply_diff`) were entirely refactored to use Neovim's asynchronous `jobstart` API. This prevents the editor from locking up during long-running tasks (like `npm install` or applying massive patches), ensuring a completely fluid user experience.
- **Anti-OOM (Out of Memory) Protection**: Enforced strict line-read limits and binary file detection mechanisms on context builders and file dumpers. This safeguards Neovim from crashing when the user attempts to accidentally inject massive datasets (e.g., multi-gigabyte log files).
- **I/O Caching & Stutter Prevention**: Implemented intelligent session-level caching for heavy synchronous shell calls (such as resolving the git root directory). This eliminated micro-stutters during typing inside the chat buffer.
- **Sandbox Escape Prevention**: Hardened the Gatekeeper's Regex engine to strictly anchor string evaluations and proactively block shell chaining operators (`|`, `&&`, `$()`, backticks). This completely neutralizes RCE (Remote Code Execution) vulnerabilities arising from potential AI tool call hallucinations.
- **Pure Scope Isolation**: Eradicated all `_G` global variables from the architecture, shifting entirely to encapsulated module states (`StateManager`), guaranteeing zero memory leaks across sessions and multi-buffer setups.
- **Idempotent AST Encapsulation**: The ReAct orchestrator now enforces strict XML `<block>` wrapping for all user and AI interactions, completely eliminating hybrid parsing ambiguities and Double-Wrapping bugs.

### 21. Deterministic Test Architecture & State Isolation (Phase 47)
- **Async Barrier (Queue Draining)**: Intercepts Neovim's native event loop APIs (`vim.schedule` and `vim.defer_fn`) globally across the test suite. This guarantees that all background asynchronous promises resolve before a test buffer is torn down, eliminating silent `Plenary.busted` crashes and phantom leakage.
- **Global State Anti-Bleeding**: Implementation of a strict *Restore-Before-Assert* pattern ensuring global Neovim I/O and Kernel mocks (e.g., `vim.fn.system`, `vim.fn.executable`) are unfailingly restored to their original state even when `assert` exceptions interrupt the runtime flow.
- **Deterministic Suite Execution**: Ensured 100% stability in test counts (abolishing hash-based directory loading inconsistencies in Linux environments) by structurally confining every `it` evaluation within meticulously scoped `describe` lifecycle bounds.

---

## Current Development State

### ✅ Implemented, Stable, and Tested (V2.4.3 Architecture)
The core of the product is a cutting-edge industrial orchestration engine.
- **Plenary Test Coverage:** 281 isolated Unit and Integration tests (0 Failures / 0 Errors - 100% Absolute Success).
- 100% Deterministic Asynchronous Test Suite with custom Async Barriers and State Leakage Prevention.
- Idempotent XML AST enforcing strict `<block>` encapsulation for all UI and LLM I/O.
- 100% Internationalized System (i18n) and Cognitive Backend.
- `LazyVim`-like interface with Anchored Dynamic Footer and 13 Master Modules.
- Dual Extensibility: Active Polyglot Skills for the AI, Textual Injectors (`\`) for the User.
- Predictive Watchdog 2.0 (Flexible Compression Engines) & Safe Undo.
- Real-time IAM for Agents and Semantic Skills (Safe Deletion, Isolated Prompt Editing).
- Advanced Swarm (MoA, Mutable Cognitive Levels, Pipelines, Choreography).
- Pure Lua PubSub Architecture (EventBus) with Centralized State Management.
- Situational Awareness Tools enabling active environmental inspection.
- Just-in-Time LSP Provisioning with `Mason.nvim` integration.
- Unified Diff, Persistent Workspaces, and Meta-Agent Squads.
- Deep integration with Neovim LSP and Ripgrep for deterministic navigation.
- Local Git automation via DevOps Agent with atomic security locks.
- Polymorphic Immutable Ledger with Asynchronous Background Summarization (Dynamic Watchdog), Local RAG (`deep_dive`), and Native Visual Folds/Conceal.
- Active Semantic Indexing with Zero-Freeze UX, Popcorn Patching, and Cognitive Load Balancer.
- Asynchronous Tool Execution (`jobstart`) and Robust Out-of-Memory (OOM) Protection.
- Strict Sandbox Security against remote execution bypasses.
--------------------- ./.gitignore : ---------------------
# Ignora arquivos temporários e chaves vazadas
*.json
!agents/agents.json
.DS_Store
.luarc.json
mctx_backup_*.mctx
.mctx_chats/
!./run_tests.sh
./*.mctx
collect_info.sh 
get_context_human_written.fish 
create_tests.sh 
refactorate.sh
