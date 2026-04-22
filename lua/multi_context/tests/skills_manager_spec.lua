local skills = require('multi_context.skills_manager')
local prompt_parser = require('multi_context.prompt_parser')
local tool_runner = require('multi_context.tool_runner')

describe("Fase 19 - Sistema de Skills (Extensibilidade):", function()
    local test_dir = "/tmp/mctx_mock_skills"

    before_each(function()
        -- Usa a API nativa do Neovim para garantir que a pasta seja criada com sucesso
        vim.fn.mkdir(test_dir, "p")
        skills.reset()
    end)

    after_each(function()
        vim.fn.delete(test_dir, "rf")
    end)

    it("Deve carregar e validar uma skill customizada corretamente", function()
        local valid_skill = "return { name = 'minha_skill', description = 'Uma skill de teste', execute = function(args) return 'Executado: ' .. (args.texto or '') end }"
        local f = io.open(test_dir .. "/minha_skill.lua", "w")
        f:write(valid_skill)
        f:close()

        skills.load_skills(test_dir)
        local loaded = skills.get_skills()

        assert.is_not_nil(loaded["minha_skill"])
        assert.are.same("minha_skill", loaded["minha_skill"].name)
        assert.are.same("Executado: teste", loaded["minha_skill"].execute({texto = "teste"}))
    end)

    it("Deve ignorar arquivos que não retornam uma tabela de skill valida", function()
        local invalid_skill = "return { name = 'skill_quebrada', description = 'Falta o execute' }"
        local f = io.open(test_dir .. "/invalid.lua", "w")
        f:write(invalid_skill)
        f:close()

        local not_lua = "isso nao e codigo lua valido"
        local f2 = io.open(test_dir .. "/erro_sintaxe.lua", "w")
        f2:write(not_lua)
        f2:close()

        skills.load_skills(test_dir)
        local loaded = skills.get_skills()

        assert.is_nil(loaded["skill_quebrada"])
        local count = 0
        for _ in pairs(loaded) do count = count + 1 end
        assert.are.same(0, count)
    end)

    it("Deve injetar a definicao da skill customizada no prompt do sistema", function()
        skills.reset()
        skills.skills["calc_especial"] = {
            name = "calc_especial",
            description = "Calculo complexo customizado",
            parameters = { { name = "valor", type = "number", desc = "O valor base" } }
        }

        local full_prompt = prompt_parser.build_system_prompt("System Base", nil, nil, {})
        
        assert.truthy(full_prompt:match("calc_especial"))
        assert.truthy(full_prompt:match("Calculo complexo customizado"))
        assert.truthy(full_prompt:match('name="valor"'))
    end)

    it("Deve rotear e executar uma skill customizada atraves do tool_runner", function()
        skills.reset()
        skills.skills["echo_skill"] = {
            name = "echo_skill",
            description = "Skill que repete uma mensagem",
            parameters = { { name = "message", type = "string" } },
            execute = function(args) return "ECHOED: " .. (args.message or "vazio") end
        }

        local parsed_tag = { name = "echo_skill", inner = "\n  <message>Hello World</message>\n" }
        local approve_ref = { value = true }
        local output = tool_runner.execute(parsed_tag, true, approve_ref, nil)

        assert.truthy(output:match("ECHOED: Hello World"))
    end)

    it("Deve limpar skills apagadas e recarregar a lista (Hot-Reload)", function()
        skills.reset()
        skills.skills["skill_apagada"] = { name = "skill_apagada", description = "Old", execute = function() end }

        local valid_skill = "return { name = 'skill_nova', description = 'Nova', execute = function() return 'ok' end }"
        local f = io.open(test_dir .. "/skill_nova.lua", "w")
        f:write(valid_skill)
        f:close()

        skills.load_skills(test_dir)
        local loaded = skills.get_skills()

        assert.is_nil(loaded["skill_apagada"], "A skill antiga deve ser removida da memoria no reload")
        assert.is_not_nil(loaded["skill_nova"], "A nova skill deve ser carregada imediatamente")
    end)

end)
