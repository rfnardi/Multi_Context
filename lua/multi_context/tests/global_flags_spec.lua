local init = require('multi_context')
local StateManager = require('multi_context.core.state_manager')
local react_orchestrator = require('multi_context.core.react_orchestrator')
local prompt_parser = require('multi_context.llm.prompt_parser')
local popup = require('multi_context.ui.popup')

describe("Fase 35 - Pre-Processador Global de Flags (--queue e --moa)", function()
    local buf
    local orig_execute
    local captured_messages
    local api_client = require('multi_context.llm.api_client')

    before_each(function()
        react_orchestrator.reset_turn()
        StateManager.get('react').is_queue_mode = false
        StateManager.get('react').queued_tasks = nil

        buf = vim.api.nvim_create_buf(false, true)
        popup.popup_buf = buf
        
        captured_messages = nil
        orig_execute = api_client.execute
        api_client.execute = function(msgs, on_start, on_chunk, on_done)
            captured_messages = msgs
        end
    end)

    after_each(function()
        api_client.execute = orig_execute
        vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("Deve capturar --queue, ligar is_queue_mode e fatiar a fila corretamente", function()
        local text = {
            "## Nardi >>",
            "@coder faca X --queue",
            "e depois",
            "@qa teste Y"
        }
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, text)
        
        require('multi_context.core.react_orchestrator').SendFromPopup()
        
        assert.is_true(StateManager.get('react').is_queue_mode, "A flag --queue deve ativar o modo de fila")
        assert.truthy(StateManager.get('react').queued_tasks:match("@qa"), "O segundo agente deve ter ido para a fila")
        assert.falsy(captured_messages[#captured_messages].content:match("%-%-queue"), "A flag deve ser removida do payload")
    end)

    it("Deve capturar --moa, nao fatiar a fila e redirecionar tudo para o tech_lead", function()
        local text = {
            "## Nardi >>",
            "@architect analise, @coder crie, @qa teste --moa",
        }
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, text)
        
        require('multi_context.core.react_orchestrator').SendFromPopup()
        
        assert.is_nil(StateManager.get('react').queued_tasks, "No modo MOA a fila deve ficar vazia")
        assert.are.same("tech_lead", StateManager.get('react').active_agent, "O tech_lead deve assumir o controle forcadamente")
        
        local last_msg = captured_messages[#captured_messages].content
        assert.truthy(last_msg:match("orquestração semântica"), "Deve injetar o prompt do tech_lead")
        assert.truthy(last_msg:match("@architect"), "As mencoes devem ser mantidas no payload")
        assert.falsy(last_msg:match("%-%-moa"), "A flag deve ser limpa")
    end)

    it("Deve processar a proxima tarefa automaticamente no TerminateTurn se is_queue_mode for true", function()
        StateManager.get('react').is_queue_mode = true
        StateManager.get('react').queued_tasks = "@qa teste"
        
        local send_called = false
        local orig_send = require('multi_context.core.react_orchestrator').SendFromPopup
        require('multi_context.core.react_orchestrator').SendFromPopup = function() send_called = true end
        
        local orig_defer = vim.defer_fn
        vim.defer_fn = function(cb, ms) cb() end
        
        require('multi_context.core.react_orchestrator').TerminateTurn()
        
        local lines = vim.api.nvim_buf_get_lines(popup.popup_buf, 0, -1, false)
        local chat_content = table.concat(lines, "\n")
        
        assert.falsy(chat_content:match("%[Checkpoint%]"), "Nao deve imprimir o checkpoint no modo queue")
        assert.truthy(chat_content:match("@qa teste"), "Deve reinjetar a proxima tarefa na tela")
        assert.is_true(send_called, "Deve ter agendado o proximo turno automaticamente")
        
        vim.defer_fn = orig_defer
        require('multi_context.core.react_orchestrator').SendFromPopup = orig_send
    end)
end)