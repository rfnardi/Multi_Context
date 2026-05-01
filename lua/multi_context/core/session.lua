local StateManager = require('multi_context.core.state_manager')
local M = {}

M.clear = function()
    StateManager.set('session_messages', {})
end

M.add_message = function(role, content, metadata)
    local msgs = StateManager.get('session_messages')
    if not msgs or type(msgs) ~= "table" then 
        msgs = {}
        StateManager.set('session_messages', msgs)
    end
    
    content = vim.trim(content or "")
    if content == "" then return end
    
    -- MÁGICA: Se o papel for o mesmo do anterior, concatena em vez de criar novo node
    -- Isso evita o erro de "roles sequenciais duplicados" de APIs como a Anthropic
    if #msgs > 0 and msgs[#msgs].role == role then
        msgs[#msgs].content = msgs[#msgs].content .. "\n\n" .. content
        if metadata then msgs[#msgs].metadata = metadata end
    else
        table.insert(msgs, { role = role, content = content, metadata = metadata or {} })
    end
end

M.get_messages = function()
    local msgs = StateManager.get('session_messages')
    if not msgs then return {} end
    return vim.deepcopy(msgs)
end

M.build_payload = function(system_prompt)
    local payload = {}
    if system_prompt then table.insert(payload, { role = "system", content = system_prompt }) end
    for _, m in ipairs(M.get_messages()) do 
        table.insert(payload, { role = m.role, content = m.content }) 
    end
    return payload
end

-- Backward Compatibility: Lê o buffer visual para RAM permitindo a edição manual no neovim
M.sync_from_lines = function(lines)
    M.clear()
    if not lines or #lines == 0 then return end
    
    local role = nil
    local acc = {}
    local orphaned = {}
    local user_pat = "^##%s*([%w_]+)%s*>>"
    local ia_pat   = "^##%s*IA.*>>"
    
    local function flush()
        if role and #acc > 0 then
            local text = table.concat(acc, "\n"):match("^%s*(.-)%s*$")
            if text ~= "" then
                -- Injeções órfãs (ex: Git Diff) vão para a primeira mensagem do usuário
                if role == "user" and #orphaned > 0 then
                    text = table.concat(orphaned, "\n") .. "\n\n" .. text
                    orphaned = {}
                end
                M.add_message(role, text)
            end
        end
        acc = {}
    end

    for _, line in ipairs(lines) do
        if line:match(ia_pat) then
            flush(); role = "assistant"
        elseif line:match(user_pat) then
            flush(); role = "user"
            local body = line:gsub(user_pat .. "%s*", "")
            if body ~= "" then table.insert(acc, body) end
        elseif not line:match("^## API atual:") then
            if role then 
                table.insert(acc, line) 
            else
                if line:match("%S") then table.insert(orphaned, line) end
            end
        end
    end
    flush()
    
    if #orphaned > 0 then
        local text = table.concat(orphaned, "\n"):match("^%s*(.-)%s*$")
        if text ~= "" then M.add_message("user", text) end
    end
end

return M
