local M = {}

local _state = {}

M.get = function(key)
    if not _state[key] then _state[key] = {} end
    return _state[key]
end

M.set = function(key, value)
    _state[key] = value
end

M.patch = function(key, table_values)
    if type(table_values) ~= "table" then return end
    if type(_state[key]) ~= "table" then _state[key] = {} end
    
    for k, v in pairs(table_values) do
        _state[key][k] = v
    end
end

M.reset = function()
    _state = {}
end

return M
