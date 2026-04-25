local skills = require('multi_context.skills_manager')

describe("Fase 27 - Ecossistema da Comunidade (V1.0):", function()
    -- Usa o diretório root do projeto (assumindo que o Neovim abriu na raiz)
    local examples_dir = vim.fn.getcwd() .. "/examples/skills"

    it("Deve disponibilizar e compilar os exemplos base de skills perfeitamente", function()
        skills.reset()
        
        -- Tenta carregar a pasta que será distribuída no GitHub
        skills.load_skills(examples_dir)
        local loaded = skills.get_skills()

        -- Validando estruturalmente se as skills de demonstração foram escritas sem erros de sintaxe Lua
        assert.is_not_nil(loaded["read_jira"], "O catálogo deve conter a skill de exemplo: read_jira")
        assert.is_not_nil(loaded["run_pytest"], "O catálogo deve conter a skill de exemplo: run_pytest")
        assert.is_not_nil(loaded["sql_inspector"], "O catálogo deve conter a skill de exemplo: sql_inspector")
    end)
end)
