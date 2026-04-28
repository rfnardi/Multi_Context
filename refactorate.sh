#!/bin/bash

# 1. Corrigindo o teste do Context Builders e adicionando teste para nome do arquivo
cat << 'EOF' > lua/multi_context/tests/context_builders_spec.lua
local ctx = require('multi_context.context_builders')

describe("Context Builders Module:", function()
    it("Deve extrair o contexto do buffer atual corretamente", function()
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"linhaA", "linhaB"})
        vim.api.nvim_set_current_buf(buf)
        
        local res = ctx.get_current_buffer()
        -- CORREÇÃO: O novo header é "=== BUFFER: Nome ==="
        assert.truthy(res:match("=== BUFFER:"))
        assert.truthy(res:match("linhaA"))
        assert.truthy(res:match("linhaB"))
    end)

    it("Deve incluir o nome do arquivo no cabecalho do get_current_buffer", function()
        local buf = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_buf_set_name(buf, "meu_script_falso.lua")
        vim.api.nvim_set_current_buf(buf)
        
        local res = ctx.get_current_buffer()
        assert.truthy(res:match("meu_script_falso%.lua"), "O nome do arquivo deve ser extraído e aparecer no header")
    end)

    it("Deve extrair apenas as linhas da selecao visual (com range)", function()
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"L1", "L2", "L3", "L4"})
        vim.api.nvim_set_current_buf(buf)
        
        local res = ctx.get_visual_selection(2, 3)
        assert.truthy(res:match("SELEÇÃO %(linhas 2%-3%)"))
        assert.truthy(res:match("L2"))
        assert.truthy(res:match("L3"))
        assert.falsy(res:match("L1"))
        assert.falsy(res:match("L4"))
    end)
    
    it("Deve corrigir a ordem se o range for passado invertido (baixo pra cima)", function()
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"A", "B", "C"})
        vim.api.nvim_set_current_buf(buf)
        
        local res = ctx.get_visual_selection(3, 1)
        assert.truthy(res:match("SELEÇÃO %(linhas 1%-3%)"))
    end)
end)
EOF

# 2. Corrigindo o teste do QA (Inglês) e adicionando o teste para a persona @architect
cat << 'EOF' > lua/multi_context/tests/swarm_etapa5_spec.lua
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
EOF

# 3. Adicionando teste para o injetor current_buffer
cat << 'EOF' > lua/multi_context/tests/injectors_spec.lua
local injectors = require('multi_context.injectors')
local popup = require('multi_context.ui.popup')

describe("Fase 29 - Passo 1 e 2: Injectors Fuzzy e Smart Placement", function()
    local orig_get_native
    local orig_feedkeys
    local buf
    local win

    before_each(function()
        buf, win = popup.create_popup("Meu prompt inicial: ")
        orig_feedkeys = vim.api.nvim_feedkeys
        vim.api.nvim_feedkeys = function() end
        
        orig_get_native = injectors.get_native_injectors
        injectors.get_native_injectors = function()
            return {
                { name = "teste_injetor", execute = function() return "TEXTO_INJETADO" end },
                { name = "outro_comando", execute = function() return "DIFERENTE" end }
            }
        end
    end)

    after_each(function()
        injectors.get_native_injectors = orig_get_native
        vim.api.nvim_feedkeys = orig_feedkeys
        if popup.popup_win and vim.api.nvim_win_is_valid(popup.popup_win) then
            vim.api.nvim_win_close(popup.popup_win, true)
        end
    end)

    it("Deve filtrar as opcoes usando o fuzzy finder via _update_filter", function()
        injectors.api_list = {"teste_injetor", "outro_comando"}
        injectors.filtered_list = {"teste_injetor", "outro_comando"}
        
        injectors._update_filter("out")
        assert.are.same(1, #injectors.filtered_list)
        assert.are.same("outro_comando", injectors.filtered_list[1])
        
        injectors._update_filter("tst")
        assert.are.same(1, #injectors.filtered_list)
        assert.are.same("teste_injetor", injectors.filtered_list[1])
    end)

    it("Deve injetar o texto NA LINHA DE BAIXO do cursor preservando o prompt", function()
        vim.api.nvim_win_set_cursor(win, {1, 19})
        
        injectors.api_list = {"teste_injetor"}
        injectors.filtered_list = {"teste_injetor"}
        injectors.current_selection = 1
        injectors.parent_win = win
        
        injectors._select()
        
        local final_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        assert.are.same("Meu prompt inicial: ", final_lines[1])
        assert.are.same("TEXTO_INJETADO", final_lines[2])
    end)
end)

describe("Testes Restaurados da Fase 28 - Integridade de Extensoes", function()
    local injectors = require('multi_context.injectors')
    
    it("Deve carregar a lista combinada de injetores nativos e custom", function()
        local list = injectors.get_all_injectors()
        assert.is_not_nil(list["buffers"], "A lista deve conter injetores nativos (ex: buffers)")
        assert.is_not_nil(list["git_diff"], "A lista deve conter injetores nativos (ex: git_diff)")
    end)

    it("Deve disponibilizar o novo injetor 'current_buffer' nativamente", function()
        local native = injectors.get_native_injectors()
        local found = false
        for _, inj in ipairs(native) do
            if inj.name == "current_buffer" then found = true end
        end
        assert.is_true(found, "O injetor current_buffer deve estar registrado")
    end)

    it("Deve carregar um injetor customizado valido a partir do diretorio local", function()
        local orig_stdpath = vim.fn.stdpath
        vim.fn.stdpath = function(kind)
            if kind == "config" then return "/tmp/mctx_mock_restored" else return orig_stdpath(kind) end
        end
        vim.fn.mkdir("/tmp/mctx_mock_restored/mctx_injectors", "p")
        
        local valid_inj = "return { name = 'meu_injetor', description = 'teste', execute = function() return 'OK' end }"
        vim.fn.writefile({valid_inj}, "/tmp/mctx_mock_restored/mctx_injectors/meu_injetor.lua")
        
        local custom = injectors.get_custom_injectors()
        
        vim.fn.stdpath = orig_stdpath
        vim.fn.delete("/tmp/mctx_mock_restored", "rf")
        
        local found = false
        for _, inj in ipairs(custom) do
            if inj.name == "meu_injetor" then found = true end
        end
        assert.is_true(found, "O injetor customizado deve ser encontrado na varredura")
    end)

    it("Deve disponibilizar os exemplos base de injetores na pasta examples", function()
        local examples_dir = vim.fn.getcwd() .. "/examples/injectors"
        local files = vim.fn.globpath(examples_dir, "*.lua", false, true)
        
        local names = {}
        for _, file in ipairs(files) do
            local chunk = loadfile(file)
            if chunk then
                local ok, res = pcall(chunk)
                if ok and type(res) == "table" then
                    names[res.name] = true
                end
            end
        end
        
        assert.is_true(names["project_dump"], "Falta o injetor project_dump")
        assert.is_true(names["lsp_errors"], "Falta o injetor lsp_errors")
        assert.is_true(names["git_log"], "Falta o injetor git_log")
    end)
end)
EOF

chmod +x run_tests.sh
echo "Testes corrigidos e expandidos para bater exatamente 120 validações!"
