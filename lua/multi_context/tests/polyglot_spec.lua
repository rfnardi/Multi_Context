local skills = require('multi_context.skills_manager')

describe("Fase 29 - Passo 3: Polyglot Skills (Shell, Fish, Python)", function()
    local test_dir = "/tmp/mctx_polyglot_test"

    before_each(function()
        vim.fn.mkdir(test_dir, "p")
        skills.reset()
    end)

    after_each(function()
        vim.fn.delete(test_dir, "rf")
    end)

    it("Deve ler e envelopar um script bash executavel extraindo parametros do cabecalho", function()
        local script_path = test_dir .. "/meu_script_bash.sh"
        local bash_content = {
            "#!/bin/bash",
            "# DESC: Um script teste",
            "# PARAM: target | string | true | O alvo da acao",
            "echo \"Alvo e: $MCTX_TARGET\""
        }
        vim.fn.writefile(bash_content, script_path)
        vim.fn.system("chmod +x " .. script_path)

        skills.load_skills(test_dir)
        local loaded = skills.get_skills()

        assert.is_not_nil(loaded["meu_script_bash"], "A skill bash deve ser registrada com o nome do arquivo")
        assert.are.same("Um script teste", loaded["meu_script_bash"].description)
        assert.are.same("target", loaded["meu_script_bash"].parameters[1].name)
        assert.are.same("string", loaded["meu_script_bash"].parameters[1].type)
        assert.is_true(loaded["meu_script_bash"].parameters[1].required)

        local result = loaded["meu_script_bash"].execute({ target = "MUNDO" })
        assert.truthy(result:match("Alvo e: MUNDO"), "As variaveis de ambiente devem ser passadas para o script")
    end)
end)
