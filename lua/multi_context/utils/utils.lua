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
    
    local swarm = require('multi_context.core.swarm_manager')
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
            local swarm = require('multi_context.core.swarm_manager')
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
    api.nvim_buf_set_keymap(new_buf, "i", "\\", "\\<Esc><Cmd>lua require('multi_context.ecosystem.injectors').open_selector()<CR>", km)
    vim.api.nvim_buf_set_keymap(new_buf, "n", "<A-x>", "<Cmd>lua require('multi_context.core.react_orchestrator').ExecuteTools(nil, vim.api.nvim_get_current_buf())<CR>", km)
    vim.api.nvim_buf_set_keymap(new_buf, "i", "<A-x>", "<Esc><Cmd>lua require('multi_context.core.react_orchestrator').ExecuteTools(nil, vim.api.nvim_get_current_buf())<CR>", km)

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






