local config = require('multi_context.config')
local api_client = require('multi_context.api_client')
local popup = require('multi_context.ui.popup')
local tools = require('multi_context.tools')
local agents = require('multi_context.agents')
local tool_parser = require('multi_context.tool_parser')
local tool_runner = require('multi_context.tool_runner')
local i18n = require('multi_context.i18n')

local M = {}
M.state = { queue = {}, workers = {}, reports = {} }

M.reset = function() M.state.queue = {}; M.state.workers = {}; M.state.reports = {} end

M.init_swarm = function(json_payload)
    M.reset()
    if not json_payload or json_payload == "" then return false end
    local ok, decoded = pcall(vim.fn.json_decode, vim.trim(json_payload))
    if not ok or type(decoded) ~= "table" or type(decoded.tasks) ~= "table" then return false end
    
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
    if #M.state.queue == 0 then
        local any_busy = false
        for _, w in ipairs(M.state.workers) do if w.busy then any_busy = true; break end end
        if not any_busy and M.on_swarm_complete then
            local summary = i18n.t("swarm_final_report") .. "\n"
            for _, rep in ipairs(M.state.reports) do
                summary = summary .. "\n" .. i18n.t("swarm_agent_res", rep.agent, rep.result)
            end
            M.on_swarm_complete(summary)
        end
        return
    end

    local level_val = { low = 1, medium = 2, high = 3 }
    local loaded_agents = require('multi_context.agents').load_agents()

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
                if api_level >= req_level then
                    local diff = api_level - req_level
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
            local buf_id = popup.create_swarm_buffer(task.agent, task.instruction, worker.api.name)
            
            local system_prompt = "You are a sub-agent operating in SWARM mode. Your strict task is: " .. (task.instruction or "")
            if loaded_agents[task.agent] then
                system_prompt = system_prompt .. "\n\n=== YOUR GUIDELINES ===\n" .. loaded_agents[task.agent].system_prompt
            end
            
            local context_text = ""
            if type(task.context) == "table" then
                for _, path in ipairs(task.context) do
                    if path ~= "*" and path ~= "" then
                        context_text = context_text .. "\n== File: " .. path .. " ==\n" .. tools.read_file(path)
                    end
                end
            end
            system_prompt = system_prompt .. "\n\n=== INITIAL CONTEXT PROVIDED ===\n" .. context_text            
            system_prompt = system_prompt .. "\n\n=== DELIVERY RULES (MANDATORY) ===\nWhen you finish the task and no longer need to use any tools, you MUST deliver your final report inside the <final_report>...</final_report> tags. The report MUST include a clear summary of what was done, the edited files, and list in a structured way the executed Git operations (if any). This tag ends your execution, and without it, the master will not read your response."

            local cfg = require('multi_context.config').options
            if cfg.language == "pt-BR" then
                system_prompt = system_prompt .. i18n.t("sys_lang_directive")
            end

            local messages = {
                { role = "system", content = system_prompt },
                { role = "user", content = "Start executing your task. If you need more information, use the available tools. When you finish all the work, provide a summary." }
            }
            
            local visual_history = ""
            local final_report_text = ""

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
                        
                        local extracted_report = current_chunk:match("<final_report>(.-)</final_report>")
                        if extracted_report then
                            final_report_text = vim.trim(extracted_report)
                        else
                            final_report_text = ""
                        end

                        local sanitized = tool_parser.sanitize_payload(current_chunk)
                        
                        if sanitized:match("<tool_call") then
                            local new_content = ""
                            local cursor = 1
                            local approve_ref = { value = true }
                            
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
                                        local new_system = "You are a sub-agent operating in SWARM mode. Your strict task is: " .. (task.instruction or "")
                                        if loaded_agents[switch_target] then
                                            new_system = new_system .. "\n\n=== YOUR GUIDELINES ===\n" .. loaded_agents[switch_target].system_prompt
                                        end
                                        new_system = new_system .. "\n\n=== INITIAL CONTEXT PROVIDED ===\n" .. context_text
                                        new_system = new_system .. "\n\n=== DELIVERY RULES (MANDATORY) ===\nWhen you finish the task and no longer need to use any tools, you MUST deliver your final report inside the <final_report>...</final_report> tags. The report MUST include a clear summary of what was done, the edited files, and list in a structured way the executed Git operations (if any). This tag ends your execution, and without it, the master will not read your response."
                                        
                                        local cfg = require('multi_context.config').options
                                        if cfg.language == "pt-BR" then
                                            new_system = new_system .. i18n.t("sys_lang_directive")
                                        end
                                        
                                        messages[1].content = new_system
                                        new_content = i18n.t("swarm_success_switch", switch_target)
                                        
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
                                        new_content = i18n.t("swarm_err_switch", task.agent, switch_target)
                                    end
                                end

                                visual_history = visual_history .. "\n\n## Sistema >>\n" .. new_content
                                table.insert(messages, { role = "user", content = new_content })
                                execute_turn() 
                                return
                            end
                        end
                        
                        if buf_id and vim.api.nvim_buf_is_valid(buf_id) then
                            local lines = vim.api.nvim_buf_get_lines(buf_id, 0, -1, false)
                            table.insert(lines, "")
                            table.insert(lines, i18n.t("swarm_task_done"))
                            vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
                        end
                        
                        worker.busy = false
                        local clean_res = final_report_text:gsub("%s+", "")
                        
                        task.retries = task.retries or 0
                        if clean_res == "" and task.retries < 2 then
                            task.retries = task.retries + 1
                            if buf_id and vim.api.nvim_buf_is_valid(buf_id) then
                                local lines = vim.api.nvim_buf_get_lines(buf_id, 0, -1, false)
                                table.insert(lines, i18n.t("swarm_api_empty", task.retries))
                                vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
                            end
                            table.insert(M.state.queue, task)
                        else
                            if clean_res == "" then final_report_text = i18n.t("swarm_fail_repeated") end
                            local has_next = false
                            if type(task.chain) == 'table' then
                                local c_idx = 0
                                for idx, a in ipairs(task.chain) do if a == task.agent then c_idx = idx; break end end
                                if c_idx > 0 and c_idx < #task.chain then
                                    task.agent = task.chain[c_idx + 1]
                                    task.instruction = (task.instruction or '') .. '\n\n' .. i18n.t("swarm_prev_report") .. '\n' .. final_report_text
                                    task.retries = 0
                                    table.insert(M.state.queue, task)
                                    has_next = true
                                end
                            end
                            if not has_next then
                            table.insert(M.state.reports, { agent = task.agent, result = final_report_text })
                            end
                        end
                        vim.schedule(M.dispatch_next)
                    end,
                    function(err)
                        if buf_id and vim.api.nvim_buf_is_valid(buf_id) then
                            local lines = vim.api.nvim_buf_get_lines(buf_id, 0, -1, false)
                            table.insert(lines, "")
                            table.insert(lines, i18n.t("swarm_api_err", tostring(err)))
                            vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
                        end
                        worker.busy = false
                        task.retries = task.retries or 0
                        if task.retries < 2 then
                            task.retries = task.retries + 1
                            if buf_id and vim.api.nvim_buf_is_valid(buf_id) then
                                local lines = vim.api.nvim_buf_get_lines(buf_id, 0, -1, false)
                                table.insert(lines, i18n.t("swarm_api_fail", worker.api.name, task.retries))
                                vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
                            end
                            table.insert(M.state.queue, task)
                        else
                            table.insert(M.state.reports, { agent = task.agent, result = i18n.t("swarm_fatal_err", tostring(err)) })
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
