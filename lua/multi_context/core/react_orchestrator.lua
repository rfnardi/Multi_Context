local api = vim.api
local EventBus = require('multi_context.core.event_bus')
local StateManager = require('multi_context.core.state_manager')
local utils = require('multi_context.utils.utils')
local config = require('multi_context.config')
local prompt_parser = require('multi_context.llm.prompt_parser')
local tool_parser = require('multi_context.ecosystem.tool_parser')
local tool_runner = require('multi_context.ecosystem.tool_runner')

local M = {}

local function get_state()
    local st = StateManager.get("react")
    if st.is_autonomous == nil then st.is_autonomous = false end
    if st.auto_loop_count == nil then st.auto_loop_count = 0 end
    if st.is_queue_mode == nil then st.is_queue_mode = false end
    if st.is_moa_mode == nil then st.is_moa_mode = false end
    return st
end

M.setup = function()
    EventBus.on("USER_SUBMIT", function(payload)
        M.ProcessTurn(payload.buf)
    end)
end

M.reset_turn = function()
    StateManager.patch("react", {
        is_autonomous = false,
        auto_loop_count = 0,
        active_job_id = nil,
        user_aborted = false,
        is_moa_mode = false,
    })
end

M.check_circuit_breaker = function()
    local react_state = get_state()
    react_state.auto_loop_count = (react_state.auto_loop_count or 0) + 1
    if react_state.auto_loop_count >= 15 then
        vim.notify("Limite de 15 loops atingido. Pausando por segurança.", vim.log.levels.WARN)
        return true
    end
    return false
end

M.abort_stream = function(is_user)
    local react_state = get_state()
    if react_state.active_job_id then
        react_state.user_aborted = is_user or false
        pcall(vim.fn.jobstop, react_state.active_job_id)
        react_state.active_job_id = nil
    end
end

M.TerminateTurn = function()
    M.reset_turn()
    local react_state = get_state()
    local cfg = require('multi_context.config')
    
    local auto_trigger = false
    if react_state.queued_tasks and react_state.queued_tasks ~= "" then
        if react_state.is_queue_mode then auto_trigger = true end
    end
    
    EventBus.emit("UI_TERMINATE_TURN", {
        current_api = cfg.get_current_api(),
        user_name = cfg.options.user_name or "Nardi",
        queued_tasks = react_state.queued_tasks,
        is_queue_mode = react_state.is_queue_mode,
        auto_trigger = auto_trigger
    })
    
    if react_state.queued_tasks and react_state.queued_tasks ~= "" then
        react_state.queued_tasks = nil
    else
        react_state.is_queue_mode = false
    end
end

local function get_context_md_content()
    local root = vim.fn.system("git rev-parse --show-toplevel")
    if vim.v.shell_error == 0 then root = root:gsub("\n", "") else root = vim.fn.getcwd() end
    local filepath = root .. "/CONTEXT.md"
    if vim.fn.filereadable(filepath) == 1 then return table.concat(vim.fn.readfile(filepath), "\n") end
    return nil
end

