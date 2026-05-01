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
