local api = vim.api
local utils = require('multi_context.utils.utils')
local popup = require('multi_context.ui.chat_view')
local commands = require('multi_context.commands')
local config = require('multi_context.config')
local react_orchestrator = require('multi_context.core.react_orchestrator')

local M = {}
M.popup_buf = popup.popup_buf
M.popup_win = popup.popup_win
M.current_workspace_file = nil

M.setup = function(opts)
    if config and config.setup then config.setup(opts) end
    react_orchestrator.setup()
end

M.OnSwarmComplete = function(summary)
    local p = require('multi_context.ui.chat_view')
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
    local p = require('multi_context.ui.chat_view')
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
    local ui_popup = require('multi_context.ui.chat_view')
    local is_popup = (ui_popup.popup_win and vim.api.nvim_win_is_valid(ui_popup.popup_win) and vim.api.nvim_get_current_win() == ui_popup.popup_win)
    if is_popup then
        vim.api.nvim_win_hide(ui_popup.popup_win)
        local new_filename, content = utils.build_workspace_content(ui_popup.popup_buf, M.current_workspace_file)
        M.current_workspace_file = utils.export_to_workspace(content, new_filename)
    else
        local cur_buf = vim.api.nvim_get_current_buf()
        if vim.api.nvim_buf_get_name(cur_buf):match("%.mctx$") then
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

return M
