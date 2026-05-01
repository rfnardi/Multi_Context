local EventBus = require('multi_context.core.event_bus')
local react_orchestrator = require('multi_context.core.react_orchestrator')

describe("Fase 35 - Etapa 2: Core Isolation", function()
    it("TerminateTurn deve emitir evento em vez de manipular a UI diretamente", function()
        local event_fired = false
        EventBus.on("UI_TERMINATE_TURN", function(payload)
            event_fired = true
        end)
        
        -- Mocking nvim_buf_set_lines para estourar erro se chamado diretamente
        local orig_set_lines = vim.api.nvim_buf_set_lines
        vim.api.nvim_buf_set_lines = function() error("Acoplamento detectado: O Core tentou tocar na tela!") end
        
        assert.has_no.errors(function()
            react_orchestrator.TerminateTurn()
        end)
        
        assert.is_true(event_fired, "O evento UI_TERMINATE_TURN deveria ter sido emitido.")
        vim.api.nvim_buf_set_lines = orig_set_lines
    end)
end)
