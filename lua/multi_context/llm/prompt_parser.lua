local M = {}
local registry = require('multi_context.skills.registry')
local i18n = require('multi_context.i18n')

M.parse_user_input = function(raw_text, agents_table)
    local parsed = {
        text_to_send = raw_text,
        agent_name = nil,
        is_autonomous = false
    }
    
    local StateManager = require('multi_context.core.state_manager')
    if StateManager.get('react').is_moa_mode then
        parsed.agent_name = "tech_lead"
        parsed.text_to_send = "O usuário solicitou uma orquestração semântica (Modo MOA). Analise a demanda abaixo e use a ferramenta spawn_swarm para instanciar e coordenar os agentes mencionados para que resolvam o problema:\n\n" .. parsed.text_to_send
        parsed.is_autonomous = true
        return parsed
    end

    local ok_sq, squads_manager = pcall(require, 'multi_context.ecosystem.squads')
    local squads = ok_sq and squads_manager.load_squads() or {}
    
    local agent_match = parsed.text_to_send:match("@([%w_]+)")
    if agent_match then
        if agent_match == "reset" then
            parsed.agent_name = "reset"
            parsed.text_to_send = parsed.text_to_send:gsub("@reset%s*", "")
        elseif squads[agent_match] then
            local squad_def = squads[agent_match]
            parsed.text_to_send = parsed.text_to_send:gsub("@" .. agent_match .. "%s*", "")
            parsed.text_to_send = parsed.text_to_send:gsub("^%s*", ""):gsub("%s*$", "")
            
            local main_task = vim.deepcopy(squad_def.tasks[1] or {})
            if parsed.text_to_send ~= "" then
                main_task.instruction = (main_task.instruction or "") .. "\n\nUser Request:\n" .. parsed.text_to_send
            end
            
            local payload = { tasks = { main_task } }
            if squad_def.tasks then
                for i = 2, #squad_def.tasks do table.insert(payload.tasks, squad_def.tasks[i]) end
            end
            
            local ok_json, json_payload = pcall(vim.fn.json_encode, payload)
            parsed.agent_name = "tech_lead"
            parsed.text_to_send = string.format("<tool_call name=\"spawn_swarm\">\n```json\n%s\n```\n</tool_call>", json_payload)
            parsed.is_autonomous = true
        elseif agents_table[agent_match] then
            parsed.agent_name = agent_match
            parsed.text_to_send = parsed.text_to_send:gsub("@" .. agent_match .. "%s*", "")
        end
    end
    
    if parsed.text_to_send:match("%-%-auto") then
        parsed.is_autonomous = true
        parsed.text_to_send = parsed.text_to_send:gsub("%-%-auto%s*", "")
    end
    
    parsed.text_to_send = parsed.text_to_send:gsub("^%s*", ""):gsub("%s*$", "")
    return parsed
end

M.build_system_prompt = function(base_prompt, memory_context, active_agent_name, agents_table, current_tokens)
    if active_agent_name == "archivist" then
        if active_agent_name == "tech_lead" then
        local available = {}
        for k, _ in pairs(agents_table) do table.insert(available, k) end
        system_prompt = system_prompt .. "\n\n=== AVAILABLE AGENTS FOR DELEGATION ===\nYou MUST ONLY assign tasks to these exact agents: " .. table.concat(available, ", ") .. "\nDo NOT invent new agent names (e.g., no 'frontend-coder', 'qa_contrato'). Use STRICTLY and ONLY the names listed above."
    end
    
    local cfg = require('multi_context.config').options
        local wd = cfg.watchdog or { strategy = "semantic", percent = 0.3, fixed_target = 1500 }
        local prompt = "You are the system's @archivist. Your mission is to structure the verbose chat memory below using EXACTLY 4 tags: <genesis>, <plan>, <journey>, and <now>.\n"
        if wd.strategy == "percent" then
            local target = math.floor((current_tokens or 5000) * (wd.percent or 0.3))
            prompt = prompt .. "MANDATORY: Compression is based on a percentage ceiling. Your output must not exceed " .. target .. " tokens.\n"
        elseif wd.strategy == "fixed" then
            prompt = prompt .. "MANDATORY: Aggressive compression. Your output must not exceed " .. (wd.fixed_target or 1500) .. " tokens.\n"
        else
            prompt = prompt .. "SEMANTIC COMPRESSION: Adapt the size to the complexity of the content, focusing on information integrity.\n"
        end
        prompt = prompt .. "Reply STRICTLY with the generated XML."
        return prompt
    end
    local system_prompt = base_prompt

    if memory_context then
        system_prompt = system_prompt .. "\n\n=== CURRENT PROJECT STATE (MEMORY) ===\n" .. memory_context .. "\n- Update CONTEXT.md when finishing tasks."
    end

    if active_agent_name and active_agent_name ~= "reset" and agents_table and agents_table[active_agent_name] then
        local agent_data = agents_table[active_agent_name]
        local active_agent_prompt = "\n\n=== AGENT INSTRUCTIONS: " .. string.upper(active_agent_name) .. " ===\n" .. agent_data.system_prompt
        
        if agent_data.skills and #agent_data.skills > 0 then
            active_agent_prompt = active_agent_prompt .. "\n\n" .. registry.build_manual_for_skills(agent_data.skills)
        end
        
        system_prompt = system_prompt .. active_agent_prompt
    end

    local ok, skills_manager = pcall(require, 'multi_context.ecosystem.skills_manager')
    if ok and skills_manager and skills_manager.get_skills then
        local user_skills = skills_manager.get_skills()
        local has_user_skills = false
        local user_skills_xml = "\n\n=== CUSTOM TOOLS ===\nYou have access to user-customized tools. You can invoke them by returning an XML block in the format <tool_call name=\"name\">\n<tools>\n"
        
        for _, skill in pairs(user_skills) do
            has_user_skills = true
            local params_xml = ""
            if skill.parameters then
                for _, p in ipairs(skill.parameters) do
                    params_xml = params_xml .. string.format('\n      <parameter name="%s" type="%s" required="%s">%s</parameter>',
                        p.name, p.type or "string", tostring(p.required ~= false), p.desc or "")
                end
            end
            user_skills_xml = user_skills_xml .. string.format([[
  <tool_definition>
    <name>%s</name>
    <description>%s</description>
    <parameters>%s
    </parameters>
  </tool_definition>]], skill.name, skill.description, params_xml)
        end
        user_skills_xml = user_skills_xml .. "\n</tools>\n"

        if has_user_skills then
            system_prompt = system_prompt .. user_skills_xml
        end
    end

    if active_agent_name == "tech_lead" then
        local available = {}
        for k, _ in pairs(agents_table) do table.insert(available, k) end
        system_prompt = system_prompt .. "\n\n=== AVAILABLE AGENTS FOR DELEGATION ===\nYou MUST ONLY assign tasks to these exact agents: " .. table.concat(available, ", ") .. "\nDo NOT invent new agent names (e.g., no 'frontend-coder', 'qa_contrato'). Use STRICTLY and ONLY the names listed above."
    end
    
    local cfg = require('multi_context.config').options
    if cfg.language == "pt-BR" then
        system_prompt = system_prompt .. i18n.t("sys_lang_directive")
    end

    return system_prompt
end

return M
