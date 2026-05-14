require("multi_context.tests.libuv_barrier")
local swarm = require('multi_context.core.swarm_manager')
local api_client = require('multi_context.llm.api_client')
local popup = require('multi_context.ui.chat_view')
local agents = require('multi_context.agents')

describe("Fase 21 - Pipelines e Coreografia:", function()
    local orig_execute, orig_create_buf, orig_load_agents

    before_each(function()
        swarm.reset()
        
        orig_execute = api_client.execute
        orig_create_buf = popup.create_swarm_buffer
        popup.create_swarm_buffer = function() return 999 end
        
        orig_load_agents = agents.load_agents
        agents.load_agents = function()
            return {
                coder = { system_prompt = "Você é o Coder.", abstraction_level = "high" },
                qa = { system_prompt = "Você é o QA.", abstraction_level = "high" }
            }
        end
    end)

    after_each(function()
        if _G.AwaitForBackground then _G.AwaitForBackground() end
        api_client.execute = orig_execute
        popup.create_swarm_buffer = orig_create_buf
        agents.load_agents = orig_load_agents
    end)

    it("Passo 1: Deve processar 'chain' e 'allow_switch' no init_swarm", function()
        local ok = swarm.init_swarm('{"tasks":[{"chain":["coder", "qa"], "instruction": "F", "allow_switch": ["dba"]}]}')
        assert.is_true(ok)
        assert.are.same("coder", swarm.state.queue[1].agent)
        assert.are.same("qa", swarm.state.queue[1].chain[2])
    end)

    it("Passo 2: Deve reencarnar a tarefa na fila caso haja agentes restantes na chain", function()
        api_client.execute = function(msgs, start, chunk, done, err, cfg)
            chunk("<final_report>Terminei o código</final_report>")
            done(cfg, nil)
        end
        swarm.init_swarm('{"tasks":[{"chain":["coder", "qa"], "instruction": "F"}]}')
        swarm.state.workers = { { api = { name = "mock_api", abstraction_level = "high" }, busy = false } }
        
        swarm.dispatch_next()
        -- 💡 Espera o tick assíncrono do Neovim rodar a rotina do Swarm
        vim.wait(100, function() return #swarm.state.queue > 0 end, 5)

        assert.are.same(1, #swarm.state.queue)
        assert.are.same(0, #swarm.state.reports)
        assert.are.same("qa", swarm.state.queue[1].agent)
    end)

    it("Passo 3: Deve permitir troca de agente na mesma aba via switch_agent", function()
        local call_count = 0
        local prompts_usados = {}
        
        api_client.execute = function(msgs, start, chunk, done, err, cfg)
            call_count = call_count + 1
            table.insert(prompts_usados, msgs[1].content)
            
            if call_count == 1 then
                chunk('<tool_call name="switch_agent">\n  <target_agent>qa</target_agent>\n</tool_call>')
                done(cfg, nil)
            else
                chunk('<final_report>QA testou e aprovou</final_report>')
                done(cfg, nil)
            end
        end

        local json_payload = [[
        {
            "tasks":[
                { 
                    "agent": "coder",
                    "instruction": "Faça a feature",
                    "allow_switch": ["qa"]
                }
            ]
        }
        ]]
        
        swarm.init_swarm(json_payload)
        swarm.state.workers = { { api = { name = "mock_api", abstraction_level = "high" }, busy = false } }
        
        swarm.dispatch_next()
        vim.wait(200, function() return call_count >= 2 end, 5)

        assert.are.same(2, call_count)
        assert.truthy(prompts_usados[1]:match("Você é o Coder"))
        assert.truthy(prompts_usados[2]:match("Você é o QA"))
        
        assert.are.same(0, #swarm.state.queue)
        assert.are.same(1, #swarm.state.reports)
        assert.truthy(swarm.state.reports[1].result:match("QA testou e aprovou"))
    end)
end)
