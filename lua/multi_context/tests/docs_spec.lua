describe("Fase 32 - Distribuição e Documentação", function()
    local root = vim.fn.getcwd()

    it("O arquivo de ajuda nativa (doc/multicontext.txt) deve existir e estar formatado", function()
        local doc_path = root .. "/doc/multicontext.txt"
        assert.are.same(1, vim.fn.filereadable(doc_path), "O diretório doc/ e o arquivo multicontext.txt devem existir")
        
        local content = table.concat(vim.fn.readfile(doc_path), "\n")
        assert.truthy(content:match("%*multicontext%.txt%*"), "Deve conter a tag de cabeçalho do Vimdoc")
        assert.truthy(content:match("%*multicontext%-commands%*"), "Deve ter uma seção de comandos navegável")
    end)

    it("O README.md deve estar atualizado com as features mais recentes", function()
        local readme_path = root .. "/README.md"
        assert.are.same(1, vim.fn.filereadable(readme_path), "O README.md deve existir na raiz")
        
        local content = table.concat(vim.fn.readfile(readme_path), "\n")
        assert.truthy(content:match("LSP"), "O README deve citar a integração com o LSP")
        assert.truthy(content:match("Ripgrep") or content:match("rg"), "O README deve citar a busca com Ripgrep")
        assert.truthy(content:match("@devops") or content:match("Git"), "O README deve citar o agente DevOps e Automação Git")
    end)
end)
