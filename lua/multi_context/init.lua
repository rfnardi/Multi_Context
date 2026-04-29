local api = vim.api
local utils = require('multi_context.utils.utils')
local popup = require('multi_context.ui.popup')
local commands = require('multi_context.commands')
local config = require('multi_context.config')

local tool_parser = require('multi_context.ecosystem.tool_parser')
local tool_runner = require('multi_context.ecosystem.tool_runner')
local prompt_parser = require('multi_context.llm.prompt_parser')
local scroller = require('multi_context.ui.scroller')

local M = {}
M.popup_buf = popup.popup_buf
M.popup_win = popup.popup_win
M.current_workspace_file = nil

M.setup = function(opts)
    if config and config.setup then config.setup(opts) end
    require('multi_context.core.react_orchestrator').setup()
end

M.OnSwarmComplete = function(summary)
    local p = require('multi_context.ui.popup')
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
    local user_prefix = "## " .. (cfg.options.user_name or "Nardi") .. " >>"
    
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
    local p = require('multi_context.ui.popup')
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
    local ui_popup = require('multi_context.ui.popup')
    local is_popup = (ui_popup.popup_win and vim.api.nvim_win_is_valid(ui_popup.popup_win) and vim.api.nvim_get_current_win() == ui_popup.popup_win)
    if is_popup then
        vim.api.nvim_win_hide(ui_popup.popup_win)
        local new_filename, content = utils.build_workspace_content(ui_popup.popup_buf, M.current_workspace_file)
        M.current_workspace_file = utils.export_to_workspace(content, new_filename)
    else
        local cur_buf = vim.api.nvim_get_current_buf()
        if vim.api.nvim_buf_get_name(cur_buf):match(".mctx$") then
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

M.TerminateTurn = function()
    react_orchestrator.reset_turn()
    local p = require('multi_context.ui.popup')
    local buf = p.popup_buf
    if not buf or not vim.api.nvim_buf_is_valid(buf) then return end
    
    local cfg = require('multi_context.config')
    local current_api = cfg.get_current_api()
    local user_prefix = "## " .. (cfg.options.user_name or "Nardi") .. " >>"
    
    local next_prompt_lines = { "", "## API atual: " .. current_api, user_prefix .. " " }
    
    local auto_trigger_queue = false
    if StateManager.get('react').queued_tasks and StateManager.get('react').queued_tasks ~= "" then
        if StateManager.get('react').is_queue_mode then
            auto_trigger_queue = true
            for _, q_line in ipairs(vim.split(StateManager.get('react').queued_tasks, "\n")) do table.insert(next_prompt_lines, q_line) end
        else
            table.insert(next_prompt_lines, require("multi_context.i18n").t("checkpoint"))
            for _, q_line in ipairs(vim.split(StateManager.get('react').queued_tasks, "\n")) do table.insert(next_prompt_lines, q_line) end
        end
        StateManager.get('react').queued_tasks = nil
    else
        StateManager.get('react').is_queue_mode = false
    end
    
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, next_prompt_lines)
    p.create_folds(buf)
    require('multi_context.ui.highlights').apply_chat(buf)
    p.update_title()
    
    if p.popup_win and vim.api.nvim_win_is_valid(p.popup_win) then
        pcall(vim.api.nvim_win_set_cursor, p.popup_win, { vim.api.nvim_buf_line_count(buf), 0 })
        vim.cmd("normal! zz"); vim.cmd("startinsert!")
    end

    if auto_trigger_queue then
        vim.cmd("stopinsert")
        vim.defer_fn(function() require('multi_context.core.event_bus').emit('USER_SUBMIT', { buf = buf }) end, 100)
    end
end

local function get_context_md_content()
    local root = vim.fn.system("git rev-parse --show-toplevel")
    if vim.v.shell_error == 0 then root = root:gsub("\n", "") else root = vim.fn.getcwd() end
    local filepath = root .. "/CONTEXT.md"
    if vim.fn.filereadable(filepath) == 1 then return table.concat(vim.fn.readfile(filepath), "\n") end
    return nil
end

