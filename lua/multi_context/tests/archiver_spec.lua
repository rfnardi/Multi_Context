local session = require('multi_context.core.session')
local StateManager = require('multi_context.core.state_manager')
local archiver = require('multi_context.core.archiver')

describe("Fase 42.2 e 42.3: Motor de Compressão e Recuperação Relacional", function()

    before_each(function()
        StateManager.reset()
        session.clear()
    end)

    it("Fase 42.2: deve arquivar blocos e criar um resumo apontando para eles", function()
        session.add_message("user", "Problema X", { id = "b1", status = "active" })
        session.add_message("assistant", "Solução Y", { id = "b2", status = "active" })
        
        archiver.compress({"b1", "b2"}, "Resumo da solução X-Y", "b3")
        
        local msgs = session.get_messages()
        
        assert.are.same("archived", msgs[1].metadata.status)
        assert.are.same("archived", msgs[2].metadata.status)
        
        local resumo = msgs[3]
        assert.are.same("b3", resumo.metadata.id)
        assert.are.same("summary", resumo.metadata.type)
        assert.are.same("b1,b2", resumo.metadata.covers)
        assert.are.same("active", resumo.metadata.status)
    end)
    
    it("Fase 42.2: deve garantir que blocos archived não apareçam no build_payload", function()
        session.add_message("user", "Privado", { id = "b1", status = "archived" })
        session.add_message("assistant", "Público", { id = "b2", status = "active" })
        
        local payload = session.build_payload()
        assert.are.same(1, #payload)
        assert.are.same("Público", payload[1].content)
    end)

    it("Fase 42.3: deep_dive deve recuperar os conteúdos originais de um target_id que cobre blocos", function()
        session.add_message("user", "Erro na linha 42", { id = "block_a", status = "archived", type="raw", role="user" })
        session.add_message("assistant", "Código corrigido com mutex", { id = "block_b", status = "archived", type="raw", role="assistant" })
        session.add_message("assistant", "Bug de concorrência resolvido", { id = "summary_1", status = "active", type="summary", covers="block_a,block_b" })

        local retrieved_xml = archiver.deep_dive("summary_1")
        
        assert.truthy(retrieved_xml:match("Erro na linha 42"), "Deveria conter o conteúdo do bloco A")
        assert.truthy(retrieved_xml:match("Código corrigido com mutex"), "Deveria conter o conteúdo do bloco B")
        assert.truthy(retrieved_xml:match("<block id=\"block_a\""), "Deveria encapsular a resposta em tags XML legíveis para a IA")
    end)

    it("Fase 42.3: deep_dive deve avisar a IA graciosamente se o target_id não possuir blocos atrelados", function()
        session.add_message("assistant", "Texto genérico", { id = "b99", status = "active" })
        local retrieved = archiver.deep_dive("b99")
        
        assert.truthy(retrieved:match("nenhum bloco"), "Deveria avisar que não há blocos associados")
    end)

end)
