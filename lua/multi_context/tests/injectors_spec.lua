local injectors = require('multi_context.injectors')
local popup = require('multi_context.ui.popup')

describe("Fase 28 - Passo 1 e 2: Context Injectors e Seletor", function()
    local orig_get_native
    local orig_feedkeys
    local buf
    local win

    before_each(function()
        buf, win = popup.create_popup("Meu prompt inicial:")
        
        -- Mock para impedir que a tecla "a" simulada trave o terminal de testes
        orig_feedkeys = vim.api.nvim_feedkeys
        vim.api.nvim_feedkeys = function() end
        
        orig_get_native = injectors.get_native_injectors
        injectors.get_native_injectors = function()
            return {
                { name = "teste_injetor", description = "Mock", execute = function() return " TEXTO_INJETADO" end }
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

    it("Deve carregar a lista combinada de injetores", function()
        local list = injectors.get_all_injectors()
        assert.is_not_nil(list["teste_injetor"], "A lista deve conter o injetor nativo mockado")
    end)

    it("Deve realizar a injeção do texto diretamente na posicao do cursor", function()
        -- Simulando o cursor (0-indexed line, e col após os dois pontos)
        vim.api.nvim_win_set_cursor(win, {1, 19})
        
        injectors.api_list = {"teste_injetor"}
        injectors.current_selection = 1
        injectors.parent_win = win
        
        injectors._select()
        
        local final_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        local joined = table.concat(final_lines, "\n")
        
        -- O texto deve ter sido "colado"
        assert.truthy(joined:match("Meu prompt inicial: TEXTO_INJETADO"), "O texto do injetor deve estar no buffer do chat")
    end)
end)

describe("Fase 28 - Passo 3: Injetores Customizados e Exemplos", function()
    local injectors = require('multi_context.injectors')
    
    it("Deve carregar um injetor customizado valido a partir do diretorio local", function()
        -- Mock stdpath para um diretório temporário
        local orig_stdpath = vim.fn.stdpath
        vim.fn.stdpath = function(kind)
            if kind == "config" then return "/tmp/mctx_mock" else return orig_stdpath(kind) end
        end
        
        vim.fn.mkdir("/tmp/mctx_mock/mctx_injectors", "p")
        
        local valid_inj = "return { name = 'meu_injetor', description = 'teste', execute = function() return 'OK' end }"
        vim.fn.writefile({valid_inj}, "/tmp/mctx_mock/mctx_injectors/meu_injetor.lua")
        
        local custom = injectors.get_custom_injectors()
        
        -- Cleanup imediato
        vim.fn.stdpath = orig_stdpath
        vim.fn.delete("/tmp/mctx_mock", "rf")
        
        assert.are.same(1, #custom)
        assert.are.same("meu_injetor", custom[1].name)
        assert.are.same("OK", custom[1].execute())
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
