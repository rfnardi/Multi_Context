local config = require('multi_context.config')
local api = vim.api

local M = {}

M.state = {
    sections = {
        { id = "apis", title = "[1] PROVEDORES DE REDE E APIS", expanded = false },
        { id = "swarm", title = "[2] ORQUESTRAÇÃO DE SWARM (MOA)", expanded = false },
        { id = "watchdog", title = "[3] GUARDIÃO DE CONTEXTO (WATCHDOG)", expanded = false },
        { id = "limits", title = "[4] COMPORTAMENTO E LIMITES GLOBAIS", expanded = false },
        { id = "gatekeeper", title = "[5] PERFIS E PERMISSÕES (GATEKEEPER)", expanded = false },
        { id = "skills", title = "[6] ECOSSISTEMA DE SKILLS LOCAIS", expanded = false }
    },
    apis = {}, default_api = "", fallback_mode = true,
    watchdog = {}, horizon = 4000, tolerance = 1.0,
    identity = "User", max_loops = 15,
    agents = {}, expanded_agents = {},
    all_skills = {},
    clipboard_api = nil
}

M.line_map = {}
M.buf = nil; M.win = nil

M.reset_state = function()
    if M.state and M.state.sections then
        for _, s in ipairs(M.state.sections) do s.expanded = false end
    end
    M.state.expanded_agents = {}
end

M.init_state = function()
    M.reset_state()
    local cfg = config.load_api_config() or { apis = {} }
    M.state.apis = vim.deepcopy(cfg.apis)
    M.state.default_api = cfg.default_api or ""
    M.state.fallback_mode = cfg.fallback_mode ~= false

    M.state.watchdog = vim.deepcopy(config.options.watchdog or {})
    M.state.horizon = config.options.cognitive_horizon or 4000
    M.state.tolerance = config.options.user_tolerance or 1.0
    M.state.identity = config.options.user_name or "User"
    M.state.max_loops = 15

    local agents = require('multi_context.agents')
    local skills_mgr = require('multi_context.skills_manager')
    M.state.agents = agents.load_agents() or {}
    pcall(skills_mgr.load_skills)
    M.state.all_skills = skills_mgr.get_skills() or {}
    
    local native_tools = {"list_files", "read_file", "search_code", "edit_file", "run_shell", "replace_lines", "apply_diff", "rewrite_chat_buffer", "get_diagnostics", "spawn_swarm", "switch_agent"}
    for _, t in ipairs(native_tools) do M.state.all_skills[t] = { name = t, is_native = true } end
end

M.toggle_section = function(idx)
    if M.state.sections[idx] then M.state.sections[idx].expanded = not M.state.sections[idx].expanded end
end

local function format_row(label, value, total_width)
    local label_len = vim.fn.strdisplaywidth(label)
    local value_len = vim.fn.strdisplaywidth(value)
    local dots_len = total_width - label_len - value_len - 2
    if dots_len < 1 then dots_len = 1 end
    return label .. " " .. string.rep(".", dots_len) .. " " .. value
end

