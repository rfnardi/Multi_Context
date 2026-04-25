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
    local disk_cfg = M.load_api_config()
    if disk_cfg then
        if disk_cfg.watchdog then M.options.watchdog = vim.deepcopy(disk_cfg.watchdog) end
        if disk_cfg.cognitive_horizon then M.options.cognitive_horizon = disk_cfg.cognitive_horizon end
        if disk_cfg.user_tolerance then M.options.user_tolerance = disk_cfg.user_tolerance end
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






