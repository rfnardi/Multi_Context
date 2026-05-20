local EventBus = require('multi_context.core.event_bus')
local react_orchestrator = require('multi_context.core.react_orchestrator')
local utils = require('multi_context.utils.utils')
local config = require('multi_context.config')
local state = require('multi_context.core.state_manager')

describe("Fase 50: CLI Headless Adapter (DevOps Mode) - Full Suite", function()
    local orig_io_write = io.write
    local orig_io_flush = io.flush
    local orig_vim_cmd = vim.cmd
    local orig_process_turn = react_orchestrator.ProcessTurn
    local orig_build_workspace = utils.build_workspace_content
    local orig_writefile = vim.fn.writefile
    local orig_state_set = state.set
    local orig_defer_fn = vim.defer_fn
    
    local captured_stdout = ""
    local exit_code_captured = nil
    local process_turn_call_count = 0
    local process_turn_called_with_buf = nil
    local workspace_saved = nil
    local state_set_calls = {}

    before_each(function()
        captured_stdout = ""
        exit_code_captured = nil
        process_turn_call_count = 0
        process_turn_called_with_buf = nil
        workspace_saved = nil
        state_set_calls = {}
        
        io.write = function(...)
            local args = {...}
            for _, str in ipairs(args) do if type(str) == "string" then captured_stdout = captured_stdout .. str end end
        end
        io.flush = function() end
        
        vim.cmd = function(cmd_str)
            if type(cmd_str) == "string" and cmd_str:match("^cquit") then
                exit_code_captured = tonumber(cmd_str:match("%d+"))
            else
                pcall(orig_vim_cmd, cmd_str)
            end
        end

        react_orchestrator.ProcessTurn = function(buf) 
            process_turn_call_count = process_turn_call_count + 1 
            process_turn_called_with_buf = buf
        end
        
        utils.build_workspace_content = function(buf, file) return file, "MOCK_CONTENT" end
        vim.fn.writefile = function(lines, file) workspace_saved = file end
        
        state.set = function(k, v)
            state_set_calls[k] = v
            orig_state_set(k, v)
        end
        
        vim.defer_fn = function(cb, timeout) cb() end

        config.options = config.options or {}
        config.options.user_name = "User"

        EventBus.clear()
        package.loaded['multi_context.cli'] = nil
    end)

    after_each(function()
        io.write = orig_io_write
        io.flush = orig_io_flush
        vim.cmd = orig_vim_cmd
        react_orchestrator.ProcessTurn = orig_process_turn
        utils.build_workspace_content = orig_build_workspace
        vim.fn.writefile = orig_writefile
        state.set = orig_state_set
        vim.defer_fn = orig_defer_fn
        EventBus.clear()
    end)

    -- ==========================================================
    -- 1. TESTES LEGADOS (ETAPAS 1 E 2)
    -- ==========================================================
    it("Deve interceptar UI_APPEND_CHUNK e redirecionar para stdout em tempo real", function()
        require('multi_context.cli').setup()
        EventBus.emit("UI_APPEND_CHUNK", { chunk = "Avaliando " })
        EventBus.emit("UI_APPEND_CHUNK", { chunk = "o diff..." })
        assert.is_true(captured_stdout:match("Avaliando o diff...") ~= nil)
    end)

    it("Deve interceptar UI_APPEND_LINES e formatar com quebra de linha no stdout", function()
        require('multi_context.cli').setup()
        EventBus.emit("UI_APPEND_LINES", { lines = { "Executando...", "Finalizado" } })
        assert.is_true(captured_stdout:match("Executando...\nFinalizado\n") ~= nil)
    end)

    it("Deve interceptar UI_TERMINATE_TURN e encerrar o Neovim com cquit 0 (Sessao Efemera)", function()
        require('multi_context.cli').setup()
        EventBus.emit("UI_TERMINATE_TURN", { queued_tasks = nil, is_queue_mode = false })
        assert.are.equal(0, exit_code_captured)
    end)

    it("Deve executar cli.run(prompt) criando um Shadow Buffer efêmero e chamando a IA", function()
        local cli = require('multi_context.cli')
        cli.run("refatore a função X")
        assert.is_not_nil(process_turn_called_with_buf, "react_orchestrator.ProcessTurn não foi chamado")
        local lines = vim.api.nvim_buf_get_lines(process_turn_called_with_buf, 0, -1, false)
        local content = table.concat(lines, "\n")
        assert.is_true(content:match("## User >> refatore a função X") ~= nil, "O prompt não foi injetado no Shadow Buffer")
    end)

    -- ==========================================================
    -- 2. TESTES DE REGRESSÃO E FIXES DE UX
    -- ==========================================================
    it("Regressão: Deve limpar a memória da sessão no boot para evitar 'Chats Fantasmas'", function()
        require('multi_context.cli').run("meu prompt")
        assert.is_not_nil(state_set_calls['session_messages'], "O estado da sessão não foi resetado")
        assert.is_not_nil(state_set_calls['react'], "O estado do orchestrator não foi resetado")
    end)

    it("Regressão: O Stream Parser deve suprimir tags XML e formatar Tool Calls (TUI limpa)", function()
        require('multi_context.cli').setup()
        
        EventBus.emit("UI_APPEND_CHUNK", { chunk = "<tool_call name=\"read_file\" path=\"main.py\">" })
        EventBus.emit("UI_APPEND_CHUNK", { chunk = "Lendo arquivo...</tool_call>" })
        
        assert.is_nil(captured_stdout:match("<tool_call"), "A tag XML bruta vazou para a interface do terminal!")
        assert.is_not_nil(captured_stdout:match("%[> TOOL_CALL: read_file %(path: main.py%)%]"), "O formatador ASCII não converteu a tag corretamente.")
    end)

    it("Regressão: Deve remover emojis excessivos dos logs nativos e substituí-los por [✓]", function()
        require('multi_context.cli').setup()
        
        vim.notify("✅ Edição aplicada")
        EventBus.emit("UI_APPEND_LINES", { lines = { "✅ Prompt Caching: 1000 tokens" } })

        assert.is_nil(captured_stdout:match("✅"), "Ainda existem emojis ✅ vazando no console.")
        assert.is_not_nil(captured_stdout:match("%[✓%] Edição aplicada"), "A notificação não foi purificada.")
        assert.is_not_nil(captured_stdout:match("%[✓%] Prompt Caching:"), "A linha de caching não foi purificada.")
    end)

    it("Regressão: Deve salvar o arquivo EXATAMENTE no diretório local bypassando .mctx_chats/", function()
        local cli = require('multi_context.cli')
        local current_dir_file = "meu_app_teste.mctx"
        
        cli.run("prompt", current_dir_file)
        EventBus.emit("UI_TERMINATE_TURN", { queued_tasks = nil, is_queue_mode = false })
        
        assert.are.equal(current_dir_file, workspace_saved, "O sistema tentou salvar usando as regras legadas de diretório.")
        assert.are.equal(0, exit_code_captured, "O Neovim não retornou cquit 0.")
    end)

    it("Regressão: Encadeamento de Queue/MoA deve chamar ProcessTurn recursivo sem fechar o Neovim", function()
        local cli = require('multi_context.cli')
        
        cli.run("faça X")
        assert.are.equal(1, process_turn_call_count)
        
        EventBus.emit("UI_TERMINATE_TURN", { 
            auto_trigger = true, 
            queued_tasks = "@tech_lead faça Y" 
        })
        
        assert.is_nil(exit_code_captured, "O CLI executou cquit e matou a IA no meio do pipeline!")
        assert.is_not_nil(captured_stdout:match("%[QUEUE%]"), "O log visual de avanço da fila não foi impresso.")
        assert.are.equal(2, process_turn_call_count, "O ProcessTurn recursivo não foi acionado para o próximo agente.")
    end)
end)
