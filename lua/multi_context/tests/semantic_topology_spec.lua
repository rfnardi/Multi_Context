local assert = require("luassert")

describe("Fase 40: Ontologia Hierarquica e Roteamento Semantico", function()
    
    it("Contrato 1.2 e 5.1: Skill Loader e Auto-Wrapper", function()
        local ontology = require('multi_context.ecosystem.skills_ontology')
        local resolved = ontology.resolve_agent_skills({"code_refactoring", "unknown_custom_tool"})
        
        assert.is_true(#resolved.semantic_skills >= 2)
        local found_refactoring = false
        local found_custom = false
        for _, s in ipairs(resolved.semantic_skills) do
            if s.name == "code_refactoring" then found_refactoring = true end
            if s.name == "unknown_custom_tool" then found_custom = true end
        end
        assert.is_true(found_refactoring)
        assert.is_true(found_custom)
        assert.is_true(resolved.tools_set["read_file"])
        assert.is_true(resolved.tools_set["unknown_custom_tool"])
    end)
    
    it("Contrato 1.4: Squad Loader calcula abstraction_level dinamicamente", function()
        local squads = require('multi_context.ecosystem.squads')
        package.loaded['multi_context.agents'] = {
            load_agents = function()
                return {
                    agent_low = { abstraction_level = "low" },
                    agent_high = { abstraction_level = "high" }
                }
            end
        }
        
        local mock_file = os.tmpname()
        vim.fn.writefile({[[ { "test_squad": { "tasks":[ { "agent": "agent_low", "chain": ["agent_high"] } ] } } ]]}, mock_file)
        
        squads.squads_file = mock_file
        local loaded = squads.load_squads()
        assert.are.same("high", loaded["test_squad"].abstraction_level)
        os.remove(mock_file)
    end)
    
    it("Contrato 2.3: Deduplicacao de Tools", function()
        local registry = require('multi_context.skills.registry')
        registry.get_skill_doc = function(name) return "<doc>"..name.."</doc>" end
        
        local manual = registry.build_manual_for_skills({"code_refactoring", "code_investigation"})
        local _, count = manual:gsub("<doc>read_file</doc>", "")
        assert.are.same(1, count, "read_file should be injected exactly once")
    end)
    
    it("Contrato 3.2: Desempacotamento de Squads no Swarm Manager", function()
        local swarm = require('multi_context.core.swarm_manager')
        package.loaded['multi_context.ecosystem.squads'] = {
            load_squads = function()
                return {
                    my_squad = {
                        collective_purpose = "Squad Goal",
                        tasks = {
                            { agent = "coder", instruction = "Do code" },
                            { agent = "qa", instruction = "Do test" }
                        }
                    }
                }
            end
        }
        
        local payload = { tasks = { { agent = "my_squad", instruction = "Main User Task" } } }
        swarm.init_swarm(vim.fn.json_encode(payload))
        
        assert.are.same(2, #swarm.state.queue)
        assert.are.same("coder", swarm.state.queue[1].agent)
        assert.is_true(swarm.state.queue[1].instruction:match("Squad Goal") ~= nil)
        assert.is_true(swarm.state.queue[1].instruction:match("Main User Task") ~= nil)
        assert.are.same("qa", swarm.state.queue[2].agent)
    end)
end)
