local State = require('multi_context.core.state_manager')

describe("Core Arquitetura 2.0: State Manager", function()
    before_each(function()
        State.reset()
    end)

    it("Deve definir e recuperar um valor do estado global", function()
        State.set("active_agent", "coder")
        assert.are.same("coder", State.get("active_agent"))
    end)

    it("Deve suportar merge parcial de tabelas no estado (patch)", function()
        State.set("flags", { queue = false, moa = false })
        State.patch("flags", { moa = true })
        
        local flags = State.get("flags")
        assert.is_true(flags.moa, "Deve ter atualizado o moa para true")
        assert.is_false(flags.queue, "Nao deve ter apagado o queue original")
    end)
end)
