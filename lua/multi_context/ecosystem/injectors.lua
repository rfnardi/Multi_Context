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
    local all = M.get_all_injectors()
    local injector = all[name]
    
    M._close_win_only()
    
    if M.parent_win and api.nvim_win_is_valid(M.parent_win) then
        api.nvim_set_current_win(M.parent_win)
        
        local content = ""
        if injector and type(injector.execute) == "function" then
            content = injector.execute() or ""
        end
        
        local content_lines = vim.split(content, "\n", {plain = true})
        local row, col = unpack(api.nvim_win_get_cursor(0))
        local line = api.nvim_get_current_line()
        
        local prefix = string.sub(line, 1, col + 1)
        local suffix = string.sub(line, col + 2)
        if prefix:sub(-1) == "\\" then prefix = prefix:sub(1, -2) end
        
        api.nvim_set_current_line(prefix .. suffix)
        
        api.nvim_buf_set_lines(api.nvim_win_get_buf(M.parent_win), row, row, false, content_lines)
        
        api.nvim_win_set_cursor(0, {row + #content_lines, #(content_lines[#content_lines])})
        
        api.nvim_feedkeys("a", "n", true)
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
        api.nvim_feedkeys("a", "n", true) 
    end
end
return M