local function add_line(lines, text, action) table.insert(lines, text); if action then M.line_map[#lines] = action end end

M.render = function()
    M.line_map = {}
    local lines = {}
    local w = 62

    add_line(lines, "  MultiContext AI 🤖                                       [v1.0]", nil)
    add_line(lines, "", nil)

    for s_idx, sec in ipairs(M.state.sections) do
        local prefix = sec.expanded and "▼ " or "▶ "
        add_line(lines, prefix .. sec.title, { type = "section", idx = s_idx })
        
        if sec.expanded then
            if sec.id == "apis" then
                add_line(lines, format_row("    Motor Automático de Fallback", M.state.fallback_mode and "●" or "○", w), { type = "toggle_fallback" })
                add_line(lines, "    Lista de Provedores:", nil)
                for i, a in ipairs(M.state.apis) do
                    local mark = (a.name == M.state.default_api) and "●" or "○"
                    add_line(lines, format_row("    ├─ " .. a.name, mark, w), { type = "api_select", name = a.name, idx = i })
                end
            elseif sec.id == "swarm" then
                add_line(lines, "    (Permissão para invocar sub-agentes e prioridade de uso)", nil)
                for i, a in ipairs(M.state.apis) do
                    local mark = a.allow_spawn and "●" or "○"
                    add_line(lines, format_row("    " .. i .. ". " .. a.name .. " (" .. (a.abstraction_level or "medium") .. ")", mark, w), { type = "api_spawn", idx = i })
                end
            elseif sec.id == "watchdog" then
                local wd = M.state.watchdog
                local m_disp = wd.mode and (wd.mode:sub(1,1):upper() .. wd.mode:sub(2)) or "Off"
                add_line(lines, format_row("    Status da Interceptação", "[ " .. m_disp .. " ]", w), { type = "wd_mode" })
                add_line(lines, format_row("    Gatilho (Limiar)", M.state.horizon .. " tokens", w), { type = "wd_horizon" })
                add_line(lines, format_row("    Tolerância do Usuário", tostring(M.state.tolerance), w), { type = "wd_tolerance" })
                local strat = "Semântico"
                if wd.strategy == "percent" then strat = "Percentual" elseif wd.strategy == "fixed" then strat = "Fixo" end
                add_line(lines, format_row("    Estratégia", "[ " .. strat .. " ]", w), { type = "wd_strategy" })
                
                if wd.strategy == "percent" then
                    add_line(lines, format_row("    Alvo Percentual", math.floor((wd.percent or 0.3) * 100) .. "%", w), { type = "wd_percent" })
                elseif wd.strategy == "fixed" then
                    add_line(lines, format_row("    Alvo Fixo", (wd.fixed_target or 1500) .. " tokens", w), { type = "wd_fixed" })
                end
            elseif sec.id == "limits" then
                add_line(lines, format_row("    Identidade no Chat", "[ " .. M.state.identity .. " ]", w), { type = "limit_identity" })
                add_line(lines, format_row("    Limite Autônomo (ReAct)", M.state.max_loops .. " turnos", w), { type = "limit_loops" })
            elseif sec.id == "gatekeeper" then
                add_line(lines, "    (Aperte <CR> num agente para configurar suas skills)", nil)
                local agent_names = {}
                for n, _ in pairs(M.state.agents) do table.insert(agent_names, n) end
                table.sort(agent_names)

                for _, ag_name in ipairs(agent_names) do
                    local is_exp = M.state.expanded_agents[ag_name]
                    add_line(lines, "    " .. (is_exp and "▼ " or "▶ ") .. ag_name, { type = "agent_expand", name = ag_name })
                    if is_exp then
                        local ag_data = M.state.agents[ag_name]
                        local ag_skills = ag_data.skills or {}
                        
                        local skill_names = {}
                        for sn, _ in pairs(M.state.all_skills) do table.insert(skill_names, sn) end
                        table.sort(skill_names)

                        for _, sn in ipairs(skill_names) do
                            local has_skill = false
                            for _, s in ipairs(ag_skills) do if s == sn then has_skill = true; break end end
                            add_line(lines, format_row("      ├─ " .. sn, has_skill and "●" or "○", w), { type = "agent_skill_toggle", agent = ag_name, skill = sn })
                        end
                        add_line(lines, format_row("      └─ Abstraction Level", "[ " .. (ag_data.abstraction_level or "high") .. " ]", w), { type = "agent_level", name = ag_name })
                    end
                end
                add_line(lines, "    [ + Criar Novo Agente ]", { type = "create_agent" })
            elseif sec.id == "skills" then
                add_line(lines, "    (Aperte 'e' sobre uma skill para editar seu código)", nil)
                local skill_names = {}
                for sn, _ in pairs(M.state.all_skills) do table.insert(skill_names, sn) end
                table.sort(skill_names)
                
                for _, sn in ipairs(skill_names) do
                    local sk = M.state.all_skills[sn]
                    add_line(lines, format_row("    " .. sn, sk.is_native and "[ Nativa ]" or "[ Custom ]", w), { type = "edit_skill", name = sn })
                end
                add_line(lines, "    [ + Criar Nova Skill ]", { type = "create_skill" })
            end
            add_line(lines, "", nil)
        end
    end

    while #lines < 22 do table.insert(lines, "") end
    table.insert(lines, string.rep("─", w + 2))
    table.insert(lines, "  <CR> Expandir   <Space> Alternar   <c> Alterar   <e> Editar")
    return lines
end

M.update_buffer = function()
    if not M.buf or not api.nvim_buf_is_valid(M.buf) then return end
    vim.bo[M.buf].modifiable = true
    api.nvim_buf_set_lines(M.buf, 0, -1, false, M.render())
    vim.bo[M.buf].modifiable = false
    vim.bo[M.buf].modified = false
    pcall(function() require('multi_context.ui.highlights').apply_controls(M.buf) end)
end

M.handle_cr = function()
    local action = M.line_map[api.nvim_win_get_cursor(0)[1]]
    if not action then return end
    
    if action.type == "section" then 
        M.toggle_section(action.idx)
        M.update_buffer()
    elseif action.type == "agent_expand" then 
        M.state.expanded_agents[action.name] = not M.state.expanded_agents[action.name]
        M.update_buffer()
    elseif action.type == "create_skill" then
        vim.ui.input({ prompt = "Nome da nova Skill (.lua): " }, function(input)
            if not input or input == "" then return end
            input = input:gsub("%.lua$", "")
            local dir = vim.fn.stdpath("config") .. "/mctx_skills"
            if vim.fn.isdirectory(dir) == 0 then vim.fn.mkdir(dir, "p") end
            local path = dir .. "/" .. input .. ".lua"
            
            local boilerplate = {
                "return {",
                "    name = '" .. input .. "',",
                "    description = 'Sua descrição aqui',",
                "    parameters = {",
                "        { name = 'arg1', type = 'string', required = true, desc = 'Descrição do argumento' }",
                "    },",
                "    execute = function(args)",
                "        return 'Resultado da skill'",
                "    end",
                "}"
            }
            vim.fn.writefile(boilerplate, path)
            vim.cmd("edit " .. path)
            vim.notify("Skill criada! Execute :ContextReloadSkills após editar.", vim.log.levels.INFO)
            pcall(api.nvim_win_close, M.win, true)
        end)
    elseif action.type == "create_agent" then
        vim.ui.input({ prompt = "Nome da nova Persona: @" }, function(input)
            if not input or input == "" then return end
            if not M.state.agents[input] then
                M.state.agents[input] = {
                    system_prompt = "Você é um especialista em...",
                    abstraction_level = "high",
                    skills = {}
                }
                M.save_config()
                vim.notify("Agente @" .. input .. " criado! Expanda-o para dar permissões.", vim.log.levels.INFO)
                M.update_buffer()
            end
        end)
    end
end

M.handle_space = function()
    local action = M.line_map[api.nvim_win_get_cursor(0)[1]]
    if not action then return end

    if action.type == "api_select" then M.state.default_api = action.name
    elseif action.type == "toggle_fallback" then M.state.fallback_mode = not M.state.fallback_mode
    elseif action.type == "api_spawn" then M.state.apis[action.idx].allow_spawn = not M.state.apis[action.idx].allow_spawn
    elseif action.type == "wd_mode" then
        local cycles = { off = "ask", ask = "auto", auto = "off" }
        M.state.watchdog.mode = cycles[M.state.watchdog.mode or "off"] or "off"
    elseif action.type == "wd_strategy" then
        local cycles = { semantic = "percent", percent = "fixed", fixed = "semantic" }
        M.state.watchdog.strategy = cycles[M.state.watchdog.strategy or "semantic"] or "semantic"
    elseif action.type == "agent_skill_toggle" then
        local ag = M.state.agents[action.agent]
        if not ag.skills then ag.skills = {} end
        local found_idx = nil
        for i, s in ipairs(ag.skills) do if s == action.skill then found_idx = i; break end end
        if found_idx then table.remove(ag.skills, found_idx) else table.insert(ag.skills, action.skill) end
    end
    M.update_buffer()
end

M.handle_edit = function()
    local action = M.line_map[api.nvim_win_get_cursor(0)[1]]
    if not action then return end

    local function prompt_str(msg, callback)
        vim.ui.input({ prompt = msg }, function(input)
            if input and input ~= "" then callback(input); M.update_buffer() end
        end)
    end

    local function prompt_num(msg, callback)
        prompt_str(msg, function(i) local n = tonumber(i); if n then callback(n) end end)
    end

    if action.type == "wd_horizon" then prompt_num("Novo Gatilho (tokens): ", function(n) M.state.horizon = n end)
    elseif action.type == "wd_tolerance" then prompt_num("Nova Tolerância (ex: 1.0): ", function(n) M.state.tolerance = n end)
    elseif action.type == "wd_percent" then prompt_num("Novo Percentual (ex: 30 para 30%): ", function(n) M.state.watchdog.percent = n / 100 end)
    elseif action.type == "wd_fixed" then prompt_num("Novo Alvo Fixo (tokens): ", function(n) M.state.watchdog.fixed_target = n end)
    elseif action.type == "limit_identity" then prompt_str("Seu Nome: ", function(s) M.state.identity = s end)
    elseif action.type == "limit_loops" then prompt_num("Máximo de Turnos Autônomos: ", function(n) M.state.max_loops = n end)
    elseif action.type == "agent_level" then
        local cycles = { high = "medium", medium = "low", low = "high" }
        local ag = M.state.agents[action.name]
        ag.abstraction_level = cycles[ag.abstraction_level or "high"] or "high"
        M.update_buffer()
    end
end

M.handle_open_file = function()
    local action = M.line_map[api.nvim_win_get_cursor(0)[1]]
    if action and action.type == "edit_skill" then
        if M.state.all_skills[action.name].is_native then
            vim.notify("Essa é uma ferramenta Core. O código não pode ser alterado por aqui.", vim.log.levels.WARN)
            return
        end
        local path = vim.fn.stdpath("config") .. "/mctx_skills/" .. action.name .. ".lua"
        if vim.fn.filereadable(path) == 1 then
            vim.cmd("edit " .. path)
            pcall(api.nvim_win_close, M.win, true)
        end
    end
end

M.handle_dd = function()
    local action = M.line_map[api.nvim_win_get_cursor(0)[1]]
    if action and (action.type == "api_select" or action.type == "api_spawn") then
        M.state.clipboard_api = table.remove(M.state.apis, action.idx)
        M.update_buffer()
    end
end

M.handle_p = function()
    if not M.state.clipboard_api then return end
    local action = M.line_map[api.nvim_win_get_cursor(0)[1]]
    local idx = #M.state.apis + 1
    if action and (action.type == "api_select" or action.type == "api_spawn") then idx = action.idx + 1 end
    table.insert(M.state.apis, idx, M.state.clipboard_api)
    M.state.clipboard_api = nil
    M.update_buffer()
end

M.save_config = function()
    local cfg = config.load_api_config() or { apis = {} }
    cfg.apis = M.state.apis
    cfg.default_api = M.state.default_api
    cfg.fallback_mode = M.state.fallback_mode
    
    cfg.watchdog = vim.deepcopy(M.state.watchdog)
    cfg.cognitive_horizon = M.state.horizon
    cfg.user_tolerance = M.state.tolerance
    config.save_api_config(cfg)
    
    config.options.user_name = M.state.identity
    -- Aqui salvaríamos o max_loops no react_loop, mas manteremos no JSON de fallback no futuro se necessário
    
    -- IAM: Salva os Agentes e Permissões!
    local agents_file = vim.fn.stdpath("config") .. "/mctx_agents.json"
    local raw_json = vim.fn.json_encode(M.state.agents)
    vim.fn.writefile({raw_json}, agents_file)
    pcall(function() vim.fn.system(string.format("echo %s | jq . > %s", vim.fn.shellescape(raw_json), agents_file)) end)

    M._last_saved_cfg = cfg
    vim.notify("Configurações e Permissões salvas!", vim.log.levels.INFO)
end

M.open_panel = function()
    M.init_state()
    for _, b in ipairs(api.nvim_list_bufs()) do if api.nvim_buf_get_name(b):match("MultiContext_Controls$") then pcall(api.nvim_buf_delete, b, { force = true }) end end
    M.buf = api.nvim_create_buf(false, true)
    vim.bo[M.buf].buftype = 'acwrite'
    vim.bo[M.buf].bufhidden = 'wipe'
    vim.bo[M.buf].swapfile = false
    api.nvim_buf_set_name(M.buf, "MultiContext_Controls")
    
    local w, h = 70, 25
    M.win = api.nvim_open_win(M.buf, true, {
        relative = 'editor', width = w, height = h,
        row = math.floor((vim.o.lines - h) / 2), col = math.floor((vim.o.columns - w) / 2),
        border = 'rounded', style = 'minimal'
    })
    
    vim.wo[M.win].cursorline = true; vim.wo[M.win].wrap = false; vim.wo[M.win].number = true; vim.wo[M.win].relativenumber = true
    M.update_buffer()
    
    local km = { noremap = true, silent = true }
    local function map(k, f) api.nvim_buf_set_keymap(M.buf, "n", k, "", { callback = f, noremap = true, silent = true }) end
    
    map("<CR>", M.handle_cr)
    map("<Space>", M.handle_space)
    map("c", M.handle_edit)
    map("e", M.handle_open_file)
    map("dd", M.handle_dd)
    map("p", M.handle_p)
    api.nvim_buf_set_keymap(M.buf, "n", "q", ":q!<CR>", km)
    
    api.nvim_create_autocmd("BufWriteCmd", { buffer = M.buf, callback = M.save_config })
end

return M
