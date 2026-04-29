local memory_tracker = require('multi_context.utils.memory_tracker')

describe("Fase 25 - Passo 1: O Guardião Preditivo 2.0 (Fundações):", function()
    before_each(function()
        memory_tracker.reset()
    end)

    it("Deve inicializar a EMA perfeitamente com o primeiro valor", function()
        memory_tracker.add_turn(100)
        assert.are.same(100, memory_tracker.get_ema())
    end)

    it("Deve calcular a EMA absorvendo picos sem enviesar totalmente", function()
        memory_tracker.add_turn(100)  -- O normal
        memory_tracker.add_turn(5000) -- O pico
        
        local ema_after_peak = memory_tracker.get_ema()
        assert.is_true(ema_after_peak > 1000 and ema_after_peak < 2000, "EMA deveria ter amortecido o pico")

        memory_tracker.add_turn(150)  -- Voltou ao normal
        local ema_after_drop = memory_tracker.get_ema()
        
        assert.is_true(ema_after_drop < ema_after_peak, "EMA deve começar a descer")
    end)
    
    it("Deve prever os tokens ignorando a dupla contagem do prompt", function()
        memory_tracker.add_turn(100)
        
        -- Agora passamos APENAS o tamanho do buffer atual. 
        -- O prompt recém-digitado já está colado nele pela UI, então não devemos somar duas vezes.
        local prediction = memory_tracker.predict_next_total(500)
        
        -- 500 (Buffer com prompt) + 100 (EMA)
        assert.are.same(600, prediction, "A predição deve ser apenas Buffer Atual + EMA")
    end)

    it("Deve garantir Imunidade de Primeiro Turno (Cold Start)", function()
        -- Histórico Zerado
        assert.is_true(memory_tracker.is_immune(), "Deve ser imune no Big Bang (0 turnos)")
        
        -- Após o primeiro turno
        memory_tracker.add_turn(1500)
        assert.is_true(memory_tracker.is_immune(), "Ainda deve ser imune antes de disparar o segundo turno")
        
        -- Após o segundo turno
        memory_tracker.add_turn(200)
        assert.is_false(memory_tracker.is_immune(), "A partir do segundo turno concluído, o Guardião passa a vigiar")
    end)
end)






