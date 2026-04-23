local memory_tracker = require('multi_context.memory_tracker')

describe("Fase 22 - Passo 1: O Guardião Preditivo (EMA Tracker):", function()
    before_each(function()
        memory_tracker.reset()
    end)

    it("Deve inicializar a EMA perfeitamente com o primeiro valor", function()
        memory_tracker.add_turn(100)
        assert.are.same(100, memory_tracker.get_ema())
    end)

    it("Deve calcular a EMA absorvendo picos sem enviesar totalmente", function()
        memory_tracker.add_turn(100)  -- O normal
        
        -- Simulando o turno 2 onde a IA usou uma tool e puxou um arquivo de 5000 tokens
        memory_tracker.add_turn(5000) 
        
        local ema_after_peak = memory_tracker.get_ema()
        -- A EMA deve subir, mas o pico deve ser amortecido (não pode pular reto pra 5000)
        assert.is_true(ema_after_peak > 1000 and ema_after_peak < 2000, "EMA deveria ter amortecido o pico")

        -- Simulando o turno 3 que voltou ao normal
        memory_tracker.add_turn(150)  
        local ema_after_drop = memory_tracker.get_ema()
        
        assert.is_true(ema_after_drop < ema_after_peak, "EMA deve começar a descer após um turno com valor menor")
    end)
    
    it("Deve prever corretamente os tokens totais para o próximo disparo", function()
        memory_tracker.add_turn(100)
        
        -- prediction = Contexto Atual (500) + Prompt a enviar (50) + Predição da IA (EMA atual, que é 100)
        local prediction = memory_tracker.predict_next_total(500, 50)
        
        assert.are.same(650, prediction, "A predição total deve ser a soma exata dos 3 fatores")
    end)
end)
