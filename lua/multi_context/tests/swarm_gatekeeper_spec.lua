local assert = require("luassert")
local tool_runner = require("multi_context.ecosystem.tool_runner")
local StateManager = require("multi_context.core.state_manager")

describe("Swarm Gatekeeper Fix", function()
    before_each(function()
        StateManager.reset()
    end)

    it("tool_runner.execute DEVE aceitar active_agent_override para Sub-Agentes do Swarm", function()
        -- Mocks locais: tech_lead não tem ferramentas. devops tem git.
        local agents = {
            tech_lead = { skills = {} },
            devops = { skills = {"git_automation"} }
        }
        
        local mock_ontology = {
            resolve_agent_skills = function(skills)
                if skills and skills[1] == "git_automation" then
                    return { tools_set = { get_git_env = true } }
                end
                return { tools_set = {} }
            end
        }
        
        -- Injeção no package.loaded
        package.loaded["multi_context.agents"] = { load_agents = function() return agents end }
        package.loaded["multi_context.ecosystem.ontology"] = mock_ontology
        
        -- Simulando que o estado global React ainda é o Tech Lead
        StateManager.patch("react", { active_agent = "tech_lead" })
        
        local tool_data = { name = "get_git_env", inner = "" }
        local ref = { value = true }
        
        -- Teste A (Bug Antigo): Sem override, DEVE negar (Tech Lead não pode rodar Git)
        local out_denied = tool_runner.execute(tool_data, true, ref, 1)
        assert.truthy(out_denied:match("Operação negada"))
        
        -- Teste B (Nova Funcionalidade): Com override do Swarm, DEVE autorizar o Devops
        local out_allowed = tool_runner.execute(tool_data, true, ref, 1, "devops")
        assert.falsy(out_allowed:match("Operação negada"))
        
        -- Cleanup
        package.loaded["multi_context.agents"] = nil
        package.loaded["multi_context.ecosystem.ontology"] = nil
    end)
end)
