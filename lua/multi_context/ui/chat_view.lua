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
    
    -- FASE 42.5: Ocultação NATIVA do Neovim para XML
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
    local preview = ""
    for i = vim.v.foldstart, vim.v.foldend do
        local l = vim.fn.getline(i)
        l = l:gsub("<[^>]+>", "") -- Limpa as tags na preview
        if l:match("%S") then
            preview = vim.trim(l)
            break
        end
    end
    return " 📦 [" .. lines_count .. " linhas arquivadas] " .. preview
end

function M.create_folds(buf)
    if not buf or not api.nvim_buf_is_valid(buf) then return end
    vim.schedule(function()
        if not api.nvim_buf_is_valid(buf) then return end
        local windows = vim.fn.win_findbuf(buf)
        for _, win in ipairs(windows) do
            if api.nvim_win_is_valid(win) then
                vim.api.nvim_win_call(win, function()
                    vim.wo.foldmethod = "manual"
                    vim.wo.foldenable = true -- OBRIGATÓRIO PARA TESTES HEADLESS!
                    vim.wo.foldtext = "v:lua.require('multi_context.ui.chat_view').fold_text()"
                    pcall(vim.cmd, 'normal! zE')

                    local total_lines = vim.api.nvim_buf_line_count(buf)
                    local in_archived = false
                    local start_fold = -1

                    for lnum = 1, total_lines do
                        local line = vim.api.nvim_buf_get_lines(buf, lnum - 1, lnum, false)[1]
                        if line then
                            if line:match('<block.-status="archived"') then
                                in_archived = true
                                start_fold = lnum
                            elseif line:match('</block>') and in_archived then
                                if lnum >= start_fold then
                                    pcall(vim.cmd, string.format("%d,%dfold", start_fold, lnum))
                                    pcall(vim.cmd, string.format("%dfoldclose", start_fold))
                                end
                                in_archived = false
                            end
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
