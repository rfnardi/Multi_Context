local registry = require('multi_context.skills.registry')
local prompt_parser = require('multi_context.prompt_parser')

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
        
        -- Garante que as palavras chaves existam para os testes antigos continuarem passando
        assert.truthy(manual:match("FERRAMENTAS DO SISTEMA"), "Deve conter FERRAMENTAS DO SISTEMA")
        assert.truthy(manual:match("XML"), "Deve reforçar XML")
        assert.truthy(manual:match("get_diagnostics"), "Deve avisar sobre o auto-LSP")
        
        -- A grande verificação de economia: o texto original tinha ~660 caracteres. 
        -- Vamos forçar o tamanho do cabeçalho + mock a ser menor que 280 chars
        assert.is_true(#manual < 280, "O manual base deve ser hiper-sintético para economizar tokens. Tamanho atual: " .. #manual)
    end)
    
    it("O system prompt base deve ser limpo e não possuir gorduras", function()
        local prompt = prompt_parser.build_system_prompt("Base", "Mem", "coder", {coder = {system_prompt="sys", skills={}}})
        
        -- Verifica as palavras chave dos testes antigos
        assert.truthy(prompt:match("ESTADO ATUAL DO PROJETO"))
        assert.truthy(prompt:match("INSTRUÇÕES DO AGENTE:"))
        
        -- Proíbe prolixidade (estas palavras estavam no antigo prompt de parser e gastavam tokens)
        assert.falsy(prompt:match("sempre que finalizar uma tarefa para não perder a memória"), "Retire explicações longas sobre o CONTEXT.md")
    end)
end)






