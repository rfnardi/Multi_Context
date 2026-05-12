cat << 'EOF' > fix_swarm_json.lua
-- 1. Substituição Absoluta do M.init_swarm
local f1 = "lua/multi_context/core/swarm_manager.lua"
local c1 = table.concat(vim.fn.readfile(f1), "\n")
local start_pos = c1:find("M%.init_swarm = function%(json_payload%)")
local end_pos = c1:find("M%.dispatch_next = function%(%)")

if start_pos and end_pos then
    local new_func = [[M.init_swarm = function(json_payload)
    M.reset()
    if not json_payload or json_payload == "" then return false end
    local clean_payload = vim.trim(json_payload)
    local ok, decoded = pcall(vim.fn.json_decode, clean_payload)
    if not ok then
        -- A Mágica de Extração: Ignora tudo e pega do primeiro { até o último }
        local json_match = clean_payload:match("%b{}")
        if json_match then ok, decoded = pcall(vim.fn.json_decode, json_match) end
    end
    if not ok or type(decoded) ~= "table" or type(decoded.tasks) ~= "table" then 
        return false, "ERRO JSON: Formato inválido. Use apenas chaves { } e o array 'tasks'." 
    end
    local ok_sq, squads_manager = pcall(require, "multi_context.ecosystem.squads")
    local squads = ok_sq and squads_manager.load_squads() or {}
    local new_tasks = {}
    for _, task in ipairs(decoded.tasks) do
        local target = task.agent or (task.chain and task.chain[1])
        if target and squads[target] then
            local squad = squads[target]
            local main_task = vim.deepcopy(squad.tasks[1] or {})
            local col_purp = squad.collective_purpose or squad.description or ""
            local purpose_block = col_purp ~= "" and ("\n=== SQUAD MISSION: " .. col_purp .. " ===\n") or ""
            main_task.instruction = purpose_block .. (main_task.instruction or "") .. "\n\nDelegated Task: " .. (task.instruction or "")
            if not main_task.agent and main_task.chain and #main_task.chain > 0 then main_task.agent = main_task.chain[1] end
            table.insert(new_tasks, main_task)
            if squad.tasks then for i = 2, #squad.tasks do table.insert(new_tasks, squad.tasks[i]) end end
        else
            if not task.agent and type(task.chain) == "table" and #task.chain > 0 then task.agent = task.chain[1] end
            table.insert(new_tasks, task)
        end
    end
    M.state.queue = new_tasks
    local apis = require("multi_context.config").get_spawn_apis()
    for _, api_cfg in ipairs(apis) do table.insert(M.state.workers, { api = api_cfg, busy = false, current_task = nil }) end
    return true
end

]]
    vim.fn.writefile(vim.split(c1:sub(1, start_pos - 1) .. new_func .. c1:sub(end_pos), "\n"), f1)
    print("✅ Swarm Manager reescrito com Extrator JSON blindado.")
end

-- 2. Substituição Absoluta no Tool Runner para passar o erro adiante
local f2 = "lua/multi_context/ecosystem/tool_runner.lua"
local c2 = table.concat(vim.fn.readfile(f2), "\n")
local s2 = c2:find("elseif name == \"spawn_swarm\" then")
local e2 = c2:find("elseif name == \"switch_agent\" then")

if s2 and e2 then
    local new_chunk2 = [[elseif name == "spawn_swarm" then
        local swarm = require('multi_context.core.swarm_manager')
        local swarm_ok, swarm_err = swarm.init_swarm(clean_inner)
        if swarm_ok then
            swarm.on_swarm_complete = require('multi_context').OnSwarmComplete
            vim.defer_fn(function() swarm.dispatch_next() end, 100)
            result = i18n.t("swarm_started")
            should_continue_loop = false
        else
            result = swarm_err or i18n.t("swarm_err_json")
        end
    ]]
    vim.fn.writefile(vim.split(c2:sub(1, s2 - 1) .. new_chunk2 .. c2:sub(e2), "\n"), f2)
    print("✅ Tool Runner reescrito para reportar Erro JSON limpo.")
end
EOF

# Usa a flag --clean para rodar perfeitamente sem puxar o init.vim do usuário
nvim --clean --headless -c "luafile fix_swarm_json.lua" -c "q"
rm fix_swarm_json.lua
