local StateManager = require('multi_context.core.state_manager')
local M = {}

M.clear = function()
    StateManager.set('session_messages', {})
end

M.add_message = function(role, content, metadata)
    local safe_content = vim.trim(content or "")
    if safe_content == "" then return end
    
    local msgs = StateManager.get('session_messages') or {}
    metadata = metadata or {}
    
    -- REGRA DE OURO: Se tem ID, é um bloco discreto XML, NUNCA concatena.
    -- Se não tem ID, é fluxo antigo (gerado pelo user programaticamente), então concatena se for o mesmo role.
    if not metadata.id and #msgs > 0 and msgs[#msgs].role == role then
        msgs[#msgs].content = msgs[#msgs].content .. "\n\n" .. safe_content
    else
        table.insert(msgs, { role = role, content = safe_content, metadata = metadata })
    end
    StateManager.set('session_messages', msgs)
end

M.get_messages = function()
    return vim.deepcopy(StateManager.get('session_messages') or {})
end

M.build_payload = function(system_prompt)
    local payload = {}
    if system_prompt then table.insert(payload, { role = "system", content = system_prompt }) end
    
    for _, m in ipairs(M.get_messages()) do 
        if not m.metadata or m.metadata.status ~= "archived" then
            table.insert(payload, { role = m.role, content = m.content })
        end
    end
    return payload
end

M.sync_from_lines = function(lines)
    M.clear()
    if not lines or #lines == 0 then return end
    
    local xml_content = table.concat(lines, "\n")
    
    -- Regex tolerante para XML multiline
    for tag_attrs, content in xml_content:gmatch('<block(.-)>(.-)</block>') do
        local id = tag_attrs:match('id="([^"]+)"')
        local type = tag_attrs:match('type="([^"]+)"')
        local role = tag_attrs:match('role="([^"]+)"')
        local status = tag_attrs:match('status="([^"]+)"')
        local covers = tag_attrs:match('covers="([^"]*)"')
        
        local meta = { id = id, type = type, status = status }
        if covers and covers ~= "" then meta.covers = covers end
        
        M.add_message(role, content, meta)
    end
end

return M
