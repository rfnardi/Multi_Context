local M = {}
local api = vim.api

M.get_native_injectors = function()
    local ctx = require('multi_context.context_builders')
    return {
        { name = "buffers", description = "Código de todos os buffers abertos", execute = ctx.get_all_buffers_content },
        { name = "git_diff", description = "Alterações não commitadas", execute = ctx.get_git_diff },
        { name = "tree", description = "Árvore do diretório atual", execute = ctx.get_tree_context },
        { name = "folder", description = "Arquivos apenas da pasta atual", execute = ctx.get_folder_context },
        { name = "repo", description = "Todos os arquivos rastreados no Git", execute = ctx.get_repo_context }
    }
end

M.get_custom_injectors = function()
    local custom = {}
    local dir = vim.fn.stdpath("config") .. "/mctx_injectors"
    if vim.fn.isdirectory(dir) == 1 then
        local files = vim.fn.globpath(dir, "*.lua", false, true)
        for _, file in ipairs(files) do
            local chunk, err = loadfile(file)
            if chunk then
                local ok, res = pcall(chunk)
                if ok and type(res) == "table" and type(res.name) == "string" and type(res.execute) == "function" then
                    table.insert(custom, res)
                end
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

M.selector_buf = nil
M.selector_win = nil
M.current_selection = 1
M.api_list = {}
M.parent_win = nil

M.open_selector = function()
    local all = M.get_all_injectors()
    M.api_list = {}
    for k, _ in pairs(all) do table.insert(M.api_list, k) end
    table.sort(M.api_list)
    
    if #M.api_list == 0 then return end
    
    M.parent_win = api.nvim_get_current_win()
    M.current_selection = 1
    M.selector_buf = api.nvim_create_buf(false, true)
    M.selector_win = api.nvim_open_win(M.selector_buf, true, {
        relative = "cursor", row = 1, col = 0, width = 30, height = #M.api_list,
        style = "minimal", border = "rounded",
    })
    vim.bo[M.selector_buf].buftype = "nofile"
    M._render()
    M._keymaps()
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
    local ns = api.nvim_create_namespace("mc_injectors")
    api.nvim_buf_clear_namespace(M.selector_buf, ns, 0, -1)
    api.nvim_buf_add_highlight(M.selector_buf, ns, "ContextSelectorCurrent", M.current_selection - 1, 0, -1)
end

M._keymaps = function()
    if not M.selector_buf or not api.nvim_buf_is_valid(M.selector_buf) then return end
    local mk = function(k, fn) api.nvim_buf_set_keymap(M.selector_buf, "n", k, "", { callback = fn, noremap = true, silent = true }) end
    mk("j", function() M._move(1) end)
    mk("k", function() M._move(-1) end)
    mk("<CR>", M._select)
    mk("<Esc>", M._close)
    mk("q", M._close)
end

M._move = function(dir)
    local n = M.current_selection + dir
    if n >= 1 and n <= #M.api_list then M.current_selection = n; M._render() end
end

M._select = function()
    local name = M.api_list[M.current_selection]
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
        
        -- Como viemos do Insert mode "\|<Esc>", o cursor está posicionado no byte da barra invertida
        local prefix = string.sub(line, 1, col + 1)
        local suffix = string.sub(line, col + 2)
        
        -- Removemos a barra \ de chamada
        if prefix:sub(-1) == "\\" then
            prefix = prefix:sub(1, -2)
        end
        
        if #content_lines == 1 then
            local new_line = prefix .. content_lines[1] .. suffix
            api.nvim_set_current_line(new_line)
            api.nvim_win_set_cursor(0, {row, #prefix + #content_lines[1]})
        else
            local buf = api.nvim_win_get_buf(M.parent_win)
            local replacement = {}
            table.insert(replacement, prefix .. content_lines[1])
            for i = 2, #content_lines - 1 do table.insert(replacement, content_lines[i]) end
            table.insert(replacement, content_lines[#content_lines] .. suffix)
            
            api.nvim_buf_set_lines(buf, row - 1, row, false, replacement)
            api.nvim_win_set_cursor(0, {row + #content_lines - 1, #(content_lines[#content_lines])})
        end
        
        -- Volta pro Insert Mode
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
