-- lua/multi_context/tests/swarm_etapa3_spec.lua
local popup = require('multi_context.ui.popup')
local api_client = require('multi_context.api_client')

describe("Swarm Etapa 3 - Manager e Fila:", function()
    local swarm
    local orig_popup_create, orig_api_execute

    before_each(function()
        -- 1. Mock correto do config (preservando as options padrão)
        local config = require('multi_context.config')
        config.options = config.options or { user_name = "User" }
        config.get_spawn_apis = function()
            return {
                { name = "worker_1", model = "model_A", allow_spawn = true },
                { name = "worker_2", model = "model_B", allow_spawn = true }
            }
        end
        
        -- 2. Isolando a UI (Impede que a janela seja criada no teste de fila)
        orig_popup_create = popup.create_swarm_buffer
        popup.create_swarm_buffer = function(agent, instr) return 999 end

        -- 3. Isolando a Rede (Impede requisições HTTP falsas)
        orig_api_execute = api_client.execute
        api_client.execute = function() end

        package.loaded['multi_context.swarm_manager'] = nil
        swarm = require('multi_context.swarm_manager')
        swarm.reset()
    end)

    after_each(function()
        -- Restaurando os originais
        popup.create_swarm_buffer = orig_popup_create
        api_client.execute = orig_api_execute
    end)

    it("Deve inicializar a fila lendo o JSON do Tech Lead", function()
        local json_payload = [[
        {
            "tasks":[
                { "agent": "coder", "context":["main.lua"], "instruction": "T1" },
                { "agent": "qa", "context":["main.lua"], "instruction": "T2" }
            ]
        }
        ]]
        
        local ok = swarm.init_swarm(json_payload)
        assert.is_true(ok)
        assert.are.same(2, #swarm.state.queue)
        assert.are.same(2, #swarm.state.workers)
        assert.are.same("coder", swarm.state.queue[1].agent)
    end)

    it("Deve transferir tarefas da fila para workers respeitando o limite (Dispatch)", function()
        swarm.state.queue = {
            { agent = "a1", instruction = "1" },
            { agent = "a2", instruction = "2" },
            { agent = "a3", instruction = "3" }
        }
        
        swarm.state.workers = {
            { api = { name = "w1" }, busy = false },
            { api = { name = "w2" }, busy = false }
        }

        -- Agora pode rodar o dispatch_next com segurança sem explodir a UI
        swarm.dispatch_next()

        assert.are.same(1, #swarm.state.queue)
        
        local active_count = 0
        for _, w in ipairs(swarm.state.workers) do
            if w.busy then active_count = active_count + 1 end
        end
        assert.are.same(2, active_count)
    end)
end)
