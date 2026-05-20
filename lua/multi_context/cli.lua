local EventBus = require('multi_context.core.event_bus')
local react_orchestrator = require('multi_context.core.react_orchestrator')
local utils = require('multi_context.utils.utils')
local config = require('multi_context.config')
local session = require('multi_context.core.session')
local state = require('multi_context.core.state_manager')

local M = {}

M._setup_done = false
M.current_session_file = nil
M.shadow_buf = nil

-- ==========================================
-- GESTÃO DO SPINNER E TERMINAL
-- ==========================================
local spinner_frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
local spinner_idx = 1
local spinner_timer = nil
local is_spinning = false
local current_spinner_msg = ""

local function stop_spinner()
    if not is_spinning then return end
    is_spinning = false
    if spinner_timer then
        spinner_timer:stop()
        spinner_timer:close()
        spinner_timer = nil
    end
    io.write("\r\27[K")
    io.flush()
end

local function start_spinner(msg)
    if is_spinning then stop_spinner() end
    is_spinning = true
    current_spinner_msg = msg or "Processando..."
    
    io.write("\r\27[K\27[36m" .. spinner_frames[spinner_idx] .. " " .. current_spinner_msg .. "\27[0m")
    io.flush()
    
    spinner_timer = vim.uv.new_timer()
    spinner_timer:start(100, 100, vim.schedule_wrap(function()
        if not is_spinning then return end
        spinner_idx = spinner_idx + 1
        if spinner_idx > #spinner_frames then spinner_idx = 1 end
        io.write("\r\27[K\27[36m" .. spinner_frames[spinner_idx] .. " " .. current_spinner_msg .. "\27[0m")
        io.flush()
    end))
end

local function print_console(text)
    if not text or text == "" then return end
    local was_spinning = is_spinning
    if was_spinning then stop_spinner() end
    io.write(text)
    io.flush()
    if was_spinning then start_spinner(current_spinner_msg) end
end

local function print_line(text)
    print_console(text .. "\n")
end

