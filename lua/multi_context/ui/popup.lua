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
    api.nvim_buf_set_keymap(buf, "i", "\\", "\\<Esc><Cmd>lua require('multi_context.injectors').open_selector()<CR>", km)

    api.nvim_buf_set_keymap(buf, "n", "<A-x>", "<Cmd>lua require('multi_context').ExecuteTools()<CR>", km)
    api.nvim_buf_set_keymap(buf, "i", "<A-x>", "<Esc><Cmd>lua require('multi_context').ExecuteTools()<CR>", km)

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
        title     = " Multi_Context_Chat | ~0 tokens ",
        title_pos = 'center',
    })
    M.popup_win = win

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

function M.update_title()
    if not M.popup_win or not vim.api.nvim_win_is_valid(M.popup_win) then return end
    
    local ok, conf = pcall(vim.api.nvim_win_get_config, M.popup_win)
    if ok and conf.relative and conf.relative ~= "" then
        local utils = require('multi_context.utils')
        
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