function M.ExecuteTools(ia_idx)
    local p = require('multi_context.ui.popup')
    local buf = p.popup_buf
    if not buf or not vim.api.nvim_buf_is_valid(buf) then buf = vim.api.nvim_get_current_buf() end

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

        has_changes = true

        do
            local tag_output, should_abort, cont_loop, rew_content, backup_made = tool_runner.execute(
                parsed_tag, 
                StateManager.get('react').is_autonomous, 
                approve_all_ref, 
                buf
            )

            if backup_made then require('multi_context.core.state_manager').get('react').last_backup = backup_made end
            if rew_content then pending_rewrite_content = rew_content end
            if cont_loop then should_continue_loop = true end

            if should_abort then
                abort_all = true
                new_content = new_content .. parsed_tag.raw_tag .. parsed_tag.inner .. "</tool_call>"
            else
                new_content = new_content .. tag_output
                if tag_output:match(">%[Sistema%]: ERRO %- Ferramenta") then
                    StateManager.get('react').is_autonomous = false
                    should_continue_loop = false
                end
            end
        end

        ::continue::
        cursor = parsed_tag.close_end + 1
    end

    if not has_changes or abort_all then M.TerminateTurn(); return end

    if pending_rewrite_content then
        local rewrite_lines = vim.split(pending_rewrite_content, "\n", {plain=true})
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, rewrite_lines)
    else
        local final_lines = {}
        for _, l in ipairs(prefix_lines) do table.insert(final_lines, l) end
        for _, l in ipairs(vim.split(new_content, "\n", {plain=true})) do table.insert(final_lines, l) end
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, final_lines)
    end

    if pending_rewrite_content or (not should_continue_loop and not StateManager.get('react').is_autonomous) then
        M.TerminateTurn(); return
    end

    if react_orchestrator.check_circuit_breaker() then
        M.TerminateTurn(); return
    end

    local cfg = require('multi_context.config')
    local user_prefix = "## " .. (cfg.options.user_name or "Nardi") .. " >>"
    
    local sys_msg = require("multi_context.i18n").t("sys_info_collected")
    if not should_continue_loop and StateManager.get('react').is_autonomous then
        sys_msg = require("multi_context.i18n").t("sys_action_executed")
    end

    local b_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    table.insert(b_lines, ""); table.insert(b_lines, user_prefix .. " " .. sys_msg)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, b_lines)
    require('multi_context.ui.highlights').apply_chat(buf)

    vim.defer_fn(function() require('multi_context.core.event_bus').emit('USER_SUBMIT', { buf = buf }) end, 100)
end

vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
        if _G.MultiContextTempFiles then for _, f in ipairs(_G.MultiContextTempFiles) do pcall(os.remove, f) end end
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
command! -nargs=0 ContextReloadSkills lua require('multi_context.ecosystem.skills_manager').load_skills(); vim.notify('Skills customizadas recarregadas!', vim.log.levels.INFO)
]])

M.HandleArchivistCompression = function(ia_idx)
    local p = require('multi_context.ui.popup')
    local buf = p.popup_buf
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
    local user_prefix = "## " .. (cfg.options.user_name or "Nardi") .. " >>"
    
    local new_lines = { require("multi_context.i18n").t("quad_memory") }
    
    local function append_split(txt)
        if not txt then return end
        for _, l in ipairs(vim.split(txt, "\n", {plain=true})) do table.insert(new_lines, l) end
    end
    
    append_split("<genesis>\n" .. vim.trim(genesis) .. "\n</genesis>\n")
    append_split("<plan>\n" .. vim.trim(plan) .. "\n</plan>\n")
    append_split("<journey>\n" .. vim.trim(journey) .. "\n</journey>\n")
    append_split("<now>\n" .. vim.trim(now) .. "\n</now>\n")
    
    append_split(user_prefix .. " " .. (StateManager.get('react').pending_user_prompt or ""))
    
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, new_lines)
    
    require('multi_context.utils.memory_tracker').reset()
    StateManager.get('react').pending_user_prompt = nil
    StateManager.get('react').active_agent = nil
    
    require('multi_context.ui.highlights').apply_chat(buf)
    p.create_folds(buf)
    p.update_title()
    
    vim.notify(require("multi_context.i18n").t("archivist_compressed"), vim.log.levels.INFO)
    vim.defer_fn(function() require('multi_context.core.event_bus').emit('USER_SUBMIT', { buf = buf }) end, 100)
end

return M