-- ==========================================
-- SETUP DO ADAPTADOR TUI
-- ==========================================
M.setup = function()
    if M._setup_done then return end

    vim.notify = function(msg, level)
        msg = msg:gsub("^%[Harvester%]", "Harvester:")
        msg = msg:gsub("✅%s*", "") 
        print_line("\27[32m[✓] " .. msg .. "\27[0m")
    end

    EventBus.on("UI_START_STREAMING", function() stop_spinner() end)
    EventBus.on("UI_STOP_STREAMING", function() start_spinner("Executando tarefas e ferramentas...") end)

    local stream_buffer = ""
    local in_tag = false
    local skip_next_newline = false

    EventBus.on("UI_APPEND_CHUNK", function(payload)
        if not payload or not payload.chunk then return end
        local chunk = payload.chunk
        for i = 1, #chunk do
            local char = chunk:sub(i, i)
            
            if skip_next_newline and (char == "\n" or char == "\r") then
                -- Silêncio absoluto
            elseif char == "<" then
                in_tag = true
                stream_buffer = char
                skip_next_newline = false
            elseif char == ">" and in_tag then
                stream_buffer = stream_buffer .. char
                in_tag = false
                
                local tag = stream_buffer
                stream_buffer = ""
                skip_next_newline = true 
                
                if tag:match("^</") then 
                    -- Hide
                elseif tag:match("^<tool_call") then
                    local name = tag:match('name="([^"]+)"') or "unknown"
                    local attrs = ""
                    for k, v in tag:gmatch('([%w_]+)="([^"]+)"') do
                        if k ~= "name" then attrs = attrs .. k .. ": " .. v .. ", " end
                    end
                    attrs = attrs:gsub(", $", "")
                    print_line("\27[35m[> TOOL_CALL: " .. name .. (attrs ~= "" and " (" .. attrs .. ")" or "") .. "]\27[0m")
                end
            elseif in_tag then
                stream_buffer = stream_buffer .. char
            else
                skip_next_newline = false
                print_console(char)
            end
        end
    end)

    EventBus.on("UI_APPEND_LINES", function(payload)
        if not payload or not payload.lines then return end
        for _, line in ipairs(payload.lines) do
            if line:match("^## User >> <block.*type=\"tool_result\"") then
                -- Hide
            elseif line:match("</?content>") or line:match("</?block>") then
                -- Hide
            elseif line:match(">%[Sistema%]: (.*)") then
                local sys_msg = line:match(">%[Sistema%]: (.*)")
                print_line("\27[32m[SISTEMA]: " .. sys_msg .. "\27[0m")
            elseif line:match("^%[Enviando requisição via (.*)%]") then
                local target = line:match("^%[Enviando requisição via (.*)%]")
                print_line("\27[33m[AGENTE]: " .. target .. "\27[0m")
            elseif line:match("^## IA %((.-)%)%[(.-)%] >> <block") then
                local model, agent = line:match("^## IA %((.-)%)%[(.-)%] >> <block")
                print_line("\27[36m─────────────────────────────────────────────────────────────\27[0m")
                print_line("\27[36m[IA: " .. model .. " | " .. agent .. "]\27[0m")
                print_line("\27[36m─────────────────────────────────────────────────────────────\27[0m")
            elseif line:match("^## User >>") then
                local text = line:gsub("^## User >> %s*<block[^>]*>", ""):gsub("^## User >> ", "")
                if text ~= "" then print_line("\27[34m[USER]: " .. text .. "\27[0m") end
            elseif line:match("Prompt Caching:") then
                local clean = line:gsub("✅%s*", "")
                print_line("\27[32m[✓] " .. clean .. "\27[0m")
            else
                if line ~= "" then print_line(line) end
            end
        end
    end)

    -- ==============================================================
    -- FIX: O MOTOR DE LOOP ASSÍNCRONO PARA QUEUES E SWARMS
    -- ==============================================================
    EventBus.on("UI_TERMINATE_TURN", function(payload)
        stop_spinner()

        -- O orquestrador tem mais tarefas na fila?
        if payload and payload.auto_trigger and payload.queued_tasks then
            print_line("\n\27[33m[QUEUE]: Avançando para o próximo passo da fila...\27[0m")
            
            local prefix = "## " .. (config.options.user_name or "User") .. " >> "
            local lines = vim.split(prefix .. payload.queued_tasks, "\n", {plain=true})
            table.insert(lines, 1, "")
            
            -- Injeta a próxima tarefa no buffer
            vim.api.nvim_buf_set_lines(M.shadow_buf, vim.api.nvim_buf_line_count(M.shadow_buf), -1, false, lines)
            
            -- Dispara o Orquestrador novamente para o próximo Agente
            start_spinner("Delegando próxima tarefa da fila...")
            vim.defer_fn(function() react_orchestrator.ProcessTurn(M.shadow_buf) end, 100)
            return
        end
        
        -- Nenhuma fila restante. Terminamos.
        if M.current_session_file and M.shadow_buf and vim.api.nvim_buf_is_valid(M.shadow_buf) then
            M.format_json_in_buffer(M.shadow_buf)
            local _, final_content = utils.build_workspace_content(M.shadow_buf, M.current_session_file)
            vim.fn.writefile(vim.split(final_content, "\n", {plain=true}), M.current_session_file)
            print_line("\n\27[32m[✓] Sessão salva em " .. M.current_session_file .. "\27[0m")
        end
        
        print_line("\27[32m[✓] Automação concluída.\27[0m\n")
        vim.cmd("cquit 0")
    end)

    M._setup_done = true
end

M.format_json_in_buffer = function(buf)
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local content = table.concat(lines, "\n")
    content = content:gsub("<tool_call[^>]*>(.-)</tool_call>", function(inner)
        local trimmed = vim.trim(inner)
        if trimmed:match("^{") and trimmed:match("}$") then
            local ok, parsed = pcall(vim.fn.json_decode, trimmed)
            if ok then
                local pretty = vim.inspect(parsed) 
                pretty = pretty:gsub("=", ":"):gsub("%[", ""):gsub("%]", "")
                return "\n" .. pretty .. "\n"
            end
        end
        return inner
    end)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(content, "\n", {plain=true}))
end

M.run = function(prompt, file_path)
    M.setup()
    
    state.set('session_messages', {})
    state.set('react', {})

    M.shadow_buf = vim.api.nvim_create_buf(false, true)

    if file_path and file_path ~= "" then
        M.current_session_file = file_path
        if vim.fn.filereadable(file_path) == 1 then
            local lines = vim.fn.readfile(file_path)
            vim.api.nvim_buf_set_lines(M.shadow_buf, 0, -1, false, lines)
            session.sync_from_lines(lines)
        end
    else
        M.current_session_file = nil
    end

    local prefix = "## User >> "
    local insert_idx = vim.api.nvim_buf_line_count(M.shadow_buf)
    if insert_idx == 1 and vim.api.nvim_buf_get_lines(M.shadow_buf, 0, 1, false)[1] == "" then insert_idx = 0 end
    
    local prompt_lines = vim.split(prefix .. prompt, "\n", {plain=true})
    if insert_idx > 0 then table.insert(prompt_lines, 1, "") end
    
    vim.api.nvim_buf_set_lines(M.shadow_buf, insert_idx, -1, false, prompt_lines)

    start_spinner("Iniciando raciocínio...")
    react_orchestrator.ProcessTurn(M.shadow_buf)
end

return M
