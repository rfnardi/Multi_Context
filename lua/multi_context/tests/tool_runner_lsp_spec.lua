require("multi_context.tests.libuv_barrier")
local tool_runner = require('multi_context.ecosystem.tool_runner')
local lsp_utils = require('multi_context.ecosystem.lsp_bridge')
local agents = require('multi_context.agents')

describe("Fase 30 - Passo 3: Roteamento de Ferramentas LSP no Runner", function()
    local orig_get_def
    local orig_load_agents

    before_each(function()
        orig_load_agents = agents.load_agents
        agents.load_agents = function() return {} end
        
        orig_get_def = lsp_utils.get_definition
        lsp_utils.get_definition = function(path, line, symbol)
            return "Mock Definition: " .. path .. " L" .. line .. " [" .. symbol .. "]"
        end
    end)

    after_each(function()
    if _G.AwaitForBackground then _G.AwaitForBackground() end
        lsp_utils.get_definition = orig_get_def
        agents.load_agents = orig_load_agents
    end)

    it("Deve rotear a ferramenta lsp_definition para o lsp_utils", function()
        local tool_data = {
            name = "lsp_definition",
            path = "test.lua",
            start_line = "5", 
            inner = "simbolo_teste",
            raw_tag = "<tool_call name='lsp_definition' path='test.lua' line='5'>"
        }
        local approve_ref = { value = true }
        local output = tool_runner.execute(tool_data, true, approve_ref, nil)
        
        assert.truthy(output:match("<block"), "O output do runner deve ser um bloco")
        assert.truthy(output:match("Mock Definition: test%.lua L5 %[simbolo_teste%]"), "O output do runner deve conter o retorno da ferramenta LSP")
    end)
end)
