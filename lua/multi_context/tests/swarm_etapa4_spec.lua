require("multi_context.tests.libuv_barrier")
local swarm = require('multi_context.core.swarm_manager')
local popup = require('multi_context.ui.chat_view')
local api_client = require('multi_context.llm.api_client')

describe("Swarm Etapa 4 - Execucao Assincrona e Merge:", function()
    local original_create_buf, original_execute
    local executed_tasks = {}
    local final_summary = nil

    before_each(function()
        executed_tasks = {}
        final_summary = nil
        swarm.reset()

        original_create_buf = popup.create_swarm_buffer
        popup.create_swarm_buffer = function(agent, instr) return 999 end

        original_execute = api_client.execute
        api_client.execute = function(messages, on_start, on_chunk, on_done, on_error, force_api_cfg)
            table.insert(executed_tasks, { api = force_api_cfg.name, msgs = messages })
        end

        swarm.on_swarm_complete = function(summary)
            final_summary = summary
        end
        
        swarm.state.workers = {
            { api = { name = "worker_1", abstraction_level = "high", api_type = "openai" }, busy = false, current_task = nil }
        }
    end)

    after_each(function()
        if _G.AwaitForBackground then _G.AwaitForBackground() end
        popup.create_swarm_buffer = original_create_buf
        api_client.execute = original_execute
    end)

    it("Deve criar o buffer visual, montar o prompt e disparar a API correta", function()
        swarm.state.queue = { { agent = "coder", instruction = "Crie a funcao", context = {"mock.lua"} } }
        swarm.dispatch_next()
        assert.are.same(1, #executed_tasks)
        assert.are.same("worker_1", executed_tasks[1].api)
        assert.is_true(swarm.state.workers[1].busy)
    end)

    it("Deve processar a conclusao (on_done), liberar o worker e disparar o merge final", function()
        swarm.state.queue = { { agent = "qa", instruction = "Testes", context = {} } }
        
        api_client.execute = function(msgs, start, chunk, done, err, force_api_cfg)
            done(force_api_cfg, nil) 
        end

        swarm.dispatch_next()
        vim.wait(100, function() return final_summary ~= nil end, 5)

        assert.is_false(swarm.state.workers[1].busy)
        assert.is_not_nil(final_summary)
        assert.truthy(final_summary:match("qa"))
    end)
end)
