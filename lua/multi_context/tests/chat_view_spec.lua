require("multi_context.tests.libuv_barrier")
local EventBus = require('multi_context.core.event_bus')
local popup = require('multi_context.ui.chat_view')

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

describe("Fase 48 - UX Minimalista do Carrossel de Abas do Swarm:", function()
    it("O título deve exibir apenas a aba Main e a aba do agente ativo", function()
        local config = require('multi_context.config')
        config.options.auto_inject_context_md = false -- simplifica a string gerada
        
        local popup = require('multi_context.ui.chat_view')
        local buf, win = popup.create_popup("Inicio")
        
        -- Simulando múltiplos buffers do swarm em andamento
        popup.swarm_buffers = {
            { buf = buf, name = "Main" },
            { buf = 2, name = "coder" },
            { buf = 3, name = "qa" },
            { buf = 4, name = "devops" }
        }
        
        -- Definindo a aba ativa do Swarm como a 3 ('qa')
        popup.current_swarm_index = 3
        
        -- Atualiza o título (este método deverá ser refatorado na fase GREEN)
        popup.update_title()
        
        -- Pegar o título que foi renderizado na janela
        local conf = vim.api.nvim_win_get_config(win)
        local title = (type(conf.title) == "table" and conf.title[1][1]) or conf.title or ""
        
        -- Asserts
        assert.truthy(title:match("Main") or title:match("%[1:Main%]"), "O título DEVE conter referência à aba Main.")
        assert.truthy(title:match("qa"), "O título DEVE conter o nome do worker atual (qa).")
        assert.falsy(title:match("coder"), "O título NÃO deve exibir abas inativas para economizar espaço visual (coder).")
        assert.falsy(title:match("devops"), "O título NÃO deve exibir abas inativas para economizar espaço visual (devops).")
    end)
end)
