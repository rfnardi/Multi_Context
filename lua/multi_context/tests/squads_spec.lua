local squads = require('multi_context.squads')

describe("Fase 23 - Passo 1: Loader de Squads", function()
    local test_dir = "/tmp/mctx_squads_test"

    before_each(function()
        vim.fn.mkdir(test_dir, "p")
        squads.squads_file = test_dir .. "/mctx_squads.json"
    end)

    after_each(function()
        vim.fn.delete(test_dir, "rf")
    end)

    it("Deve criar o arquivo padrao caso nao exista e carregar corretamente", function()
        vim.fn.delete(squads.squads_file)
        
        local loaded = squads.load_squads()
        
        assert.is_not_nil(loaded["squad_dev"], "O squad padrao deve ser criado")
        assert.are.same("tech_lead", loaded["squad_dev"].tasks[1].agent)
        assert.are.same("coder", loaded["squad_dev"].tasks[1].chain[1])
    end)

    it("Deve extrair a lista de nomes dos squads", function()
        local mock_data = { squad_ux = {}, squad_backend = {} }
        vim.fn.writefile({vim.fn.json_encode(mock_data)}, squads.squads_file)
        
        local names = squads.get_squad_names()
        assert.are.same(2, #names)
        
        -- Garante que leu corretamente os arquivos mocados e ordenou
        assert.are.same("squad_backend", names[1])
        assert.are.same("squad_ux", names[2])
    end)
end)






