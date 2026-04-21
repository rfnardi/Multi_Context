-- lua/multi_context/tests/swarm_etapa4_spec.lua
local swarm = require('multi_context.swarm_manager')
local popup = require('multi_context.ui.popup')
local api_client = require('multi_context.api_client')

describe("Swarm Etapa 4 - Execucao Assincrona e Merge:", function()
    local original_create_buf, original_execute
    local executed_tasks = {}
    local final_summary = nil

    before_each(function()
        executed_tasks = {}
        final_summary = nil
        swarm.reset()

        -- Mock da UI (não queremos criar janelas de verdade no teste)
        original_create_buf = popup.create_swarm_buffer
        popup.create_swarm_buffer = function(agent, instr)
            return 999 -- ID fake de buffer
        end

        -- Mock da API (intercepta a chamada HTTP para simular sucesso imediato)
        original_execute = api_client.execute
        api_client.execute = function(messages, on_start, on_chunk, on_done, on_error, force_api_cfg)
            table.insert(executed_tasks, { api = force_api_cfg.name, msgs = messages })
        end

        -- Mock do Callback Final (interceptamos o relatório do Tech Lead)
        swarm.on_swarm_complete = function(summary)
            final_summary = summary
        end
        
        -- Injetando 1 worker ocioso diretamente no estado
        swarm.state.workers = {
            { api = { name = "worker_1", api_type = "openai" }, busy = false, current_task = nil }
        }
    end)

    after_each(function()
        popup.create_swarm_buffer = original_create_buf
        api_client.execute = original_execute
    end)

    it("Deve criar o buffer visual, montar o prompt e disparar a API correta", function()
        swarm.state.queue = { { agent = "coder", instruction = "Crie a funcao", context = {"mock.lua"} } }
        
        swarm.dispatch_next()
        
        assert.are.same(1, #executed_tasks, "O worker deveria ter acionado a API")
        assert.are.same("worker_1", executed_tasks[1].api, "O dispatcher deve usar a API atrelada ao worker")
        assert.is_true(swarm.state.workers[1].busy, "O worker deve ser marcado como ocupado")
    end)

    it("Deve processar a conclusao (on_done), liberar o worker e disparar o merge final", function()
        swarm.state.queue = { { agent = "qa", instruction = "Testes", context = {} } }
        
        -- Sobrescrevemos o mock para acionar imediatamente o callback on_done (como se a requisição terminasse na hora)
        api_client.execute = function(msgs, start, chunk, done, err, force_api_cfg)
            -- Simulando a IA terminando de digitar
            done(force_api_cfg, nil) 
        end

        swarm.dispatch_next()

        assert.is_false(swarm.state.workers[1].busy, "O worker deve voltar a ficar livre apos o on_done")
        assert.is_not_nil(final_summary, "Como a fila esvaziou, o relatorio final deve ter sido gerado")
        assert.truthy(final_summary:match("qa"), "O resumo deve conter a tarefa do agente qa")
    end)
end)
