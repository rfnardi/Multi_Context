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
    for _, worker in ipairs(M.state.workers) do
        if not worker.busy and #M.state.queue > 0 then
            local task = table.remove(M.state.queue, 1)
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
                        final_report_text = final_report_text .. "\n" .. current_chunk
                        
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
                        local clean_res = final_report_text:gsub("s+", "")
                        
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
                            table.insert(M.state.reports, { agent = task.agent, result = final_report_text })
                        end
                        M.dispatch_next() -- Chama o próximo da fila

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
                        M.dispatch_next()

                    end,
                    worker.api
                )
            end
            
            execute_turn()
        end
    end
end

return M
