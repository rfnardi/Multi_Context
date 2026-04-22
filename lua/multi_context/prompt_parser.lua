local M = {}
local registry = require('multi_context.skills.registry')

M.parse_user_input = function(raw_text, agents_table)
    local parsed = {
        text_to_send = raw_text,
        agent_name = nil,
        is_autonomous = false
    }

    local agent_match = parsed.text_to_send:match("@([%w_]+)")
    if agent_match then
        if agent_match == "reset" then
            parsed.agent_name = "reset"
            parsed.text_to_send = parsed.text_to_send:gsub("@reset%s*", "")
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

M.build_system_prompt = function(base_prompt, memory_context, active_agent_name, agents_table)
    local system_prompt = base_prompt

    if memory_context then
        system_prompt = system_prompt .. "\n\n=== ESTADO ATUAL DO PROJETO (MEMÓRIA) ===\n" .. memory_context .. "\n- Atualize o CONTEXT.md sempre que finalizar uma tarefa para não perder a memória."
    end

    if active_agent_name and active_agent_name ~= "reset" and agents_table and agents_table[active_agent_name] then
        local agent_data = agents_table[active_agent_name]
        local active_agent_prompt = "\n\n=== INSTRUÇÕES DO AGENTE: " .. string.upper(active_agent_name) .. " ===\n" .. agent_data.system_prompt
        
        -- Montador Dinâmico de Skills
        if agent_data.skills and #agent_data.skills > 0 then
            active_agent_prompt = active_agent_prompt .. "\n\n" .. registry.build_manual_for_skills(agent_data.skills)
        end
        
        system_prompt = system_prompt .. active_agent_prompt
    end

    -- INJEÇÃO FASE 19: SKILLS CUSTOMIZADAS DO USUÁRIO
    local ok, skills_manager = pcall(require, 'multi_context.skills_manager')
    if ok and skills_manager and skills_manager.get_skills then
        local user_skills = skills_manager.get_skills()
        local has_user_skills = false
        local user_skills_xml = "\n\n=== FERRAMENTAS CUSTOMIZADAS ===\nVocê tem acesso a ferramentas customizadas pelo usuário. Você pode invocá-las retornando um bloco XML no formato <tool_call name=\"nome\">\n<tools>\n"
        
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

    return system_prompt
end

return M
