local config = require('multi_context.config')
local api_client = require('multi_context.api_client')
local popup = require('multi_context.ui.popup')
local tools = require('multi_context.tools')
local agents = require('multi_context.agents')
local tool_parser = require('multi_context.tool_parser')
local tool_runner = require('multi_context.tool_runner')

local M = {}
M.state = { queue = {}, workers = {}, reports = {} }

M.reset = function() M.state.queue = {}; M.state.workers = {}; M.state.reports = {} end

M.init_swarm = function(json_payload)
    M.reset()
    if not json_payload or json_payload == "" then return false end
    local ok, decoded = pcall(vim.fn.json_decode, vim.trim(json_payload))
    if not ok or type(decoded) ~= "table" or type(decoded.tasks) ~= "table" then return false end
    
    -- Pré-processamento de Tarefas Avançadas (Fase 21)
    for _, task in ipairs(decoded.tasks) do
        if not task.agent and type(task.chain) == "table" and #task.chain > 0 then
            task.agent = task.chain[1]
        end
    end
    
    M.state.queue = decoded.tasks
    local apis = config.get_spawn_apis()
    for _, api_cfg in ipairs(apis) do
        table.insert(M.state.workers, { api = api_cfg, busy = false, current_task = nil })
    end
    return true
end

M.dispatch_next = function()
    -- FINALIZADOR (REDUCE)
    if #M.state.queue == 0 then
        local any_busy = false
        for _, w in ipairs(M.state.workers) do if w.busy then any_busy = true; break end end
        if not any_busy and M.on_swarm_complete then
            local summary = "=== RELATÓRIO DO ENXAME (SWARM) ===\n"
            for _, rep in ipairs(M.state.reports) do
                summary = summary .. "\nAgente: @" .. rep.agent .. "\nResultado Final:\n" .. rep.result .. "\n------------------------"
            end
            M.on_swarm_complete(summary)
        end
        return
    end

    -- DESPACHANTE (MAP)
        local level_val = { low = 1, medium = 2, high = 3 }
    local loaded_agents = require('multi_context.agents').load_agents()

    -- Processa a fila inteira procurando match para cada tarefa
    local i = 1
        local max_attempts = #M.state.queue
    local attempts = 0
    while i <= #M.state.queue and attempts < max_attempts do
        attempts = attempts + 1
        local task = M.state.queue[i]
        local agent_def = loaded_agents[task.agent]
        local req_level = (agent_def and agent_def.abstraction_level) and level_val[agent_def.abstraction_level] or 3
        
        local selected_worker = nil
        local best_diff = 999
        
        for _, worker in ipairs(M.state.workers) do
            if not worker.busy then
                local api_level = worker.api.abstraction_level and level_val[worker.api.abstraction_level] or 2
                
                -- Se a API é forte o suficiente para a tarefa
                if api_level >= req_level then
                    local diff = api_level - req_level
                    -- Preferimos o Match perfeito (diff 0). Se nao houver, pegamos o proximo mais barato
                    if diff < best_diff then
                        best_diff = diff
                        selected_worker = worker
                    end
                end
            end
        end

        if selected_worker then
            table.remove(M.state.queue, i)
            local worker = selected_worker
            worker.busy = true
            worker.current_task = task

            worker.busy = true
            worker.current_task = task
            local buf_id = popup.create_swarm_buffer(task.agent, task.instruction, worker.api.name)
            
            local loaded_agents = agents.load_agents()
            local system_prompt = "Você é um sub-agente operando em modo SWARM. Sua tarefa estrita é: " .. (task.instruction or "")
            if loaded_agents[task.agent] then
                system_prompt = system_prompt .. "\n\n=== SUAS DIRETRIZES ===\n" .. loaded_agents[task.agent].system_prompt
            end
            
            local context_text = ""
            if type(task.context) == "table" then
                for _, path in ipairs(task.context) do
                    if path ~= "*" and path ~= "" then
                        context_text = context_text .. "\n== Arquivo: " .. path .. " ==\n" .. tools.read_file(path)
                    end
                end
            end
            system_prompt = system_prompt .. "\n\n=== CONTEXTO INICIAL FORNECIDO ===\n" .. context_text            
            system_prompt = system_prompt .. "\n\n=== REGRAS DE ENTREGA (MANDATÓRIO) ===\nQuando terminar a tarefa e não precisar usar mais nenhuma ferramenta, você DEVE entregar o seu relatório final dentro das tags <final_report>...</final_report>. O relatório DEVE incluir um resumo claro do que foi feito, os arquivos editados e listar de forma estruturada as operações Git executadas (se houver). Esta tag encerra a sua execução e sem ela o mestre não lerá sua resposta."

            
            local messages = {
                { role = "system", content = system_prompt },
                { role = "user", content = "Inicie a execução da sua tarefa. Se precisar de mais informações, use as ferramentas disponíveis. Quando finalizar todo o trabalho, dê um resumo." }
            }
            
            local visual_history = ""
            local final_report_text = ""

            -- O MOTOR REACT RECURSIVO DO SUB-AGENTE
            local function execute_turn()
                local current_chunk = ""
                api_client.execute(messages,
                    function() end,
                    function(chunk) 
                        current_chunk = current_chunk .. chunk 
                        if buf_id and vim.api.nvim_buf_is_valid(buf_id) then
                            local display_text = visual_history .. "\n\n## IA >>\n" .. current_chunk
                            local lines = vim.split(display_text, "\n", {plain=true})
                            vim.api.nvim_buf_set_lines(buf_id, 4, -1, false, lines)
                        end
                    end,
                    function(api_entry, metrics)
                        visual_history = visual_history .. "\n\n## IA >>\n" .. current_chunk
                        table.insert(messages, { role = "assistant", content = current_chunk })
                                                -- FASE 20: Extrai APENAS o bloco estruturado, evitando Token Leak
                        local extracted_report = current_chunk:match("<final_report>(.-)</final_report>")
                        if extracted_report then
                            final_report_text = vim.trim(extracted_report)
                        else
                            final_report_text = "" -- Forçará o retry logo abaixo
                        end

                        
                        local sanitized = tool_parser.sanitize_payload(current_chunk)
                        
                        -- SE A IA USOU FERRAMENTAS, EXECUTA E CHAMA O PRÓXIMO TURNO
                        if sanitized:match("<tool_call") then
                            local new_content = ""
                            local cursor = 1
                            local approve_ref = { value = true } -- Auto Approve SILENCIOSO
                            
                            while cursor <= #sanitized do
                                local parsed = tool_parser.parse_next_tool(sanitized, cursor)
                                if not parsed then break end
                                if parsed.is_invalid or not parsed.name or parsed.name == "" then
                                    cursor = parsed.close_end + 1
                                else
                                    local tag_out = tool_runner.execute(parsed, true, approve_ref, buf_id)
                                    new_content = new_content .. "\n" .. tag_out
                                    cursor = parsed.close_end + 1
                                end
                            end
                            
                            if new_content ~= "" then
                                local switch_target = new_content:match("SWITCH_AGENT_REQUEST:([%w_]+)")
                                if switch_target then
                                    local is_allowed = false
                                    if type(task.allow_switch) == "table" then
                                        for _, allowed in ipairs(task.allow_switch) do
                                            if allowed == switch_target then is_allowed = true; break end
                                        end
                                    end
                                    
                                    if is_allowed then
                                        task.agent = switch_target
                                        local loaded_agents = require('multi_context.agents').load_agents()
                                        local new_system = "Você é um sub-agente operando em modo SWARM. Sua tarefa estrita é: " .. (task.instruction or "")
                                        if loaded_agents[switch_target] then
                                            new_system = new_system .. "\n\n=== SUAS DIRETRIZES ===\n" .. loaded_agents[switch_target].system_prompt
                                        end
                                        new_system = new_system .. "\n\n=== CONTEXTO INICIAL FORNECIDO ===\n" .. context_text
                                        new_system = new_system .. "\n\n=== REGRAS DE ENTREGA (MANDATÓRIO) ===\nQuando terminar a tarefa e não precisar usar mais nenhuma ferramenta, você DEVE entregar o seu relatório final dentro das tags <final_report>...</final_report>. O relatório DEVE incluir um resumo claro do que foi feito, os arquivos editados e listar de forma estruturada as operações Git executadas (se houver). Esta tag encerra a sua execução e sem ela o mestre não lerá sua resposta."
                                        
                                        messages[1].content = new_system
                                        new_content = "SUCESSO: Controle transferido para @" .. switch_target .. ". O sistema foi reconfigurado com suas diretrizes."
                                        
                                        if buf_id and vim.api.nvim_buf_is_valid(buf_id) then
                                            local popup = require('multi_context.ui.popup')
                                            if popup.swarm_buffers then
                                                for _, sb in ipairs(popup.swarm_buffers) do
                                                    if sb.buf == buf_id then
                                                        sb.name = switch_target
                                                        break
                                                    end
                                                end
                                            end
                                            pcall(popup.update_title)
                                        end
                                    else
                                        new_content = "ERRO: O agente @" .. task.agent .. " não tem permissão para transferir o controle para @" .. switch_target .. " (Verifique allow_switch)."
                                    end
                                end

                                visual_history = visual_history .. "\n\n## Sistema >>\n" .. new_content
                                table.insert(messages, { role = "user", content = new_content })
                                -- Recursão! O agente chama a API novamente para ler o output da ferramenta
                                execute_turn() 
                                return
                            end
                        end
                        
                        -- SE CHEGOU AQUI, ELE NÃO USOU FERRAMENTAS. A TAREFA ACABOU!
                        if buf_id and vim.api.nvim_buf_is_valid(buf_id) then
                            local lines = vim.api.nvim_buf_get_lines(buf_id, 0, -1, false)
                            table.insert(lines, "")
                            table.insert(lines, "✅ TAREFA CONCLUÍDA")
                            vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
                        end
                        
                                                worker.busy = false
                        local clean_res = final_report_text:gsub("%s+", "")
                        
                        task.retries = task.retries or 0
                        if clean_res == "" and task.retries < 2 then
                            task.retries = task.retries + 1
                            if buf_id and vim.api.nvim_buf_is_valid(buf_id) then
                                local lines = vim.api.nvim_buf_get_lines(buf_id, 0, -1, false)
                                table.insert(lines, "⚠️ API retornou vazio. Devolvendo tarefa para a fila (Tentativa " .. task.retries .. "/2)...")
                                vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
                            end
                            table.insert(M.state.queue, task)
                        else
                            if clean_res == "" then final_report_text = "FALHA: A API falhou repetidas vezes em processar esta tarefa." end
                            local has_next = false
                            if type(task.chain) == 'table' then
                                local c_idx = 0
                                for idx, a in ipairs(task.chain) do if a == task.agent then c_idx = idx; break end end
                                if c_idx > 0 and c_idx < #task.chain then
                                    task.agent = task.chain[c_idx + 1]
                                    task.instruction = (task.instruction or '') .. '\n\n=== RELATÓRIO DO AGENTE ANTERIOR ===\n' .. final_report_text
                                    task.retries = 0
                                    table.insert(M.state.queue, task)
                                    has_next = true
                                end
                            end
                            if not has_next then
                            table.insert(M.state.reports, { agent = task.agent, result = final_report_text })
                            end
                        end
                        vim.schedule(M.dispatch_next) -- Chama o próximo da fila

                    end,
                    function(err)
                        if buf_id and vim.api.nvim_buf_is_valid(buf_id) then
                            local lines = vim.api.nvim_buf_get_lines(buf_id, 0, -1, false)
                            table.insert(lines, "")
                            table.insert(lines, "❌ ERRO NA API: " .. tostring(err))
                            vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
                        end
                                                worker.busy = false
                        task.retries = task.retries or 0
                        if task.retries < 2 then
                            task.retries = task.retries + 1
                            if buf_id and vim.api.nvim_buf_is_valid(buf_id) then
                                local lines = vim.api.nvim_buf_get_lines(buf_id, 0, -1, false)
                                table.insert(lines, "⚠️ Falha na API (".. worker.api.name .. "). Devolvendo para a fila (Tentativa " .. task.retries .. "/2)...")
                                vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
                            end
                            table.insert(M.state.queue, task)
                        else
                            table.insert(M.state.reports, { agent = task.agent, result = "ERRO FATAL APÓS TENTATIVAS: " .. tostring(err) })
                        end
                        vim.schedule(M.dispatch_next)

                    end,
                    worker.api
                )
            end
            
            execute_turn()
        else
            i = i + 1
        end
    end
end

return M






