local agents = require('multi_context.agents')
local injectors = require('multi_context.ecosystem.injectors')
local popup = require('multi_context.ui.chat_view')

describe("Fase 37 - TEMA 3: Interatividade Visual e Menus (Fuzzy Finder):", function()
    describe("Módulo agents.lua", function()
        before_each(function()
            agents.api_list = {"coder", "qa", "devops", "tech_lead"}
            agents.filtered_list = {"coder", "qa", "devops", "tech_lead"}
            agents.current_selection = 1
        end)

        it("Deve travar a navegacao no topo ao pressionar <Up> no primeiro item", function()
            agents._move(-1)
            assert.are.same(1, agents.current_selection, "A seleção não deve ficar menor que 1")
        end)

        it("Deve travar a navegacao no fim ao pressionar <Down> no ultimo item", function()
            agents.current_selection = 4
            agents._move(1)
            assert.are.same(4, agents.current_selection, "A seleção não deve ultrapassar o total de itens")
        end)

        it("Deve fechar silenciosamente e nao quebrar ao tentar selecionar com filtro vazio", function()
            agents._update_filter("batman_invisivel")
            assert.are.same(0, #agents.filtered_list)
            
            -- Se não quebrar, o teste passa. O behavior esperado é não lançar exceção.
            assert.has_no.errors(function()
                agents._select()
            end)
        end)
        
        it("Deve atualizar corretamente a lista de filtrados e resetar o cursor para 1", function()
            agents.current_selection = 3
            agents._update_filter("qa")
            assert.are.same(1, #agents.filtered_list)
            assert.are.same("qa", agents.filtered_list[1])
            assert.are.same(1, agents.current_selection, "O cursor deve retornar para o índice 1 ao filtrar")
        end)

        it("Deve renderizar a lista corretamente com o cursor apontando para a selecao", function()
            agents.selector_buf = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_buf_set_lines(agents.selector_buf, 0, -1, false, { "> ", "---" })
            agents.current_selection = 2
            agents._render_list()
            local lines = vim.api.nvim_buf_get_lines(agents.selector_buf, 2, -1, false)
            assert.are.same("❯ qa", lines[2])
            pcall(vim.api.nvim_buf_delete, agents.selector_buf, {force=true})
        end)
    end)

    describe("Módulo injectors.lua", function()
        before_each(function()
            injectors.api_list = {"buffers", "current_buffer", "git_diff", "tree"}
            injectors.filtered_list = {"buffers", "current_buffer", "git_diff", "tree"}
            injectors.current_selection = 1
        end)

        it("Deve travar a navegacao no topo (Injectors)", function()
            injectors._move(-1)
            assert.are.same(1, injectors.current_selection)
        end)

        it("Deve travar a navegacao no fim (Injectors)", function()
            injectors.current_selection = 4
            injectors._move(1)
            assert.are.same(4, injectors.current_selection)
        end)

        it("Deve fechar sem quebrar ao selecionar com filtro vazio (Injectors)", function()
            injectors._update_filter("injetor_fantasma")
            assert.are.same(0, #injectors.filtered_list)
            
            assert.has_no.errors(function()
                injectors._select()
            end)
        end)

        it("Deve renderizar a lista de injetores corretamente", function()
            injectors.selector_buf = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_buf_set_lines(injectors.selector_buf, 0, -1, false, { "> ", "---" })
            injectors.current_selection = 1
            injectors._render_list()
            local lines = vim.api.nvim_buf_get_lines(injectors.selector_buf, 2, -1, false)
            assert.are.same("❯ buffers", lines[1])
            pcall(vim.api.nvim_buf_delete, injectors.selector_buf, {force=true})
        end)
    end)
end)
