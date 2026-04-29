local EventBus = require('multi_context.core.event_bus')
local popup = require('multi_context.ui.popup')

describe("UI View Arquitetura 2.0 (popup.lua):", function()
    it("Deve injetar texto no buffer ao escutar o evento UI_APPEND_CHUNK", function()
        local buf, win = popup.create_popup("Inicio")
        
        -- Em vez de chamar funções da UI, emitimos um evento no barramento global!
        EventBus.emit("UI_APPEND_CHUNK", { buf = buf, chunk = "Texto do LLM injetado via Evento!" })
        
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        local content = table.concat(lines, "\n")
        
        assert.truthy(content:match("Texto do LLM injetado via Evento!"), "A UI falhou em reagir ao evento do core")
    end)
    
    it("Deve atualizar o buffer do worker do Swarm ao escutar UI_SWARM_WORKER_UPDATE", function()
        local buf = popup.create_swarm_buffer("mock_agent", "instrucao", "mock_api")
        
        EventBus.emit("UI_SWARM_WORKER_UPDATE", { buf = buf, text = "Relatorio do Swarm via Evento" })
        
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        local content = table.concat(lines, "\n")
        assert.truthy(content:match("Relatorio do Swarm via Evento"), "A UI do Swarm falhou em reagir ao evento")
    end)
end)
