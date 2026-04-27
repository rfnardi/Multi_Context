-- lua/multi_context/tests/swarm_etapa5_spec.lua
local swarm = require('multi_context.swarm_manager')
local popup = require('multi_context.ui.popup')
local api_client = require('multi_context.api_client')
local config = require('multi_context.config')
local agents = require('multi_context.agents')

describe("Swarm Etapa 5 - Resiliência e UI Dinâmica:", function()
    local orig_execute

    before_each(function()
        orig_execute = api_client.execute
        swarm.reset()

        -- Garante ambiente limpo de janelas
        if popup.popup_win and vim.api.nvim_win_is_valid(popup.popup_win) then
            vim.api.nvim_win_close(popup.popup_win, true)
        end
        popup.swarm_buffers = {}
        popup.current_swarm_index = 1
        
        -- Mock de Config para 1 Worker
        config.get_spawn_apis = function()
            return {{ name = "mock_api", model = "mock_model", allow_spawn = true, abstraction_level = "high" }}
        end
    end)

    after_each(function()
        api_client.execute = orig_execute
    end)

    it("Deve realizar retry de uma tarefa se a API retornar string vazia", function()
        -- Mock da API para simular falha silenciosa (retorna vazio)
        api_client.execute = function(messages, on_start, on_chunk, on_done, on_error, force_api)
            -- Chama o on_done imediatamente sem chamar on_chunk (simulando texto vazio)
            on_done(force_api, nil)
        end

        swarm.init_swarm('{"tasks":[{"agent":"qa","instruction":"teste"}]}')
        swarm.dispatch_next()

        -- O worker terminou, identificou vazio, e DEVE ter devolvido a tarefa pra fila
        assert.are.same(1, #swarm.state.queue, "A tarefa deve voltar para a fila")
        assert.are.same(1, swarm.state.queue[1].retries, "O contador de retries deve ser 1")

        -- Dispara de novo, a API falha de novo (segunda tentativa vazia)
        swarm.dispatch_next()
        assert.are.same(1, #swarm.state.queue)
        assert.are.same(2, swarm.state.queue[1].retries, "O contador de retries deve ser 2")

        -- Dispara de novo (excedeu limite de retries)
        swarm.dispatch_next()
        assert.are.same(0, #swarm.state.queue, "Fila deve zerar após esgotar retries")
        assert.are.same(1, #swarm.state.reports)
        assert.truthy(swarm.state.reports[1].result:match("FALHA: A API falhou repetidas vezes"))
    end)

    it("Deve realizar retry de uma tarefa se a API retornar erro HTTP (Rate Limit)", function()
        -- Mock da API para simular Erro Bruto
        api_client.execute = function(messages, on_start, on_chunk, on_done, on_error, force_api)
            on_error("Rate Limit Exceeded")
        end

        swarm.init_swarm('{"tasks":[{"agent":"coder","instruction":"teste"}]}')
        swarm.dispatch_next()

        assert.are.same(1, #swarm.state.queue, "A tarefa deve voltar para a fila apos erro")
        assert.are.same(1, swarm.state.queue[1].retries)

        -- Simula segunda falha
        swarm.dispatch_next()
        assert.are.same(1, #swarm.state.queue)
        assert.are.same(2, swarm.state.queue[1].retries)

        -- Esgota limite
        swarm.dispatch_next()
        assert.are.same(0, #swarm.state.queue)
        assert.truthy(swarm.state.reports[1].result:match("ERRO FATAL APÓS TENTATIVAS"))
    end)

    it("Deve atualizar o titulo do Carrossel e calcular tokens dinamicamente", function()
        -- Cria a janela flutuante real (no ambiente headless)
        local main_buf, win = popup.create_popup("Buffer Principal")
        
        -- Cria o sub buffer do worker
        local sub_buf = popup.create_swarm_buffer("qa", "Instrucao teste", "api_teste")
        
        -- Força a atualização do título estando no Main (índice 1)
        popup.current_swarm_index = 1
        popup.update_title()
        
        local conf_main = vim.api.nvim_win_get_config(win)
        local title_main = type(conf_main.title) == "table" and conf_main.title[1][1] or conf_main.title or ""
        -- Verifica se o asterisco está no Main
        assert.truthy(title_main:match("%*%[1:Main%]"), "Deve destacar a aba Main")
        assert.truthy(title_main:match("%[2:qa%]"), "Não deve destacar a aba QA")
        assert.truthy(title_main:match("tokens"), "Deve conter a palavra tokens")

        -- Alterna para o buffer do Worker (índice 2)
        popup.cycle_swarm_buffer(1)
        
        local conf_sub = vim.api.nvim_win_get_config(win)
        local title_sub = type(conf_sub.title) == "table" and conf_sub.title[1][1] or conf_sub.title or ""
        assert.truthy(title_sub:match("%[1:Main%]"), "Não deve destacar a aba Main")
        assert.truthy(title_sub:match("%*%[2:qa%]"), "Deve destacar a aba QA")
    end)
    
    it("Deve confirmar a presença do agente @qa no acervo", function()
        local loaded = agents.load_agents()
        assert.is_not_nil(loaded["qa"], "O agente QA deve existir")
        assert.truthy(loaded["qa"].system_prompt:match("Qualidade"), "A descrição deve corresponder a um QA")
    end)

end)






