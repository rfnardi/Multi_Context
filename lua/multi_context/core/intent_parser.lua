local M = {}

M.parse = function(raw_text)
    local intent = {
        clean_text = raw_text or "",
        agent = nil,
        flags = { is_queue = false, is_moa = false }
    }
    
    if intent.clean_text == "" then return intent end

    -- Extração de flags usando regex robustos (lidando com espaços)
    if intent.clean_text:match("%-%-queue") then 
        intent.flags.is_queue = true 
    end
    
    if intent.clean_text:match("%-%-moa") then 
        intent.flags.is_moa = true 
    end
    
    -- Limpa as flags do texto para não poluir o prompt enviado à IA
    intent.clean_text = intent.clean_text:gsub("%s*%-%-queue", ""):gsub("%s*%-%-moa", "")
    intent.clean_text = vim.trim(intent.clean_text)

    -- Extração do Agente
    if intent.flags.is_moa then
        -- Se for MOA, o tech_lead assume forçadamente, e mantemos o texto inteiro
        -- para que ele saiba quais sub-agentes o usuário mencionou (ex: @coder, @qa)
        intent.agent = "tech_lead"
    else
        -- Procura a primeira menção de @agente no início do texto
        local possible_agent = intent.clean_text:match("^@([%w_]+)")
        if possible_agent then
            intent.agent = possible_agent
            -- Remove apenas o @agente inicial para limpar a intent do LLM
            intent.clean_text = intent.clean_text:gsub("^@" .. possible_agent .. "%s*", "")
            intent.clean_text = vim.trim(intent.clean_text)
        else
            -- Procura @agente em qualquer lugar caso não esteja no início
            possible_agent = intent.clean_text:match("@([%w_]+)")
            if possible_agent then
                intent.agent = possible_agent
                intent.clean_text = intent.clean_text:gsub("@" .. possible_agent .. "%s*", "")
                intent.clean_text = vim.trim(intent.clean_text)
            end
        end
    end

    return intent
end


M.parse_lines = function(lines, agents_table)
    agents_table = agents_table or {}
    local raw_full_text = table.concat(lines, "\n")
    
    local intent = {
        raw_current_task = "",
        queued_text = nil,
        flags = { is_queue = false, is_moa = false }
    }
    
    if raw_full_text:match("%-%-queue") then intent.flags.is_queue = true end
    if raw_full_text:match("%-%-moa") then intent.flags.is_moa = true end
    
    local current_task_lines = {}
    local queued_tasks_lines = {}
    local found_agent_count = 0
    
    local cleaned_lines = {}
    for _, line in ipairs(lines) do
        table.insert(cleaned_lines, (line:gsub("%s*%-%-queue", ""):gsub("%s*%-%-moa", "")))
    end

    for _, line in ipairs(cleaned_lines) do
        if not line:match("^> %[Checkpoint%]") then
            local possible_agent = line:match("@([%w_]+)")
            if possible_agent and agents_table[possible_agent] then 
                found_agent_count = found_agent_count + 1 
            end
            
            if intent.flags.is_moa then
                table.insert(current_task_lines, line)
            else
                if found_agent_count <= 1 then 
                    table.insert(current_task_lines, line) 
                else 
                    table.insert(queued_tasks_lines, line) 
                end
            end
        end
    end
    
    intent.raw_current_task = table.concat(current_task_lines, "\n"):gsub("^%s*", ""):gsub("%s*$", "")
    if #queued_tasks_lines > 0 then
        intent.queued_text = table.concat(queued_tasks_lines, "\n")
    end
    
    return intent
end

return M
