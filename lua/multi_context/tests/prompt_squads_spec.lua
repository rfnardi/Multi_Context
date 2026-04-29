local prompt_parser = require('multi_context.llm.prompt_parser')

-- Substitui dependência em disco por um mock em memória
package.loaded['multi_context.ecosystem.squads'] = {
    load_squads = function()
        return {
            squad_ux = {
                tasks = {
                    { agent = "tech_lead", instruction = "UX Design", chain = {"frontend"} }
                }
            }
        }
    end
}

describe("Fase 23 - Passo 2: O Compilador de Meta-Agentes", function()
    it("Deve detectar a invocacao de um squad e transpilar para spawn_swarm JSON", function()
        -- Simulando menção a squad_ux no chat
        local raw = "Gere uma tela de login @squad_ux"
        local mock_agents = { tech_lead = {} } -- agentes não importam aqui
        
        -- Garante que o parser seja re-requisitado para pegar o mock de squads
        package.loaded['multi_context.llm.prompt_parser'] = nil
        local parser = require('multi_context.llm.prompt_parser')
        
        local parsed = parser.parse_user_input(raw, mock_agents)
        
        -- Ao invés de mandar um texto cru, deve ter envelopado como tech_lead rodando spawn_swarm
        assert.are.same("tech_lead", parsed.agent_name)
        assert.truthy(parsed.text_to_send:match("<tool_call name=\"spawn_swarm\">"), "Deve engatilhar o spawn_swarm")
        
        -- CORREÇÃO AQUI: Tolerância a espaçamentos na conversão JSON (ex: {"agent": "tech_lead"})
        assert.truthy(parsed.text_to_send:match('"agent"%s*:%s*"tech_lead"'), "JSON do squad deve estar injetado")
        
        assert.truthy(parsed.text_to_send:match("UX Design"), "A instrução original do squad deve estar no JSON")
        assert.truthy(parsed.text_to_send:match("Gere uma tela de login"), "A intent do usuario foi apensada a instrucao")
    end)
end)






