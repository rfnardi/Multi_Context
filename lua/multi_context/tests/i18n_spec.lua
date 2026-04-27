local i18n = require('multi_context.i18n')
local config = require('multi_context.config')

describe("Fase 33 - Motor de Internacionalização (i18n)", function()
    local orig_lang
    local orig_dict

    before_each(function()
        orig_lang = config.options.language
        orig_dict = vim.deepcopy(i18n.dict)
        
        -- O motor base agora é pt-BR! O inglês que faz fallback para ele.
        i18n.dict = {["pt-BR"] = { hello = "Olá", base_only = "Apenas Base" },
            en = { hello = "Hello" }
        }
    end)

    after_each(function()
        config.options.language = orig_lang
        i18n.dict = orig_dict
    end)

    it("Deve traduzir a string para o idioma configurado (pt-BR)", function()
        config.options.language = "pt-BR"
        assert.are.same("Olá", i18n.t("hello"))
    end)

    it("Deve realizar fallback para o pt-BR caso a string não exista no en", function()
        config.options.language = "en"
        assert.are.same("Apenas Base", i18n.t("base_only"))
    end)

    it("Deve retornar a propria chave caso a string não exista em nenhum dicionário", function()
        config.options.language = "es"
        assert.are.same("chave_fantasma", i18n.t("chave_fantasma"))
    end)
end)
