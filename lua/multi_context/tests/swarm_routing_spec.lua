local swarm = require('multi_context.core.swarm_manager')
local agents = require('multi_context.agents')
local api_client = require('multi_context.llm.api_client')

describe("Fase 20 - Passo 2 (Fallback Direcional):", function()
    local orig_load_agents
    local orig_execute

    before_each(function()
        swarm.reset()
        
        -- Mockamos os agentes com seus níveis cognitivos
        orig_load_agents = agents.load_agents
        agents.load_agents = function()
            return {
                agente_low = { system_prompt = "low", abstraction_level = "low" },
                agente_med = { system_prompt = "med", abstraction_level = "medium" },
                agente_high = { system_prompt = "high", abstraction_level = "high" }
            }
        end
        
        -- Interceptamos o disparo real da rede para o teste ser síncrono
        orig_execute = api_client.execute
        api_client.execute = function(msgs, on_start, on_chunk, on_done, on_error, force_api_cfg)
            -- Finge que iniciou o job
        end
    end)

    after_each(function()
        agents.load_agents = orig_load_agents
        api_client.execute = orig_execute
    end)

    it("Deve bloquear a tarefa se não houver API com capacidade suficiente (Starvation)", function()
        swarm.state.queue = { { agent = "agente_med", instruction = "teste" } }
        swarm.state.workers = {
            { api = { name = "api_fraca", abstraction_level = "low" }, busy = false }
        }
        
        swarm.dispatch_next()
        
        -- A tarefa DEVE continuar na fila (1), pois a API ociosa é muito fraca para ela
        assert.are.same(1, #swarm.state.queue, "A tarefa nao deveria ter sido alocada")
        assert.is_false(swarm.state.workers[1].busy, "O worker de baixo nivel nao deve ter sido usado")
    end)

    it("Deve permitir que uma API poderosa resolva uma tarefa simples (Fallback Direcional)", function()
        swarm.state.queue = { { agent = "agente_low", instruction = "teste" } }
        swarm.state.workers = {
            { api = { name = "api_forte", abstraction_level = "high" }, busy = false }
        }
        
        swarm.dispatch_next()
        
        -- A API é overqualified, então ela engole a tarefa
        assert.are.same(0, #swarm.state.queue, "A tarefa deve ser consumida pela API overqualified")
        assert.is_true(swarm.state.workers[1].busy, "O worker forte deve assumir o trabalho")
    end)
end)






