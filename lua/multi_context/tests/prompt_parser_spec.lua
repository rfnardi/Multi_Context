-- Stub do registry para o teste isolado
package.loaded['multi_context.skills.registry'] = {
    build_manual_for_skills = function(skills) return "=== SKILLS ===" end
}

local prompt_parser = require('multi_context.prompt_parser')
local config = require('multi_context.config')

describe("Fase 25 - Passo 2: O System Agent @archivist", function()
    local mock_agents = { 
        coder = { system_prompt = "Você programa." } 
    }

    before_each(function()
        config.options.watchdog = { mode = "auto", strategy = "semantic", fixed_target = 1500, percent = 0.3 }
    end)

    it("Deve carregar o System Prompt de Compressao com limite Semântico", function()
        config.options.watchdog.strategy = "semantic"
        
        -- O archivist não existe no mock_agents propositalmente
        local final_prompt = prompt_parser.build_system_prompt("Base", "Mem", "archivist", mock_agents, 5000)

        assert.truthy(final_prompt:match("Você é o @archivist do sistema"), "O Megaprompt deve ser ativado nativamente")
        assert.truthy(final_prompt:match("COMPRESSÃO SEMÂNTICA"), "O limite semântico deve estar presente no prompt")
    end)

    it("Deve injetar o valor exato no prompt caso a estrategia seja Percentual", function()
        config.options.watchdog.strategy = "percent"
        
        -- Simulando um chat com 5000 tokens e alvo de 30%
        local final_prompt = prompt_parser.build_system_prompt("Base", "Mem", "archivist", mock_agents, 5000)
        
        -- 30% de 5000 = 1500 tokens
        assert.truthy(final_prompt:match("MANDATÓRIO: A compressão é baseada num teto percentual"), "Estrategia percentual")
        assert.truthy(final_prompt:match("1500 tokens"), "O cálculo percentual exato (1500) deve estar hardcoded no prompt")
    end)

    it("Deve injetar o limite restrito caso a estrategia seja Fixo", function()
        config.options.watchdog.strategy = "fixed"
        config.options.watchdog.fixed_target = 999
        
        local final_prompt = prompt_parser.build_system_prompt("Base", "Mem", "archivist", mock_agents, 5000)
        
        assert.truthy(final_prompt:match("MANDATÓRIO: A compressão é agressiva"), "Estrategia fixa")
        assert.truthy(final_prompt:match("999 tokens"), "O valor alvo fixo deve ser imposto")
    end)
end)