M.ProcessTurn = function(buf)
    pcall(function() require('multi_context.ecosystem.skills_manager').load_skills() end)
    if not buf or not api.nvim_buf_is_valid(buf) then return end
    
    local start_idx, _ = utils.find_last_user_line(buf)
    if not start_idx then return end

    local cfg = require('multi_context.config')
    local user_prefix = "## " .. (cfg.options.user_name or "Nardi") .. " >>"
    local lines = api.nvim_buf_get_lines(buf, start_idx, -1, false)
    if lines[1] then lines[1] = lines[1]:gsub("^" .. user_prefix .. "%s*", "") end

    local agents = require('multi_context.agents').load_agents()
    local intent_parser = require('multi_context.core.intent_parser')
    
    local parsed_intent = intent_parser.parse_lines(lines, agents)
    local react_state = get_state()
    
    if parsed_intent.flags.is_queue then react_state.is_queue_mode = true end
    if parsed_intent.flags.is_moa then react_state.is_moa_mode = true end

    local raw_user_text = parsed_intent.raw_current_task
    if parsed_intent.queued_text then react_state.queued_tasks = parsed_intent.queued_text end
    if raw_user_text == "" then vim.notify(require("multi_context.i18n").t("type_something"), vim.log.levels.WARN); return end

    local prompt_parsed = prompt_parser.parse_user_input(raw_user_text, agents)
    
    if prompt_parsed.agent_name then
        if prompt_parsed.agent_name == "reset" then react_state.active_agent = nil
        else react_state.active_agent = prompt_parsed.agent_name end
    end
    if prompt_parsed.is_autonomous then react_state.is_autonomous = true end

    local text_to_send = prompt_parsed.text_to_send
    local active_agent_name = react_state.active_agent

    local mem_tracker = require('multi_context.utils.memory_tracker')
    local current_tokens = utils.estimate_tokens(buf)
    local prompt_tokens = math.floor(#text_to_send / 4)
    local predicted_total = mem_tracker.predict_next_total(current_tokens, prompt_tokens)
    local horizon = (cfg.options.cognitive_horizon or 4000) * (cfg.options.user_tolerance or 1.0)

    if predicted_total > horizon and active_agent_name ~= "archivist" then
        react_state.pending_user_prompt = text_to_send
        react_state.active_agent = "archivist"
        active_agent_name = "archivist"
        text_to_send = require("multi_context.i18n").t("archivist_sys_prompt")
        
        local msg = require("multi_context.i18n").t("guard_limit", predicted_total, horizon)
        EventBus.emit("UI_APPEND_LINES", { buf = buf, lines = { "", msg, "" } })
    end

    local sending_msg = require("multi_context.i18n").t("sending_req", active_agent_name and require("multi_context.i18n").t("sending_via", active_agent_name) or "")
    EventBus.emit("UI_APPEND_LINES", { buf = buf, lines = { "", sending_msg } })

    local Session = require('multi_context.core.session')
    local history_lines = api.nvim_buf_get_lines(buf, 0, start_idx, false)
    
    Session.sync_from_lines(history_lines)
    Session.add_message("user", text_to_send)
    
    local base_sys_prompt = cfg.options.master_prompt or "Você é um Engenheiro de Software Autônomo no Neovim."
    local memory_context = get_context_md_content()
    local system_prompt = prompt_parser.build_system_prompt(base_sys_prompt, memory_context, active_agent_name, agents, current_tokens)
    
    local messages = Session.build_payload(system_prompt)

    local response_started = false
    local accumulated_text = ""
    local current_ia_start_idx = nil
    
    local function remove_sending_msg()
        local count = api.nvim_buf_line_count(buf)
        local last_line = api.nvim_buf_get_lines(buf, count - 1, count, false)[1]
        if last_line:match("%[Enviando requisi") then 
            EventBus.emit("UI_SET_LINES_PARTIAL", { buf = buf, start_idx = count - 2, end_idx = count, lines = {} })
        end
    end

    EventBus.emit("UI_START_STREAMING", { buf = buf })

    require('multi_context.llm.api_client').execute(messages, 
        function(job_id)
            react_state.active_job_id = job_id
            react_state.user_aborted = false
        end,
        function(chunk, api_entry)
            if not response_started then
                remove_sending_msg()
                local ia_title = "## IA (" .. api_entry.model .. ")" .. (active_agent_name and ("[@" .. active_agent_name .. "]") or "") .. " >> "
                local count_before = api.nvim_buf_line_count(buf)
                EventBus.emit("UI_APPEND_LINES", { buf = buf, lines = { "", ia_title, "" } })
                current_ia_start_idx = count_before + 2
                response_started = true
            end
            if type(chunk) == "string" and chunk ~= "" then
                EventBus.emit("UI_APPEND_CHUNK", { buf = buf, chunk = chunk })
                EventBus.emit("UI_CHUNK_RECEIVED", { buf = buf })
                
                accumulated_text = accumulated_text .. chunk
                if accumulated_text:match("</tool_call>%s*$") then
                    local tags = {}
                    for n in accumulated_text:gmatch('<tool_call[^>]*name="([^"]+)"') do table.insert(tags, n) end
                    local last_name = tags[#tags]
                    if last_name and (last_name == "edit_file" or last_name == "replace_lines" or last_name == "run_shell") then
                        M.abort_stream(false)
                    end
                end
                
                EventBus.emit("UI_UPDATE_TITLE")
            end
        end,
        function(api_entry, metrics)
            require('multi_context.utils.memory_tracker').add_turn(math.floor(#accumulated_text / 4))
            EventBus.emit("UI_STOP_STREAMING", { buf = buf })
            react_state.active_job_id = nil
            
            if react_state.user_aborted then
                EventBus.emit("UI_APPEND_LINES", { buf = buf, lines = { "", require("multi_context.i18n").t("gen_aborted") } })
                M.TerminateTurn()
                return
            end
            
            if not response_started then remove_sending_msg() end
            if metrics and (metrics.cache_read_input_tokens or 0) > 0 then
                vim.notify(require("multi_context.i18n").t("prompt_caching", metrics.cache_read_input_tokens), vim.log.levels.INFO)
            end
            
            local b_lines = api.nvim_buf_get_lines(buf, 0, -1, false)
            local has_tool = false
            local scan_start = current_ia_start_idx or 1
            for i = scan_start, #b_lines do
                if b_lines[i]:match("<tool_call") then has_tool = true; break end
            end

            if react_state.pending_user_prompt and react_state.active_agent == "archivist" then
                vim.defer_fn(function() M.HandleArchivistCompression(current_ia_start_idx, buf) end, 100)
            elseif has_tool then
                vim.defer_fn(function() M.ExecuteTools(current_ia_start_idx, buf) end, 100)
            else
                M.TerminateTurn()
            end
        end,
        function(err_msg)
            EventBus.emit("UI_STOP_STREAMING", { buf = buf })
            remove_sending_msg()
            EventBus.emit("UI_APPEND_LINES", { buf = buf, lines = { "", "**[ERRO]** " .. err_msg, "", user_prefix .. " " } })
            react_state.is_autonomous = false
        end
    )
end

M.ExecuteTools = function(ia_idx, buf)
    local react_state = get_state()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local last_ia_idx = ia_idx
    
    if not last_ia_idx then
        last_ia_idx = 0
        for i = #lines, 1, -1 do if lines[i]:match("^## IA %(") then last_ia_idx = i; break end end
        if last_ia_idx == 0 then
            for i = #lines, 1, -1 do if lines[i]:match("^## IA") then last_ia_idx = i; break end end
        end
    end
    if last_ia_idx == 0 then return end

    local prefix_lines = {}; for i = 1, last_ia_idx - 1 do table.insert(prefix_lines, lines[i]) end
    local process_lines = {}; for i = last_ia_idx, #lines do table.insert(process_lines, lines[i]) end
    
    local content_to_process = tool_parser.sanitize_payload(table.concat(process_lines, "\n"))

    local new_content = ""
    local cursor = 1
    local has_changes = false
    local abort_all = false
    local approve_all_ref = { value = false }
    local pending_rewrite_content = nil
    local should_continue_loop = false 

    while cursor <= #content_to_process do
        local parsed_tag = tool_parser.parse_next_tool(content_to_process, cursor)
        
        if not parsed_tag then
            new_content = new_content .. content_to_process:sub(cursor)
            break
        end

        new_content = new_content .. parsed_tag.text_before

        if parsed_tag.is_invalid or not parsed_tag.name or parsed_tag.name == "" then
            new_content = new_content .. parsed_tag.raw_tag .. (parsed_tag.inner or "") .. (parsed_tag.close_start and "</tool_call>" or "")
            cursor = parsed_tag.close_end + 1
            goto continue
        end

        if abort_all then
            new_content = new_content .. parsed_tag.raw_tag .. parsed_tag.inner .. "</tool_call>"
            cursor = parsed_tag.close_end + 1
            goto continue
        end

        has_changes = true

        do
            local tag_output, should_abort, cont_loop, rew_content, backup_made = tool_runner.execute(
                parsed_tag, 
                react_state.is_autonomous, 
                approve_all_ref, 
                buf
            )

            if backup_made then StateManager.get('react').last_backup = backup_made end
            if rew_content then pending_rewrite_content = rew_content end
            if cont_loop then should_continue_loop = true end

            if should_abort then
                abort_all = true
                new_content = new_content .. parsed_tag.raw_tag .. parsed_tag.inner .. "</tool_call>"
            else
                new_content = new_content .. tag_output
                if tag_output:match(">%[Sistema%]: ERRO %- Ferramenta") then
                    react_state.is_autonomous = false
                    should_continue_loop = false
                end
            end
        end

        ::continue::
        cursor = parsed_tag.close_end + 1
    end

    if not has_changes or abort_all then M.TerminateTurn(); return end

    if pending_rewrite_content then
        local rewrite_lines = vim.split(pending_rewrite_content, "\n", {plain=true})
        EventBus.emit("UI_SET_LINES", { buf = buf, lines = rewrite_lines })
    else
        local final_lines = {}
        for _, l in ipairs(prefix_lines) do table.insert(final_lines, l) end
        for _, l in ipairs(vim.split(new_content, "\n", {plain=true})) do table.insert(final_lines, l) end
        EventBus.emit("UI_SET_LINES", { buf = buf, lines = final_lines })
    end

    if pending_rewrite_content or (not should_continue_loop and not react_state.is_autonomous) then
        M.TerminateTurn(); return
    end

    if M.check_circuit_breaker() then
        M.TerminateTurn(); return
    end

    local cfg = require('multi_context.config')
    local user_prefix = "## " .. (cfg.options.user_name or "Nardi") .. " >>"
    
    local sys_msg = require("multi_context.i18n").t("sys_info_collected")
    if not should_continue_loop and react_state.is_autonomous then
        sys_msg = require("multi_context.i18n").t("sys_action_executed")
    end

    EventBus.emit("UI_APPEND_LINES", { buf = buf, lines = { "", user_prefix .. " " .. sys_msg } })
    vim.defer_fn(function() M.ProcessTurn(buf) end, 100)
end

M.HandleArchivistCompression = function(ia_idx, buf)
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local content = table.concat(lines, "\n")
    
    local genesis = content:match("<genesis>(.-)</genesis>") or "N/A"
    local plan = content:match("<plan>(.-)</plan>") or "N/A"
    local journey = content:match("<journey>(.-)</journey>") or "N/A"
    local now = content:match("<now>(.-)</now>") or "N/A"
    
    local backup_file = vim.fn.stdpath("data") .. "/mctx_pre_compression_" .. os.date("%Y%m%d_%H%M%S") .. ".mctx"
    vim.fn.writefile(lines, backup_file)
    
    local cfg = require('multi_context.config')
    local user_prefix = "## " .. (cfg.options.user_name or "Nardi") .. " >>"
    
    local new_lines = { require("multi_context.i18n").t("quad_memory") }
    
    local function append_split(txt)
        if not txt then return end
        for _, l in ipairs(vim.split(txt, "\n", {plain=true})) do table.insert(new_lines, l) end
    end
    
    append_split("<genesis>\n" .. vim.trim(genesis) .. "\n</genesis>\n")
    append_split("<plan>\n" .. vim.trim(plan) .. "\n</plan>\n")
    append_split("<journey>\n" .. vim.trim(journey) .. "\n</journey>\n")
    append_split("<now>\n" .. vim.trim(now) .. "\n</now>\n")
    
    local react_state = get_state()
    append_split(user_prefix .. " " .. (react_state.pending_user_prompt or ""))
    
    EventBus.emit("UI_SET_LINES", { buf = buf, lines = new_lines })
    
    require('multi_context.utils.memory_tracker').reset()
    react_state.pending_user_prompt = nil
    react_state.active_agent = nil
    
    EventBus.emit("UI_ARCHIVIST_DONE", { buf = buf })
    vim.notify(require("multi_context.i18n").t("archivist_compressed"), vim.log.levels.INFO)
    vim.defer_fn(function() M.ProcessTurn(buf) end, 100)
end

return M
