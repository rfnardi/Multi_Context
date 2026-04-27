local lsp_utils = require('multi_context.lsp_utils')

describe("Fase 30 - Passo 2: A Ponte Silenciosa do LSP", function()
    local orig_request_sync

    before_each(function()
        orig_request_sync = vim.lsp.buf_request_sync
    end)

    after_each(function()
        vim.lsp.buf_request_sync = orig_request_sync
    end)

    it("Deve encontrar a coluna correta de um simbolo numa linha", function()
        local col = lsp_utils._find_symbol_col("local total = calcular_imposto()", "calcular_imposto")
        -- 'c' é o 15º caractere (índice 15 em Lua, mas LSP usa 0-based offsets, então 14)
        assert.truthy(col > 0, "A coluna deve ser maior que 0")
        assert.are.same(14, col)
    end)

    it("Deve retornar erro se não encontrar o simbolo na linha", function()
        local col = lsp_utils._find_symbol_col("local a = 1", "nao_existe")
        assert.is_nil(col)
    end)
    
    it("Deve realizar a requisicao de definicao e extrair o codigo (Go to Definition)", function()
        -- Mock do LSP retornando uma posicao falsa
        vim.lsp.buf_request_sync = function(bufnr, method, params, timeout)
            if method == "textDocument/definition" then
                return {
                    { 
                        result = {
                            {
                                uri = "file:///mock/path/arquivo.lua",
                                range = { start = { line = 10, character = 0 } }
                            }
                        }
                    }
                }
            end
            return nil
        end
        
        -- Mock de leitura de arquivo nativo para o teste não depender do disco
        local orig_readfile = vim.fn.readfile
        local orig_filereadable = vim.fn.filereadable
        vim.fn.filereadable = function(path)
            if path == "/mock/path/arquivo.lua" then return 1 end
            return orig_filereadable(path)
        end
        vim.fn.readfile = function(path)
            if path == "/mock/path/arquivo.lua" then
                local lines = {}
                for i=1, 20 do table.insert(lines, "Linha " .. i) end
                return lines
            end
            return orig_readfile(path)
        end
        
        local res = lsp_utils.get_definition("/mock/path/outro.lua", 5, "meu_simbolo")
        
        vim.fn.readfile = orig_readfile
        vim.fn.filereadable = orig_filereadable
        
        assert.truthy(res:match("arquivo.lua"), "Deve indicar o arquivo da definicao")
        assert.truthy(res:match("Linha 11"), "Deve extrair a linha alvo (0-based convertida para 1-based)")
    end)
end)
