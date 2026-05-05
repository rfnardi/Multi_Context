local session = require('multi_context.core.session')
local StateManager = require('multi_context.core.state_manager')

describe("Fase 42.1: AST Polimórfica de Blocos", function()
    
    before_each(function()
        StateManager.set('session_messages', {})
    end)

    it("deve carregar blocos XML com atributos id, type, role e status", function()
        local raw_xml = [[
<block id="b1" type="raw" role="user" status="archived">Conteúdo antigo</block>
<block id="b2" type="summary" role="assistant" status="active" covers="b1">Resumo do b1</block>
        ]]
        -- Nota: Este teste servirá de base para o refactoring do parser em session.lua
        -- Precisaremos ajustar o sync_from_lines para entender essa estrutura.
        session.sync_from_lines(vim.split(raw_xml, "\n"))
        
        local msgs = session.get_messages()
        assert.are.same(2, #msgs)
        assert.are.same("b1", msgs[1].metadata.id)
        assert.are.same("archived", msgs[1].metadata.status)
        assert.are.same("b2", msgs[2].metadata.id)
        assert.are.same("b1", msgs[2].metadata.covers)
    end)

    it("deve ignorar blocos marcados como archived durante a build do payload", function()
        session.add_message("user", "b1", { id = "b1", status = "archived" })
        session.add_message("assistant", "b2", { id = "b2", status = "active" })
        
        local payload = session.build_payload()
        
        -- A lógica de build_payload precisa ser refatorada para este filtro
        for _, m in ipairs(payload) do
            if m.metadata then
                assert.is_not.are.same("archived", m.metadata.status)
            end
        end
    end)

end)
