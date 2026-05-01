local Session = require('multi_context.core.session')
local M = {}
local api = vim.api
local user_pat = "^##%s*([%w_]+)%s*>>"

local ia_pat = "^##%s*IA.*>>"
M.find_last_user_line = function(buf)
    local lines = api.nvim_buf_get_lines(buf, 0, -1, false)
    for i = #lines, 1, -1 do
        if lines[i]:match(user_pat) and not lines[i]:match(ia_pat) then return i - 1, lines[i] end
    end
    return nil
end

M.build_history = function(buf_or_lines)
    local lines = type(buf_or_lines) == "table" and buf_or_lines or api.nvim_buf_get_lines(buf_or_lines, 0, -1, false)
    Session.sync_from_lines(lines)
    return Session.get_messages()
end

return M
