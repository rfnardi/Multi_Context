local session = require('multi_context.core.session')
local StateManager = require('multi_context.core.state_manager')
local config = require('multi_context.config')
local dynamic_watchdog = require('multi_context.core.dynamic_watchdog')

describe("Fase 42.4: O Bibliotecário Assíncrono (Dynamic Watchdog)", function()
    
    before_each(function()
        StateManager.reset()
        session.clear()
        config.options.watchdog = {
            mode = "auto",
            strategy = "dynamic",
            background_api = "mock_cheap_api"
        }
    end)

    it("Deve extrair apenas blocos ativos e formatar o prompt para a API de background", function()
        session.add_message("user", "Bloco antigo 1", { id = "b1", status = "active", type = "raw" })
        session.add_message("assistant", "Bloco antigo 2", { id = "b2", status = "active", type = "raw" })
        
        local payload = dynamic_watchdog.build_background_payload()
        
        assert.truthy(payload[1].content:match("Você é um arquivista de background"))
        assert.truthy(payload[2].content:match("Bloco antigo 1"))
    end)

    it("A callback assíncrona deve aplicar o archiver.compress na RAM e emitir evento para a UI", function()
        session.add_message("user", "Erro no banco", { id = "b1", status = "active", type = "raw" })
        session.add_message("assistant", "Index criado", { id = "b2", status = "active", type = "raw" })
        
        local mock_api_response = "Resumo gerado em background: Banco de dados otimizado."
        
        dynamic_watchdog.on_background_response_received({"b1", "b2"}, mock_api_response)
        
        local msgs = session.get_messages()
        
        assert.are.same("archived", msgs[1].metadata.status)
        assert.are.same("archived", msgs[2].metadata.status)
        
        local resumo = msgs[#msgs]
        assert.are.same("summary", resumo.metadata.type)
        assert.are.same("b1,b2", resumo.metadata.covers)
    end)
    
end)
