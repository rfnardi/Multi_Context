local M = {}

local function open_with(content)
    local buf, win = require('multi_context.ui.popup').create_popup(content)
    if buf and win then vim.cmd("startinsert!") end
end

M.ContextChatHandler = function(line1, line2)
    local ctx = require('multi_context.utils.context_builders')
    if line1 and line2 and tonumber(line1) ~= tonumber(line2) then
        open_with(ctx.get_visual_selection(line1, line2))
        return
    end
    
    local mode = vim.api.nvim_get_mode().mode
    if mode == 'v' or mode == 'V' then
        open_with(ctx.get_visual_selection())
    else
        -- Modo normal: abre o chat completamente limpo
        open_with("")
    end
end

M.ContextChatFull = function() open_with("") end

M.ContextChatFolder = function()
    open_with(require('multi_context.utils.context_builders').get_folder_context())
end

M.ContextTree = function()
    open_with(require('multi_context.utils.context_builders').get_tree_context())
end

M.ContextChatRepo = function()
    open_with(require('multi_context.utils.context_builders').get_repo_context())
end

M.ContextChatGit = function()
    open_with(require('multi_context.utils.context_builders').get_git_diff())
end

M.ContextControls = function()
    require('multi_context.ui.context_controls').open_panel()
end

M.ContextBuffers  = function()
    open_with(require('multi_context.utils.context_builders').get_all_buffers_content())
end

M.TogglePopup = function()
    local popup = require('multi_context.ui.popup')

    if popup.popup_win and vim.api.nvim_win_is_valid(popup.popup_win) then
        vim.api.nvim_win_hide(popup.popup_win)
        vim.cmd("stopinsert")
        return
    end

    if popup.popup_buf and vim.api.nvim_buf_is_valid(popup.popup_buf) then
        open_with(popup.popup_buf)
    else
        open_with("")
    end
end

return M
