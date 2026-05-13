local prompt_parser = require('multi_context.llm.prompt_parser')
local config = require('multi_context.config')
local registry = require('multi_context.tools.registry')

describe("Fase 25 - Passo 2: O System Agent @archivist", function()
    local mock_agents = { coder = { system_prompt = "Você programa." } }
    local orig_build_manual

    before_each(function()
        config.options.watchdog = { mode = "auto", strategy = "semantic", fixed_target = 1500, percent = 0.3 }
        orig_build_manual = registry.build_manual_for_skills
        registry.build_manual_for_skills = function(skills) return "=== SKILLS ===" end
    end)

    after_each(function()
    if _G.AwaitForBackground then _G.AwaitForBackground() end
        registry.build_manual_for_skills = orig_build_manual
    end)

    it("Deve carregar o System Prompt de Compressao com limite Semântico", function()
        config.options.watchdog.strategy = "semantic"
        local final_prompt = prompt_parser.build_system_prompt("Base", "Mem", "archivist", mock_agents, 5000)

        assert.truthy(final_prompt:match("You are the system's @archivist"), "O Megaprompt deve ser ativado nativamente em Inglês")
        assert.truthy(final_prompt:match("SEMANTIC COMPRESSION"), "O limite semântico deve estar presente no prompt")
    end)

    it("Deve injetar o valor exato no prompt caso a estrategia seja Percentual", function()
        config.options.watchdog.strategy = "percent"
        local final_prompt = prompt_parser.build_system_prompt("Base", "Mem", "archivist", mock_agents, 5000)
        
        assert.truthy(final_prompt:match("MANDATORY: Compression is based on a percentage ceiling"), "Estrategia percentual em Inglês")
        assert.truthy(final_prompt:match("1500 tokens"), "O cálculo percentual exato (1500) deve estar hardcoded no prompt")
    end)

    it("Deve injetar o limite restrito caso a estrategia seja Fixo", function()
        config.options.watchdog.strategy = "fixed"
        config.options.watchdog.fixed_target = 999
        local final_prompt = prompt_parser.build_system_prompt("Base", "Mem", "archivist", mock_agents, 5000)
        
        assert.truthy(final_prompt:match("MANDATORY: Aggressive compression"), "Estrategia fixa em Inglês")
        assert.truthy(final_prompt:match("999 tokens"), "O valor alvo fixo deve ser imposto")
    end)
end)
