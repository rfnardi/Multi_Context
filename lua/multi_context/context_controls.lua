local config = require('multi_context.config')
local api = vim.api

local M = {}

M.state = {
    sections = {
        { id = "apis", title = "[1] PROVEDORES DE REDE E APIS", expanded = false },
        { id = "swarm", title = "[2] ORQUESTRAÇÃO DE SWARM (MOA) E FALLBACKS", expanded = false },
        { id = "watchdog", title = "[3] GUARDIÃO DE CONTEXTO (WATCHDOG)", expanded = false },
        { id = "skills", title = "[4] STATUS DO SISTEMA E SKILLS", expanded = false }
    },
    apis = {},
    default_api = "",
    watchdog = {},
    horizon = 4000,
    tolerance = 1.0,
    clipboard_api = nil
}

M.line_map = {}
M.buf = nil
M.win = nil

M.init_state = function()
    M.reset_state()
    local cfg = config.load_api_config()
    if cfg then
        M.state.apis = vim.deepcopy(cfg.apis or {})
        M.state.default_api = cfg.default_api or ""
    end
    local wd = config.options.watchdog or {}
    M.state.watchdog = vim.deepcopy(wd)
    M.state.horizon = config.options.cognitive_horizon or 4000
    M.state.tolerance = config.options.user_tolerance or 1.0
end

M.reset_state = function()
    for _, s in ipairs(M.state.sections) do
        s.expanded = false
    end
end

M.toggle_section = function(idx)
    if M.state.sections[idx] then
        M.state.sections[idx].expanded = not M.state.sections[idx].expanded
    end
end

