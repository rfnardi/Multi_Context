-- lua/multi_context/tests/react_loop_spec.lua
local StateManager = require('multi_context.core.state_manager')
local react_orchestrator = require('multi_context.core.react_orchestrator')

describe("ReAct Loop Module:", function()
    before_each(function()
        react_orchestrator.reset_turn()
    end)

    it("Deve resetar o estado corretamente", function()
        StateManager.get('react').is_autonomous = true
        StateManager.get('react').auto_loop_count = 5
        
        react_orchestrator.reset_turn()
        
        assert.is_false(StateManager.get('react').is_autonomous)
        assert.are.same(0, StateManager.get('react').auto_loop_count)
    end)

    it("Deve interromper a execução quando atingir 15 loops (Circuit Breaker)", function()
        -- Simulando 14 iterações aprovadas
        for i = 1, 14 do
            local abort = react_orchestrator.check_circuit_breaker()
            assert.is_false(abort)
        end
        
        -- A iteração 15 deve abortar
        local final_abort = react_orchestrator.check_circuit_breaker()
        assert.is_true(final_abort)
        assert.are.same(15, StateManager.get('react').auto_loop_count)
    end)
end)






