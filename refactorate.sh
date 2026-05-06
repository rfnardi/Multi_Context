#!/bin/bash
# Refatoração Final (Fase 45) - O Despertar da Colheitadeira (Harvester Auto-Trigger)

cat << 'EOF' > wrap_up_phase45.lua
-- 1. Injetar o Gatilho no utilitario que salva o Workspace
local utils_lines = vim.fn.readfile("lua/multi_context/utils/utils.lua")
local utils_content = table.concat(utils_lines, "\n")

if not utils_content:match("WORKSPACE_SAVED") then
    -- Encontra o final da função export_to_workspace e injeta o EventBus
    local search_pattern = "ExecuteTools%(nil, vim%.api%.nvim_get_current_buf%(%)%)<CR>\", km%)%s*return filename"
    local replace_pattern = "ExecuteTools(nil, vim.api.nvim_get_current_buf())<CR>\", km)\n\n    require('multi_context.core.event_bus').emit(\"WORKSPACE_SAVED\", { file = filename })\n    return filename"
    utils_content = utils_content:gsub(search_pattern, replace_pattern)
    vim.fn.writefile(vim.split(utils_content, "\n"), "lua/multi_context/utils/utils.lua")
end

-- 2. Acoplar a execucao do Harvester no Watchdog Dinâmico
local wd_lines = vim.fn.readfile("lua/multi_context/core/dynamic_watchdog.lua")
local new_wd_lines = {}
local injected = false

for _, line in ipairs(wd_lines) do
    if line:match("^return M") and not injected then
        injected = true
        table.insert(new_wd_lines, "M.run_harvester = function()")
        table.insert(new_wd_lines, "    local config = require('multi_context.config')")
        table.insert(new_wd_lines, "    if not config.options.auto_inject_context_md then return end")
        table.insert(new_wd_lines, "    local wd_cfg = config.options.watchdog or {}")
        table.insert(new_wd_lines, "    local api_cfg = config.load_api_config()")
        table.insert(new_wd_lines, "    if not api_cfg or not api_cfg.apis then return end")
        table.insert(new_wd_lines, "    local target_api = nil")
        table.insert(new_wd_lines, "    for _, a in ipairs(api_cfg.apis) do")
        table.insert(new_wd_lines, "        if a.name == wd_cfg.background_api then target_api = a; break end")
        table.insert(new_wd_lines, "    end")
        table.insert(new_wd_lines, "    if not target_api then")
        table.insert(new_wd_lines, "        for _, a in ipairs(api_cfg.apis) do")
        table.insert(new_wd_lines, "            if a.allow_background then target_api = a; break end")
        table.insert(new_wd_lines, "        end")
        table.insert(new_wd_lines, "    end")
        table.insert(new_wd_lines, "    if not target_api then target_api = api_cfg.apis[1] end")
        table.insert(new_wd_lines, "    if not target_api then return end")
        table.insert(new_wd_lines, "    local payload = M.build_harvester_payload()")
        table.insert(new_wd_lines, "    local api_client = require('multi_context.llm.api_client')")
        table.insert(new_wd_lines, "    local accumulated = \"\"")
        table.insert(new_wd_lines, "    vim.notify(\"[Harvester] 🌾 Analisando a sessão em background para colher aprendizados...\", vim.log.levels.INFO)")
        table.insert(new_wd_lines, "    api_client.execute(payload, function() end,")
        table.insert(new_wd_lines, "        function(chunk) if chunk then accumulated = accumulated .. chunk end end,")
        table.insert(new_wd_lines, "        function()")
        table.insert(new_wd_lines, "            local tools = require('multi_context.ecosystem.native_tools')")
        table.insert(new_wd_lines, "            local clean = accumulated:gsub(\"^%s*```[%w_]*\\n\", \"\"):gsub(\"\\n%s*```%s*$\", \"\")")
        table.insert(new_wd_lines, "            if clean and clean ~= \"\" then")
        table.insert(new_wd_lines, "                local header = \"\\n\\n### 🌾 Harvester Insight (\" .. os.date(\"%Y-%m-%d %H:%M\") .. \")\\n\"")
        table.insert(new_wd_lines, "                local res = tools.update_context_md(header .. clean)")
        table.insert(new_wd_lines, "                if res:match(\"SUCESSO\") then")
        table.insert(new_wd_lines, "                    vim.notify(\"[Harvester] ✅ CONTEXT.md atualizado organicamente!\", vim.log.levels.INFO)")
        table.insert(new_wd_lines, "                end")
        table.insert(new_wd_lines, "            end")
        table.insert(new_wd_lines, "        end,")
        table.insert(new_wd_lines, "        function(err) vim.notify(\"[Harvester] Erro: \" .. tostring(err), vim.log.levels.WARN) end,")
        table.insert(new_wd_lines, "    target_api)")
        table.insert(new_wd_lines, "end")
        table.insert(new_wd_lines, "")
        table.insert(new_wd_lines, "EventBus.on(\"WORKSPACE_SAVED\", function()")
        table.insert(new_wd_lines, "    M.run_harvester()")
        table.insert(new_wd_lines, "end)")
        table.insert(new_wd_lines, "")
    end
    table.insert(new_wd_lines, line)
end
vim.fn.writefile(new_wd_lines, "lua/multi_context/core/dynamic_watchdog.lua")
EOF
nvim -l wrap_up_phase45.lua
rm wrap_up_phase45.lua

echo "✅ FASE 45 CONCLUÍDA COM SUCESSO ABSOLUTO!"
echo "🎉 O Ecossistema de Contexto Vivo está operacional."
