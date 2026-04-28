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

        if popup.popup_win and vim.api.nvim_win_is_valid(popup.popup_win) then
            vim.api.nvim_win_close(popup.popup_win, true)
        end
        popup.swarm_buffers = {}
        popup.current_swarm_index = 1
        
        config.get_spawn_apis = function()
            return {{ name = "mock_api", model = "mock_model", allow_spawn = true, abstraction_level = "high" }}
        end
    end)

    after_each(function()
        api_client.execute = orig_execute
    end)

    it("Deve realizar retry de uma tarefa se a API retornar string vazia", function()
        api_client.execute = function(messages, on_start, on_chunk, on_done, on_error, force_api)
            on_done(force_api, nil)
        end

        swarm.init_swarm('{"tasks":[{"agent":"qa","instruction":"teste"}]}')
        swarm.dispatch_next()

        assert.are.same(1, #swarm.state.queue)
        assert.are.same(1, swarm.state.queue[1].retries)

        swarm.dispatch_next()
        assert.are.same(1, #swarm.state.queue)
        assert.are.same(2, swarm.state.queue[1].retries)

        swarm.dispatch_next()
        assert.are.same(0, #swarm.state.queue)
        assert.are.same(1, #swarm.state.reports)
        assert.truthy(swarm.state.reports[1].result:match("FALHA") or swarm.state.reports[1].result:match("FAILURE"))
    end)

    it("Deve realizar retry de uma tarefa se a API retornar erro HTTP (Rate Limit)", function()
        api_client.execute = function(messages, on_start, on_chunk, on_done, on_error, force_api)
            on_error("Rate Limit Exceeded")
        end

        swarm.init_swarm('{"tasks":[{"agent":"coder","instruction":"teste"}]}')
        swarm.dispatch_next()

        assert.are.same(1, #swarm.state.queue)
        assert.are.same(1, swarm.state.queue[1].retries)

        swarm.dispatch_next()
        assert.are.same(1, #swarm.state.queue)
        assert.are.same(2, swarm.state.queue[1].retries)

        swarm.dispatch_next()
        assert.are.same(0, #swarm.state.queue)
        assert.truthy(swarm.state.reports[1].result:match("FATAL"))
    end)

    it("Deve atualizar o titulo do Carrossel e calcular tokens dinamicamente", function()
        local main_buf, win = popup.create_popup("Buffer Principal")
        local sub_buf = popup.create_swarm_buffer("qa", "Instrucao teste", "api_teste")
        
        popup.current_swarm_index = 1
        popup.update_title()
        
        local conf_main = vim.api.nvim_win_get_config(win)
        local title_main = type(conf_main.title) == "table" and conf_main.title[1][1] or conf_main.title or ""
        
        assert.truthy(title_main:match("%*%[1:Main%]"))
        assert.truthy(title_main:match("%[2:qa%]"))
        assert.truthy(title_main:match("tokens"))

        popup.cycle_swarm_buffer(1)
        
        local conf_sub = vim.api.nvim_win_get_config(win)
        local title_sub = type(conf_sub.title) == "table" and conf_sub.title[1][1] or conf_sub.title or ""
        assert.truthy(title_sub:match("%[1:Main%]"))
        assert.truthy(title_sub:match("%*%[2:qa%]"))
    end)
    
    it("Deve confirmar a presença do agente @qa no acervo e sua descrição traduzida", function()
        local loaded = agents.load_agents()
        assert.is_not_nil(loaded["qa"], "O agente QA deve existir")
        -- CORREÇÃO: Busca por "Quality Assurance" (Inglês) em vez de "Qualidade" (Português)
        assert.truthy(loaded["qa"].system_prompt:match("Quality Assurance"), "A descrição deve corresponder a um QA em Inglês")
    end)

    it("Deve confirmar a presença do novo agente @architect no acervo", function()
        local loaded = agents.load_agents()
        assert.is_not_nil(loaded["architect"], "O agente architect deve existir")
        assert.truthy(loaded["architect"].system_prompt:match("SOLID"), "Deve focar em princípios de arquitetura (SOLID)")
        assert.truthy(loaded["architect"].system_prompt:match("TDD"), "Deve focar em Test-Driven Development")
    end)
end)
