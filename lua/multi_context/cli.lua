local EventBus = require('multi_context.core.event_bus')
local react_orchestrator = require('multi_context.core.react_orchestrator')
local utils = require('multi_context.utils.utils')
local config = require('multi_context.config')

local M = {}

M._setup_done = false
M.current_session_file = nil
M.shadow_buf = nil

M.setup = function()
    if M._setup_done then return end

    -- 1. Interceptor de Streaming (Em tempo real)
    EventBus.on("UI_APPEND_CHUNK", function(payload)
        if payload and payload.chunk then
            io.write(payload.chunk)
            io.flush()
        end
    end)

    -- 2. Interceptor de Linhas Inteiras (Logs e sistema)
    EventBus.on("UI_APPEND_LINES", function(payload)
        if payload and payload.lines then
            for _, line in ipairs(payload.lines) do
                io.write(line .. "\n")
            end
            io.flush()
        end
    end)

    -- 3. Interceptor de Encerramento (Auto-Save e Exit Code)
    EventBus.on("UI_TERMINATE_TURN", function(payload)
        -- Se o pipeline (Queue Mode) ainda tiver tarefas automáticas na fila, aguarda.
        if payload and payload.auto_trigger then
            return
        end
        
        -- Auto-Save: Se estivermos em uma Sessão Persistente, salva o buffer de volta no disco
        if M.current_session_file and M.shadow_buf and vim.api.nvim_buf_is_valid(M.shadow_buf) then
            local new_file, content = utils.build_workspace_content(M.shadow_buf, M.current_session_file)
            utils.export_to_workspace(content, new_file or M.current_session_file)
        end
        
        -- Encerra o Neovim com Sucesso para pipelines de CI/CD
        vim.cmd("cquit 0")
    end)

    M._setup_done = true
end

-- A ponte de entrada para o Shell do Linux
M.run = function(prompt, file_path)
    M.setup()

    -- Cria o Shadow Buffer (invisível, unlisted, temporário)
    M.shadow_buf = vim.api.nvim_create_buf(false, true)

    if file_path and file_path ~= "" then
        M.current_session_file = file_path
        -- Carrega a Memória (AST) se o arquivo já existir
        if vim.fn.filereadable(file_path) == 1 then
            local lines = vim.fn.readfile(file_path)
            vim.api.nvim_buf_set_lines(M.shadow_buf, 0, -1, false, lines)
            -- Sincroniza a Sessão para o orquestrador recuperar as tags <block>
            require('multi_context.core.session').sync_from_lines(lines)
        end
    else
        M.current_session_file = nil
    end

    -- Formata o Prompt do Usuário
    local user_name = (config.options and config.options.user_name) or "User"
    local prefix = "## " .. user_name .. " >> "
    
    local line_count = vim.api.nvim_buf_line_count(M.shadow_buf)
    local is_empty = (line_count == 1 and vim.api.nvim_buf_get_lines(M.shadow_buf, 0, 1, false)[1] == "")
    local insert_idx = is_empty and 0 or line_count
    
    local prompt_lines = vim.split(prefix .. prompt, "\n", {plain=true})
    
    -- Pula uma linha se o arquivo não estiver vazio
    if not is_empty then
        table.insert(prompt_lines, 1, "")
    end
    
    -- Injeta no Shadow Buffer
    vim.api.nvim_buf_set_lines(M.shadow_buf, insert_idx, -1, false, prompt_lines)

    -- Engana o Orquestrador passando o Shadow Buffer em vez de uma UI
    react_orchestrator.ProcessTurn(M.shadow_buf)
end

return M
