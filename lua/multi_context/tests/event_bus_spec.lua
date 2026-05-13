local EventBus = require('multi_context.core.event_bus')

describe("Core Arquitetura 2.0: EventBus", function()
    -- Em vez de EventBus.clear() que destrói o listener de interface do plugin inteiro (vazando falhas para outros testes),
    -- vamos apenas usar nomes de eventos isolados virtuais.
    
    it("Deve registrar e disparar um evento (on / emit)", function()
        local received = false
        local payload_recebido = nil
        
        EventBus.on("TEST_EVENT_1", function(payload)
            received = true
            payload_recebido = payload
        end)
        
        EventBus.emit("TEST_EVENT_1", { foo = "bar" })
        
        assert.is_true(received, "O listener deveria ter sido acionado")
        assert.are.same("bar", payload_recebido.foo, "O payload deve ser entregue intacto")
    end)

    it("Deve permitir múltiplos listeners para o mesmo evento (Fan-out)", function()
        local count = 0
        EventBus.on("MULTI_EVENT_1", function() count = count + 1 end)
        EventBus.on("MULTI_EVENT_1", function() count = count + 1 end)
        
        EventBus.emit("MULTI_EVENT_1")
        
        assert.are.same(2, count, "Ambos os listeners deveriam ser acionados")
    end)

    it("Deve desregistrar um listener especifico (off)", function()
        local count = 0
        local cb1 = function() count = count + 1 end
        local cb2 = function() count = count + 1 end
        
        EventBus.on("OFF_EVENT_1", cb1)
        EventBus.on("OFF_EVENT_1", cb2)
        
        EventBus.off("OFF_EVENT_1", cb1)
        
        EventBus.emit("OFF_EVENT_1")
        
        assert.are.same(1, count, "Apenas o segundo listener deveria ser acionado")
    end)

    it("Deve suportar execucao unica (once)", function()
        local count = 0
        EventBus.once("ONCE_EVENT_1", function() count = count + 1 end)
        
        EventBus.emit("ONCE_EVENT_1")
        EventBus.emit("ONCE_EVENT_1") -- Este não deve surtir efeito
        
        assert.are.same(1, count, "O listener 'once' deve ser removido após a primeira execucao")
    end)

    it("Nao deve quebrar ao emitir um evento sem listeners", function()
        assert.has_no.errors(function()
            EventBus.emit("GHOST_EVENT_1")
        end)
    end)
end)
