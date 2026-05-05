local Session = require('multi_context.core.session')
local StateManager = require('multi_context.core.state_manager')

describe("Fase 35 - Etapa 1: Session AST RAM Abstraction", function()
    before_each(function()
        StateManager.reset()
        Session.clear()
    end)

    it("Deve inicializar uma sessao vazia na memoria", function()
        local msgs = Session.get_messages()
        assert.are.same(0, #msgs)
    end)

    it("Deve adicionar mensagens e mesclar papéis sequenciais nativamente", function()
        Session.add_message("user", "Oi")
        Session.add_message("user", "Tudo bem?")
        Session.add_message("assistant", "Olá!")
        
        local msgs = Session.get_messages()
        assert.are.same(2, #msgs, "Mensagens do mesmo papel devem ser fundidas")
        assert.are.same("user", msgs[1].role)
        assert.truthy(msgs[1].content:match("Oi\n\nTudo bem?"))
        assert.are.same("assistant", msgs[2].role)
    end)

    it("Deve construir o payload purificado acoplando o system prompt", function()
        Session.add_message("user", "Request")
        local payload = Session.build_payload("SYSTEM PROMPT MOCK")
        
        assert.are.same(2, #payload)
        assert.are.same("system", payload[1].role)
        assert.are.same("SYSTEM PROMPT MOCK", payload[1].content)
        assert.are.same("user", payload[2].role)
    end)

    it("Deve serializar a arvore AST a partir de linhas de texto (Backward Compatibility)", function()
        local lines = {
            '<block id="1" type="raw" role="user" status="active">Hello</block>',
            '<block id="2" type="raw" role="assistant" status="active">Hi there</block>',
            '<block id="3" type="raw" role="user" status="active">How are you?</block>'
        }
        Session.sync_from_lines(lines)
        local msgs = Session.get_messages()
        
        assert.are.same(3, #msgs)
        assert.are.same("user", msgs[1].role)
        assert.are.same("assistant", msgs[2].role)
        assert.are.same("user", msgs[3].role)
        assert.are.same("How are you?", msgs[3].content)
    end)
end)
