local EventBus = require('multi_context.core.event_bus')
local react_orchestrator = require('multi_context.core.react_orchestrator')
local utils = require('multi_context.utils.utils')
local config = require('multi_context.config')

describe("Fase 50: CLI Headless Adapter (DevOps Mode)", function()
    local orig_io_write = io.write
    local orig_io_flush = io.flush
    local orig_vim_cmd = vim.cmd
    local orig_process_turn = react_orchestrator.ProcessTurn
    local orig_build_workspace = utils.build_workspace_content
    local orig_export = utils.export_to_workspace
    
    local captured_stdout = ""
    local exit_code_captured = nil
    local process_turn_called_with_buf = nil
    local workspace_saved = nil

    before_each(function()
        captured_stdout = ""
        exit_code_captured = nil
        process_turn_called_with_buf = nil
        workspace_saved = nil
        
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

        react_orchestrator.ProcessTurn = function(buf) process_turn_called_with_buf = buf end
        utils.build_workspace_content = function(buf, file) return file, "MOCK_CONTENT" end
        utils.export_to_workspace = function(content, file) workspace_saved = file; return file end

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
        utils.export_to_workspace = orig_export
        EventBus.clear()
    end)

    it("Deve interceptar UI_APPEND_CHUNK e redirecionar para stdout em tempo real", function()
        require('multi_context.cli').setup()
        EventBus.emit("UI_APPEND_CHUNK", { chunk = "Avaliando " })
        EventBus.emit("UI_APPEND_CHUNK", { chunk = "o diff..." })
        assert.is_true(captured_stdout:match("Avaliando o diff...") ~= nil)
    end)

    it("Deve interceptar UI_APPEND_LINES e formatar com quebra de linha no stdout", function()
        require('multi_context.cli').setup()
        EventBus.emit("UI_APPEND_LINES", { lines = { "Executando...", "[OK]" } })
        assert.is_true(captured_stdout:match("Executando...\n%[OK%]\n") ~= nil)
    end)

    it("Deve interceptar UI_TERMINATE_TURN e encerrar o Neovim com cquit 0 (Sessao Efemera)", function()
        require('multi_context.cli').setup()
        EventBus.emit("UI_TERMINATE_TURN", { queued_tasks = nil, is_queue_mode = false })
        assert.are.equal(0, exit_code_captured)
    end)

    -- ================= NOVOS TESTES (ETAPA 2) =================

    it("Deve executar cli.run(prompt) criando um Shadow Buffer efêmero e chamando a IA", function()
        local cli = require('multi_context.cli')
        
        -- Simulando o terminal invocando o Neovim
        cli.run("refatore a função X")
        
        -- Verifica se o orquestrador foi acionado
        assert.is_not_nil(process_turn_called_with_buf, "react_orchestrator.ProcessTurn não foi chamado")
        
        -- Pega o conteúdo do buffer e verifica se o prompt foi injetado corretamente
        local lines = vim.api.nvim_buf_get_lines(process_turn_called_with_buf, 0, -1, false)
        local content = table.concat(lines, "\n")
        assert.is_true(content:match("## User >> refatore a função X") ~= nil, "O prompt não foi injetado no Shadow Buffer")
    end)

    it("Deve carregar um arquivo, usar o Shadow Buffer e salvar no evento TERMINATE_TURN (Sessao Persistente)", function()
        local cli = require('multi_context.cli')
        
        -- Simulamos a injeção com a flag persistente (ex: -f test_sessao.mctx)
        local mock_file = "test_sessao.mctx"
        cli.run("continue a analise", mock_file)
        
        assert.is_not_nil(process_turn_called_with_buf, "A IA não foi acionada para o arquivo persistente")
        
        -- Emitimos o evento de que a IA terminou o pipeline / Swarm
        EventBus.emit("UI_TERMINATE_TURN", { queued_tasks = nil, is_queue_mode = false })
        
        -- Verifica se o auto-save foi disparado no disco
        assert.are.equal(mock_file, workspace_saved, "O adaptador não salvou o arquivo .mctx antes de dar o cquit")
        assert.are.equal(0, exit_code_captured, "Não executou cquit 0 após salvar a sessão")
    end)
end)
