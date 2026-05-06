#!/bin/bash

echo "🚀 Iniciando Refatoração Final (GREEN) - Fase 44.2: JIT Micro-Archiving Dispatcher..."

cat << 'EOF' > lua/multi_context/core/dynamic_watchdog.lua
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
    EventBus.emit("UI_ARCHIVIST_DONE", { buf = vim.api.nvim_get_current_buf() })
end

M.build_jit_payload = function(msg_content)
    return {
        {
            role = "system",
            content = "You are a Cognitive Librarian. Analyze the provided block content and extract semantic metadata. Reply STRICTLY and ONLY with valid XML containing: <key_words>comma-separated keywords</key_words> and <summary>brief descriptive summary</summary>."
        },
        {
            role = "user",
            content = msg_content
        }
    }
end

M.patch_block_abstract = function(buf, block_id, abstract_xml)
    if not vim.api.nvim_buf_is_valid(buf) then return false end
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local start_idx = nil
    local end_idx = nil
    
    for i, line in ipairs(lines) do
        if line:match('<block[^>]*id="' .. vim.pesc(block_id) .. '"') then
            start_idx = i - 1
        elseif start_idx and line:match('</block>') then
            end_idx = i - 1
            break
        end
    end
    
    if not start_idx or not end_idx then return false end
    
    local block_def = lines[start_idx + 1]
    local block_end = lines[end_idx + 1]
    
    local inner_lines = {}
    for i = start_idx + 2, end_idx do table.insert(inner_lines, lines[i]) end
    local inner_content = table.concat(inner_lines, "\n")
    
    if inner_content:match("<content>") then return true end
    
    local new_lines = { block_def }
    local abs_lines = vim.split("<abstract>\n" .. vim.trim(abstract_xml) .. "\n</abstract>", "\n", {plain=true})
    for _, l in ipairs(abs_lines) do table.insert(new_lines, l) end
    
    table.insert(new_lines, "<content>")
    for _, l in ipairs(inner_lines) do table.insert(new_lines, l) end
    table.insert(new_lines, "</content>")
    table.insert(new_lines, block_end)
    
    vim.api.nvim_buf_set_lines(buf, start_idx, end_idx + 1, false, new_lines)
    
    local msgs = session.get_messages()
    for _, msg in ipairs(msgs) do
        if msg.metadata and msg.metadata.id == block_id then
            local kw = abstract_xml:match("<key_words>(.-)</key_words>")
            local summ = abstract_xml:match("<summary>(.-)</summary>")
            msg.metadata.abstract = {
                key_words = kw and vim.trim(kw) or "",
                summary = summ and vim.trim(summ) or ""
            }
            break
        end
    end
    require('multi_context.core.state_manager').set('session_messages', msgs)
    EventBus.emit("UI_ARCHIVIST_DONE", { buf = buf })
    return true
end

M.dispatch_jit_task = function(buf, block_id, msg_content)
    local config = require('multi_context.config')
    local wd_cfg = config.options.watchdog or {}
    
    if wd_cfg.strategy ~= "dynamic" or not wd_cfg.background_api or wd_cfg.background_api == "" then return end
    
    local api_cfg = config.load_api_config()
    if not api_cfg or not api_cfg.apis then return end
    
    local target_api = nil
    for _, a in ipairs(api_cfg.apis) do
        if a.name == wd_cfg.background_api then target_api = a; break end
    end
    if not target_api then return end
    
    local payload = M.build_jit_payload(msg_content)
    local api_client = require('multi_context.llm.api_client')
    local accumulated = ""
    
    api_client.execute(payload, 
        function() end, 
        function(chunk) if chunk then accumulated = accumulated .. chunk end end,
        function() M.patch_block_abstract(buf, block_id, accumulated) end,
        function(err) vim.notify("[Watchdog] JIT Erro: " .. tostring(err), vim.log.levels.WARN) end,
        target_api
    )
end

return M
EOF

# Injetar o Hook oficial no react_orchestrator.lua antes dos encerramentos de turno
sed -i 's/M.TerminateTurn()/-- FASE 44: Disparo JIT Micro-Archiving\n                pcall(function()\n                    local session = require("multi_context.core.session")\n                    local msgs = session.get_messages()\n                    local last_msg = msgs[#msgs]\n                    if last_msg and last_msg.metadata and last_msg.metadata.id then\n                        require("multi_context.core.dynamic_watchdog").dispatch_jit_task(buf, last_msg.metadata.id, last_msg.content)\n                    end\n                end)\n                M.TerminateTurn()/g' lua/multi_context/core/react_orchestrator.lua

echo "✅ Dispatcher do Watchdog JIT e Hook do Ciclo de Vida implementados com sucesso!"
echo "👉 Rode os testes (a expectativa é superar a barreira dos 250 testes no verde!)."
echo "PlenaryBustedFile lua/multi_context/tests/dynamic_watchdog_dispatch_spec.lua"
