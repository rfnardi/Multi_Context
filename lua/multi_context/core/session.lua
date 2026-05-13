local StateManager = require('multi_context.core.state_manager')
local M = {}

M.clear = function()
    StateManager.set('session_messages', {})
end

M.add_message = function(role, content, metadata)
    local safe_content = vim.trim(content or "")
    if safe_content == "" then return end
    
    local msgs = StateManager.get('session_messages') or {}
    table.insert(msgs, { role = role, content = safe_content, metadata = metadata or {} })
    StateManager.set('session_messages', msgs)
end

M.get_messages = function()
    return vim.deepcopy(StateManager.get('session_messages') or {})
end

M.build_payload = function(system_prompt)
    local config = require('multi_context.config')
    local utils = require('multi_context.utils.utils')
    local final_sys = system_prompt or ''
    if config.options.auto_inject_context_md then
        local ctx_path = utils.get_context_md_path()
        if ctx_path then
            local lines = vim.fn.readfile(ctx_path)
            local ctx_content = table.concat(lines, '\n')
            final_sys = final_sys .. '\n\n=== CONTEXT.md (Active Memory) ===\n' .. ctx_content
        end
    end
    local payload = {}
    if final_sys ~= '' then table.insert(payload, { role = 'system', content = final_sys }) end
    for _, m in ipairs(M.get_messages()) do 
        if not m.metadata or m.metadata.status ~= 'archived' then
            table.insert(payload, { role = m.role, content = m.content })
        end
    end
    return payload
end

M.sync_from_lines = function(lines)
    M.clear()
    if not lines or #lines == 0 then return end
    
    local xml_content = table.concat(lines, "\n")
    
    for tag_attrs, raw_inner_content in xml_content:gmatch('<block(.-)>(.-)</block>') do
        local id = tag_attrs:match('id="([^"]+)"')
        local type = tag_attrs:match('type="([^"]+)"')
        local role = tag_attrs:match('role="([^"]+)"')
        local status = tag_attrs:match('status="([^"]+)"')
        local covers = tag_attrs:match('covers="([^"]*)"')
        
        local meta = { id = id, type = type, status = status }
        if covers and covers ~= "" then meta.covers = covers end
        
        local final_content = raw_inner_content
        local abstract_content = raw_inner_content:match('<abstract>(.-)</abstract>')
        
        if abstract_content then
            local kw = abstract_content:match('<key_words>(.-)</key_words>')
            local summ = abstract_content:match('<summary>(.-)</summary>')
            meta.abstract = {
                key_words = kw and vim.trim(kw) or "",
                summary = summ and vim.trim(summ) or ""
            }
        end
        
        local explicit_content = raw_inner_content:match('<content>(.-)</content>')
        if explicit_content then
            final_content = explicit_content
        end
        
        M.add_message(role, final_content, meta)
    end
end

return M
