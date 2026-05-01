local injectors = require('multi_context.ecosystem.injectors')
local popup = require('multi_context.ui.chat_view')

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
    local injectors = require('multi_context.ecosystem.injectors')
    
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
