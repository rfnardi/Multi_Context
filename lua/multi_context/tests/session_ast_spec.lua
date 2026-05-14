require("multi_context.tests.libuv_barrier")
local Session = require('multi_context.core.session')
local StateManager = require('multi_context.core.state_manager')

describe("Fase 35 - Etapa 1: Session AST RAM Abstraction", function()
    before_each(function()
        require("multi_context.config").options.auto_inject_context_md = false
        StateManager.reset()
        Session.clear()
    end)

    it("Deve inicializar uma sessao vazia na memoria", function()
        local msgs = Session.get_messages()
        assert.are.same(0, #msgs)
    end)

    it("Deve adicionar mensagens e manter os dados", function()
        Session.add_message("user", "Oi")
        Session.add_message("assistant", "Olá!")
        local msgs = Session.get_messages()
        assert.are.same(2, #msgs)
    end)

    it("Deve construir o payload purificado acoplando o system prompt", function()
        Session.add_message("user", "Request")
        local payload = Session.build_payload("SYSTEM PROMPT MOCK")
        assert.are.same("system", payload[1].role)
        assert.are.same("SYSTEM PROMPT MOCK", payload[1].content)
    end)

    it("Fase 46 - Integridade Arquitetural: Deve extrair conversas estritamente de XML blocks", function()
        local lines = {
            '<block id="b0" type="raw" role="user" status="active">Primeira instrução</block>',
            '<block id="b1" type="summary" role="assistant" status="active" covers="b0">Resumo comprimido pelo archivist</block>',
            '<block id="b2" type="raw" role="user" status="active">[Sistema]: Nova execucao</block>'
        }
        Session.sync_from_lines(lines)
        local msgs = Session.get_messages()
        
        assert.are.same(3, #msgs)
        assert.are.same("Primeira instrução", msgs[1].content)
        assert.are.same("summary", msgs[2].metadata.type)
        assert.are.same("[Sistema]: Nova execucao", msgs[3].content)
    end)
end)
