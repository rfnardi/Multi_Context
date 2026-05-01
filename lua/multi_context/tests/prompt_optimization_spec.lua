local registry = require('multi_context.skills.registry')
local prompt_parser = require('multi_context.llm.prompt_parser')

describe("Fase 24 - Otimização de System Prompt (Token Saving):", function()
    local orig_get_doc

    before_each(function()
        orig_get_doc = registry.get_skill_doc
        registry.get_skill_doc = function(name)
            return "<mock>1</mock>"
        end
    end)

    after_each(function()
        registry.get_skill_doc = orig_get_doc
    end)

    it("O cabeçalho do manual de habilidades deve ser altamente sintetizado", function()
        local manual = registry.build_manual_for_skills({"mock_skill"})
        
        assert.truthy(manual:match("SYSTEM TOOLS"), "Deve conter SYSTEM TOOLS em Inglês")
        assert.truthy(manual:match("XML"), "Deve reforçar XML")
        assert.truthy(manual:match("get_diagnostics"), "Deve avisar sobre o auto-LSP")
        
        assert.is_true(#manual < 700, "O manual base deve ser hiper-sintético para economizar tokens. Tamanho atual: " .. #manual)
    end)
    
    it("O system prompt base deve ser limpo e não possuir gorduras", function()
        local prompt = prompt_parser.build_system_prompt("Base", "Mem", "coder", {coder = {system_prompt="sys", skills={}}})
        
        assert.truthy(prompt:match("CURRENT PROJECT STATE"))
        assert.truthy(prompt:match("AGENT INSTRUCTIONS:"))
        
        assert.falsy(prompt:match("sempre que finalizar uma tarefa para não perder a memória"), "Retire explicações longas sobre o CONTEXT.md")
    end)
end)
