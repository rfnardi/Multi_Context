local agents = require('multi_context.agents')
local config = require('multi_context.config')

describe("Fase 20 - Passo 1 (Abstraction Levels):", function()
    local orig_json_decode

    before_each(function()
        orig_json_decode = vim.fn.json_decode
    end)

    after_each(function()
        vim.fn.json_decode = orig_json_decode
    end)

    it("Deve definir abstraction_level='high' para agentes sem o campo configurado", function()
        vim.fn.json_decode = function(...)
            return {
                agente_antigo = { system_prompt = "Sou antigo" },
                agente_novo = { system_prompt = "Sou novo", abstraction_level = "low" }
            }
        end
        
        local loaded = agents.load_agents()
        assert.is_not_nil(loaded["agente_antigo"], "O agente_antigo deve carregar")
        assert.are.same("high", loaded["agente_antigo"].abstraction_level, "Default do agente deve ser high")
        assert.are.same("low", loaded["agente_novo"].abstraction_level, "Deve respeitar o valor definido no agente")
    end)
    
    it("Deve definir abstraction_level='medium' para APIs sem o campo configurado", function()
        vim.fn.json_decode = function(...)
            -- CORREÇÃO: O Mock agora simula a estrutura real do json com a chave 'apis'
            return {
                apis = {
                    { name = "api_antiga", model = "gpt-3.5" },
                    { name = "api_nova", model = "gpt-4", abstraction_level = "high" }
                }
            }
        end
        
        local cfg = config.load_api_config()
        assert.is_not_nil(cfg, "A configuracao de APIs deve carregar")
        
        local api_antiga_level = nil
        local api_nova_level = nil
        
        for _, api in ipairs(cfg.apis) do
            if api.name == "api_antiga" then api_antiga_level = api.abstraction_level end
            if api.name == "api_nova" then api_nova_level = api.abstraction_level end
        end
        
        assert.are.same("medium", api_antiga_level, "Default da API deve ser medium")
        assert.are.same("high", api_nova_level, "Deve respeitar o valor definido na API")
    end)
end)
