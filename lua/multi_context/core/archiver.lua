local session = require('multi_context.core.session')
local StateManager = require('multi_context.core.state_manager')
local M = {}

M.compress = function(ids_to_cover, summary_text, new_id)
    local msgs = StateManager.get('session_messages') or {}
    
    for _, msg in ipairs(msgs) do
        for _, target_id in ipairs(ids_to_cover) do
            if msg.metadata and msg.metadata.id == target_id then
                msg.metadata.status = "archived"
            end
        end
    end
    
    session.add_message("assistant", summary_text, {
        id = new_id,
        type = "summary",
        status = "active",
        covers = table.concat(ids_to_cover, ",")
    })
end

M.deep_dive = function(target_id)
    local msgs = StateManager.get('session_messages') or {}
    local covers = nil
    
    -- 1. Busca o bloco summary pelo ID para extrair a lista covers
    for _, msg in ipairs(msgs) do
        if msg.metadata and msg.metadata.id == target_id then
            covers = msg.metadata.covers
            break
        end
    end
    
    -- Se não achou ou não tem covers, aborta
    if not covers or covers == "" then
        return "Sistema: Nenhum bloco associado ao ID fornecido ou ID não encontrado. (nenhum bloco)"
    end
    
    local target_ids = vim.split(covers, ",", { plain = true })
    local retrieved_blocks = {}
    
    -- 2. Varre novamente a RAM buscando os blocos cujos IDs estão na lista
    for _, msg in ipairs(msgs) do
        if msg.metadata and msg.metadata.id then
            for _, t_id in ipairs(target_ids) do
                if msg.metadata.id == vim.trim(t_id) then
                    local id = msg.metadata.id
                    local type = msg.metadata.type or "raw"
                    local role = msg.role or "unknown"
                    local status = msg.metadata.status or "archived"
                    
                    -- Reconstrói o bloco XML original
                    local xml = string.format('<block id="%s" type="%s" role="%s" status="%s">\n%s\n</block>', 
                        id, type, role, status, vim.trim(msg.content))
                    table.insert(retrieved_blocks, xml)
                end
            end
        end
    end
    
    if #retrieved_blocks == 0 then
        return "Sistema: Nenhum bloco associado ao ID fornecido foi encontrado em memória. (nenhum bloco)"
    end
    
    return table.concat(retrieved_blocks, "\n\n")
end

return M
