local lsp_manager = require('multi_context.ecosystem.lsp_manager')
local state = require('multi_context.core.state_manager')

describe("Fase 39 - JIT LSP Manager (Behavior Driven):", function()
    before_each(function()
        state.reset()
    end)

    it("Contrato 1: Deve mapear corretamente extensões para LSPs", function()
        assert.are.equal("rust_analyzer", lsp_manager._get_lsp_name("src/main.rs"))
        assert.are.equal("ts_ls", lsp_manager._get_lsp_name("app/index.ts"))
        assert.are.equal("pyright", lsp_manager._get_lsp_name("script.py"))
        assert.are.equal("gopls", lsp_manager._get_lsp_name("main.go"))
        assert.is_nil(lsp_manager._get_lsp_name("arquivo_sem_extensao"))
    end)

    it("Contrato 2: Deve respeitar o Isolamento de Estado (rejected_lsps)", function()
        -- Simulamos que o usuário já negou o rust_analyzer
        state.patch('react', { rejected_lsps = { rust_analyzer = true } })
        
        -- Simulamos a interface do usuário para explodir caso seja chamada
        local confirm_called = false
        local original_confirm = vim.fn.confirm
        vim.fn.confirm = function() confirm_called = true return 2 end
        
        local result = lsp_manager.ensure_lsp_for_file("test.rs")
        
        -- Restaura função
        vim.fn.confirm = original_confirm
        
        -- Não deve tentar instalar e não deve ter chamado o confirm
        assert.is_false(result)
        assert.is_false(confirm_called, "Ocorreu fadiga de alerta! O sistema perguntou sobre um LSP já rejeitado.")
    end)
end)
