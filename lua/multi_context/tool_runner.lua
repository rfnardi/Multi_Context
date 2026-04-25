-- lua/multi_context/tool_runner.lua
local M = {}
local tools = require('multi_context.tools')
local react_loop = require('multi_context.react_loop')

local valid_tools = {
    list_files = true, read_file = true, search_code = true,
    edit_file = true, run_shell = true, replace_lines = true, apply_diff = true,
    rewrite_chat_buffer = true, get_diagnostics = true, spawn_swarm = true, switch_agent = true
}

local dangerous_commands = {"rm%s+-rf", "mkfs", "sudo ", ">%s*/dev", "chmod ", "chown "}
local function is_dangerous(cmd)
    if not cmd then return false end
    for _, pat in ipairs(dangerous_commands) do if cmd:match(pat) then return true end end
    return false
end

M.execute = function(tool_data, is_autonomous, approve_all_ref, buf)
    local name = tool_data.name
    local clean_inner = tool_data.inner

    local skills_manager = require('multi_context.skills_manager')
    local custom_skills = skills_manager.get_skills()
    local is_custom_skill = custom_skills[name] ~= nil

    if not valid_tools[name] and not is_custom_skill then
        local err_msg = string.format("Ferramenta '%s' não existe.", tostring(name))
        local out = string.format('<tool_call name="%s">\n%s\n</tool_call>\n\n>[Sistema]: ERRO - %s', tostring(name), clean_inner, err_msg)
        return out, false, false, nil, nil
    end

    -- ==========================================
    -- GATEKEEPER DE SKILLS (Autorização)
    -- ==========================================
    local agents = require('multi_context.agents').load_agents()
    local active_agent = react_loop.state.active_agent
    local is_authorized = false

    if active_agent and agents[active_agent] and agents[active_agent].skills then
        for _, skill in ipairs(agents[active_agent].skills) do
            if skill == name then is_authorized = true; break end
        end
    else
        is_authorized = true -- Sem agente ativo (Modo Root/Manual), permite tudo
    end

    if not is_authorized then
        local err_msg = string.format("Operação negada. O agente @%s não possui a Skill '%s'.", tostring(active_agent), tostring(name))
        local out = string.format('<tool_call name="%s">\n%s\n</tool_call>\n\n>[Sistema]: ⛔ ERRO - %s', tostring(name), clean_inner, err_msg)
        return out, false, false, nil, nil
    end
    -- ==========================================

    local choice = 1
    if not approve_all_ref.value then
        if is_autonomous then
            if name == "run_shell" and is_dangerous(clean_inner) then
                vim.notify("🛡️ Comando PERIGOSO detectado.", vim.log.levels.ERROR)
                choice = vim.fn.confirm("Permitir execução PERIGOSA: " .. clean_inner, "&Sim\n&Nao\n&Todos\n&Cancelar", 2)
            elseif name == "rewrite_chat_buffer" then
                choice = vim.fn.confirm("Agente solicitou DESTRUIR E COMPRIMIR o chat. Permitir?", "&Sim\n&Nao\n&Todos\n&Cancelar", 1)
            else choice = 3; approve_all_ref.value = true end
        else
            choice = vim.fn.confirm(string.format("Agente requisitou [%s]. Permitir?", tostring(name)), "&Sim\n&Nao\n&Todos\n&Cancelar", 1)
        end
    end

    if choice == 3 then approve_all_ref.value = true; choice = 1 end
    if choice == 4 or choice == 0 then
        local out = string.format('<tool_call name="%s">\n%s\n</tool_call>', tostring(tool_data.raw_tag), clean_inner)
        return out, true, false, nil, nil
    end

    local result = ""
    local should_continue_loop = false
    local pending_rewrite_content = nil
    local backup_made = nil

    if choice == 2 then
        result = "Acesso NEGADO pelo usuario."
        local out = string.format('<tool_call name="%s">\n%s\n</tool_call>\n\n>[Sistema]: ERRO - %s', tostring(name), clean_inner, result)
        return out, false, false, nil, nil
    end

    if is_custom_skill then
        local args = {}
        if clean_inner then
            for p_name, p_val in clean_inner:gmatch("<([%w_]+)[^>]*>(.-)</%1>") do
                args[p_name] = vim.trim(p_val)
            end
        end
        local ok, skill_res = pcall(custom_skills[name].execute, args)
        if ok then
            result = tostring(skill_res)
            should_continue_loop = true
        else
            result = "ERRO NA EXECUCAO DA SKILL: " .. tostring(skill_res)
        end
    elseif name == "rewrite_chat_buffer" then
        backup_made = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        local backup_file = vim.fn.stdpath("data") .. "/mctx_backup_" .. os.date("%Y%m%d_%H%M%S") .. ".mctx"
        vim.fn.writefile(backup_made, backup_file)
        pending_rewrite_content = clean_inner
        result = "Buffer reescrito."
    elseif name == "list_files" then 
        should_continue_loop = true; result = tools.list_files()
    elseif name == "read_file" then 
        should_continue_loop = true; result = tools.read_file(tool_data.path)
    elseif name == "search_code" then 
        should_continue_loop = true; result = tools.search_code(tool_data.query)
    elseif name == "edit_file" then 
        result = tools.edit_file(tool_data.path, clean_inner)
        if is_autonomous and result:match("SUCESSO") then result = result .. "\n\n[Auto-LSP]:\n" .. tools.get_diagnostics(tool_data.path) end
    elseif name == "run_shell" then 
        result = tools.run_shell(clean_inner)
    elseif name == "replace_lines" then 
        result = tools.replace_lines(tool_data.path, tool_data.start_line, tool_data.end_line, clean_inner)
        if is_autonomous and result:match("SUCESSO") then result = result .. "\n\n[Auto-LSP]:\n" .. tools.get_diagnostics(tool_data.path) end
    elseif name == "apply_diff" then
        result = tools.apply_diff(tool_data.path, clean_inner)
        if is_autonomous and result:match("SUCESSO") then result = result .. "\n\n[Auto-LSP]:\n" .. tools.get_diagnostics(tool_data.path) end
    elseif name == "get_diagnostics" then 
        should_continue_loop = true; result = tools.get_diagnostics(tool_data.path)
    elseif name == "spawn_swarm" then
        local swarm = require('multi_context.swarm_manager')
        if swarm.init_swarm(clean_inner) then
            swarm.on_swarm_complete = require('multi_context').OnSwarmComplete
            vim.defer_fn(function() swarm.dispatch_next() end, 100)
            result = "SWARM INICIADO. O trabalho foi delegado aos sub-agentes e está rodando em background."
            should_continue_loop = false
        else
            result = "ERRO: O payload JSON fornecido para spawn_swarm é inválido."
        end
    elseif name == "switch_agent" then
        local target = clean_inner:match("<target_agent>(.-)</target_agent>")
        if not target then target = clean_inner:match("([%w_]+)") end
        if target then target = vim.trim(target) else target = "" end
        result = "SWITCH_AGENT_REQUEST:" .. target
        should_continue_loop = true
    end

    local output = ""
    if not pending_rewrite_content then
        output = string.format('<tool_call name="%s" path="%s">\n%s\n</tool_call>\n\n>[Sistema]: Resultado:\n```text\n%s\n```', tostring(name), tostring(tool_data.path or ""), clean_inner, result)
    end

    return output, false, should_continue_loop, pending_rewrite_content, backup_made
end

return M






