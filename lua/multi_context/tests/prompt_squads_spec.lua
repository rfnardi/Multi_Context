require("multi_context.tests.libuv_barrier")
local prompt_parser = require('multi_context.llm.prompt_parser')
local squads = require('multi_context.ecosystem.squads')

describe("Fase 23 - Passo 2: O Compilador de Meta-Agentes", function()
    local orig_load_squads

    before_each(function()
        orig_load_squads = squads.load_squads
        squads.load_squads = function()
            return {
                squad_ux = {
                    tasks = {
                        { agent = "tech_lead", instruction = "UX Design", queue = {"frontend"} }
                    }
                }
            }
        end
    end)

    after_each(function()
    if _G.AwaitForBackground then _G.AwaitForBackground() end
        squads.load_squads = orig_load_squads
    end)

    it("Deve detectar a invocacao de um squad e transpilar para spawn_swarm JSON", function()
        local raw = "Gere uma tela de login @squad_ux"
        local mock_agents = { tech_lead = {} }
        
        local parsed = prompt_parser.parse_user_input(raw, mock_agents)
        
        assert.are.same("tech_lead", parsed.agent_name)
        assert.truthy(parsed.text_to_send:match("<tool_call name=\"spawn_swarm\">"), "Deve engatilhar o spawn_swarm")
        assert.truthy(parsed.text_to_send:match('"agent"%s*:%s*"tech_lead"'), "JSON do squad deve estar injetado")
        assert.truthy(parsed.text_to_send:match("UX Design"), "A instrução original do squad deve estar no JSON")
        assert.truthy(parsed.text_to_send:match("Gere uma tela de login"), "A intent do usuario foi apensada a instrucao")
    end)
end)
