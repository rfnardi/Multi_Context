local session = require('multi_context.core.session')
local archiver = require('multi_context.core.archiver')
local EventBus = require('multi_context.core.event_bus')

local M = {}

M.build_background_payload = function()
    local payload = {}
    table.insert(payload, { 
        role = "system", 
        content = "Você é um arquivista de background. Sua tarefa é ler o histórico a seguir e gerar um resumo estritamente descritivo, mantendo os detalhes técnicos e operacionais. Não use formatação markdown e não invente fatos." 
    })
    
    local msgs = session.get_messages()
    local content_to_summarize = {}
    
    for _, msg in ipairs(msgs) do
        if msg.metadata and msg.metadata.status ~= "archived" and msg.metadata.type ~= "summary" then
            table.insert(content_to_summarize, string.format("[%s]: %s", msg.role, msg.content))
        end
    end
    
    table.insert(payload, { role = "user", content = table.concat(content_to_summarize, "\n\n") })
    return payload
end

M.on_background_response_received = function(ids_to_cover, summary_text)
    local new_id = "summary_" .. os.date("%H%M%S")
    archiver.compress(ids_to_cover, summary_text, new_id)
    
    -- Emite o evento para a UI (chat_view.lua) aplicar o Conceal e re-dobrar o texto automaticamente
    EventBus.emit("UI_ARCHIVIST_DONE", { buf = vim.api.nvim_get_current_buf() })
end

return M
