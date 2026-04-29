local swarm = require('multi_context.core.swarm_manager')
local api_client = require('multi_context.llm.api_client')
local popup = require('multi_context.ui.popup')
local agents = require('multi_context.agents')

describe("Fase 21 - Pipelines e Coreografia:", function()
    local orig_execute
    local orig_create_buf
    local orig_load_agents

    before_each(function()
        swarm.reset()
        
        -- Isolamos a rede
        orig_execute = api_client.execute
        -- Isolamos a UI
        orig_create_buf = popup.create_swarm_buffer
        popup.create_swarm_buffer = function() return 999 end
        
        -- Mockamos as personas para garantir o System Prompt
        orig_load_agents = agents.load_agents
        agents.load_agents = function()
            return {
                coder = { system_prompt = "Você é o Coder.", abstraction_level = "high" },
                qa = { system_prompt = "Você é o QA.", abstraction_level = "high" }
            }
        end
    end)

    after_each(function()
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
            table.insert(prompts_usados, msgs[1].content) -- Grava o System Prompt injetado neste turno!
            
            if call_count == 1 then
                -- O Coder invoca a troca pro QA
                chunk('<tool_call name="switch_agent">\n  <target_agent>qa</target_agent>\n</tool_call>')
                done(cfg, nil)
            else
                -- O QA responde com o relatório final (o loop termina aqui)
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
        
        -- Aguarda as chamadas recursivas terminarem (2 turnos)
        vim.wait(200, function() return call_count >= 2 end, 5)

        assert.are.same(2, call_count, "Deveriam ocorrer exatamente 2 turnos")
        
        -- Verifica se o cérebro da operação foi modificado no meio do caminho
        assert.truthy(prompts_usados[1]:match("Você é o Coder"), "O turno 1 deveria usar o prompt do Coder")
        assert.truthy(prompts_usados[2]:match("Você é o QA"), "O turno 2 deveria ter o prompt modificado dinamicamente para o QA")
        
        -- O report final pertence a essa sessão consolidada
        assert.are.same(0, #swarm.state.queue)
        assert.are.same(1, #swarm.state.reports)
        assert.truthy(swarm.state.reports[1].result:match("QA testou e aprovou"))
    end)
end)