local function add_line(lines, text, action)
    table.insert(lines, text)
    if action then M.line_map[#lines] = action end
end

M.render = function()
    M.line_map = {}
    local lines = {
        "=== ⚙️ MULTICONTEXT CONTROLS ===",
        "(Use j/k para navegar, <Space> para alternar, <CR> expandir, c editar, dd/p mover, :w salvar)",
        ""
    }

    for s_idx, sec in ipairs(M.state.sections) do
        local prefix = sec.expanded and "▼ " or "▶ "
        add_line(lines, prefix .. sec.title, { type = "section", idx = s_idx })
        
        if sec.expanded then
            if sec.id == "apis" then
                for i, a in ipairs(M.state.apis) do
                    local mark = (a.name == M.state.default_api) and "(selecionada)" or ""
                    add_line(lines, "      " .. a.name .. " " .. mark, { type = "api_select", name = a.name, idx = i })
                end
            elseif sec.id == "swarm" then
                for i, a in ipairs(M.state.apis) do
                    local mark = a.allow_spawn and "[x]" or "[ ]"
                    add_line(lines, "      " .. mark .. " " .. a.name, { type = "api_spawn", idx = i })
                end
            elseif sec.id == "watchdog" then
                local wd = M.state.watchdog
                local mode_display = wd.mode and (wd.mode:sub(1,1):upper() .. wd.mode:sub(2)) or "Off"
                add_line(lines, "      Status da Interceptação: [ " .. mode_display .. " ]  (Off | Ask | Auto)", { type = "wd_mode" })
                add_line(lines, "      Gatilho (Limiar):        " .. M.state.horizon .. " tokens", { type = "wd_horizon" })
                add_line(lines, "      Tolerância:              " .. M.state.tolerance, { type = "wd_tolerance" })
                add_line(lines, "", nil)
                add_line(lines, "      --- Motor de Compressão (@archivist) ---", nil)
                
                local strat_display = "Semântico"
                if wd.strategy == "percent" then strat_display = "Percentual"
                elseif wd.strategy == "fixed" then strat_display = "Fixo" end
                
                add_line(lines, "      Estratégia:[ " .. strat_display .. " ]  (Semântico | Percentual | Fixo)", { type = "wd_strategy" })
                
                if wd.strategy == "percent" then
                    add_line(lines, "      Alvo Percentual:         " .. math.floor((wd.percent or 0.3) * 100) .. "% do chat atual", { type = "wd_percent" })
                elseif wd.strategy == "fixed" then
                    add_line(lines, "      Alvo (Fixo):             " .. (wd.fixed_target or 1500) .. " tokens", { type = "wd_fixed" })
                end
            elseif sec.id == "skills" then
                local ok, skills_mgr = pcall(require, 'multi_context.skills_manager')
                local count = 0
                if ok then
                    local loaded = skills_mgr.get_skills()
                    for _ in pairs(loaded) do count = count + 1 end
                end
                add_line(lines, "      Skills Carregadas: " .. count, nil)
            end
            add_line(lines, "", nil)
        end
    end

    return lines
end

M.update_buffer = function()
    if not M.buf or not api.nvim_buf_is_valid(M.buf) then return end
    local lines = M.render()
    vim.bo[M.buf].modifiable = true
    api.nvim_buf_set_lines(M.buf, 0, -1, false, lines)
    vim.bo[M.buf].modifiable = false
end

M.handle_cr = function()
    local row = api.nvim_win_get_cursor(0)[1]
    local action = M.line_map[row]
    if action and action.type == "section" then
        M.toggle_section(action.idx)
        M.update_buffer()
    end
end

M.handle_space = function()
    local row = api.nvim_win_get_cursor(0)[1]
    local action = M.line_map[row]
    if not action then return end

    if action.type == "api_select" then
        M.state.default_api = action.name
    elseif action.type == "api_spawn" then
        M.state.apis[action.idx].allow_spawn = not M.state.apis[action.idx].allow_spawn
    elseif action.type == "wd_mode" then
        local cycles = { off = "ask", ask = "auto", auto = "off" }
        M.state.watchdog.mode = cycles[M.state.watchdog.mode or "off"] or "off"
    elseif action.type == "wd_strategy" then
        local cycles = { semantic = "percent", percent = "fixed", fixed = "semantic" }
        M.state.watchdog.strategy = cycles[M.state.watchdog.strategy or "semantic"] or "semantic"
    end
    M.update_buffer()
end

M.handle_edit = function()
    local row = api.nvim_win_get_cursor(0)[1]
    local action = M.line_map[row]
    if not action then return end

    local function prompt_num(msg, callback)
        vim.ui.input({ prompt = msg }, function(input)
            if input then
                local num = tonumber(input)
                if num then callback(num); M.update_buffer() end
            end
        end)
    end

    if action.type == "wd_horizon" then
        prompt_num("Novo Gatilho (tokens): ", function(n) M.state.horizon = n end)
    elseif action.type == "wd_tolerance" then
        prompt_num("Nova Tolerância (ex: 1.0): ", function(n) M.state.tolerance = n end)
    elseif action.type == "wd_percent" then
        prompt_num("Novo Percentual (ex: 30 para 30%): ", function(n) M.state.watchdog.percent = n / 100 end)
    elseif action.type == "wd_fixed" then
        prompt_num("Novo Alvo Fixo (tokens): ", function(n) M.state.watchdog.fixed_target = n end)
    end
end

M.handle_dd = function()
    local row = api.nvim_win_get_cursor(0)[1]
    local action = M.line_map[row]
    if action and (action.type == "api_select" or action.type == "api_spawn") then
        M.state.clipboard_api = table.remove(M.state.apis, action.idx)
        M.update_buffer()
    end
end

M.handle_p = function()
    if not M.state.clipboard_api then return end
    local row = api.nvim_win_get_cursor(0)[1]
    local action = M.line_map[row]
    local idx = #M.state.apis + 1
    if action and (action.type == "api_select" or action.type == "api_spawn") then
        idx = action.idx + 1
    end
    table.insert(M.state.apis, idx, M.state.clipboard_api)
    M.state.clipboard_api = nil
    M.update_buffer()
end

M.save_config = function()
    local cfg = config.load_api_config() or { apis = {} }
    cfg.apis = M.state.apis
    cfg.default_api = M.state.default_api
    config.save_api_config(cfg)

    config.options.watchdog = vim.deepcopy(M.state.watchdog)
    config.options.cognitive_horizon = M.state.horizon
    config.options.user_tolerance = M.state.tolerance
    
    if M.buf and vim.api.nvim_buf_is_valid(M.buf) then
        vim.bo[M.buf].modified = false
    end
    vim.notify("Configurações salvas e aplicadas em tempo real!", vim.log.levels.INFO)
end

M.open_panel = function()
    M.init_state()
    for _, b in ipairs(api.nvim_list_bufs()) do if api.nvim_buf_get_name(b):match("MultiContext_Controls$") then pcall(api.nvim_buf_delete, b, { force = true }) end end
    M.buf = api.nvim_create_buf(false, true)
    
    vim.bo[M.buf].buftype = 'acwrite'
    api.nvim_buf_set_name(M.buf, "MultiContext_Controls")
    
    M.update_buffer()
    
    local width = 70
    local height = 25
    M.win = api.nvim_open_win(M.buf, true, {
        relative = 'editor', width = width, height = height,
        row = math.floor((vim.o.lines - height) / 2),
        col = math.floor((vim.o.columns - width) / 2),
        border = 'rounded', style = 'minimal'
    })

    local km = { noremap = true, silent = true }
    local function map(k, f) api.nvim_buf_set_keymap(M.buf, "n", k, "", { callback = f, noremap = true, silent = true }) end
    
    map("<CR>", M.handle_cr)
    map("<Space>", M.handle_space)
    map("c", M.handle_edit)
    map("dd", M.handle_dd)
    map("p", M.handle_p)
    api.nvim_buf_set_keymap(M.buf, "n", "q", ":q!<CR>", km)

    api.nvim_create_autocmd("BufWriteCmd", {
        buffer = M.buf,
        callback = M.save_config
    })
end

return M
