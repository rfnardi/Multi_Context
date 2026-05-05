local chat_view = require('multi_context.ui.chat_view')

describe("Fase 42.5: Motor Visual Neovim (Folds e Conceal)", function()
    
    it("deve configurar conceallevel=2 na janela para ocultar as tags XML", function()
        local buf, win = chat_view.create_popup()
        assert.are.same(2, vim.wo[win].conceallevel, "conceallevel deve ser 2")
        assert.are.same("nc", vim.wo[win].concealcursor, "concealcursor deve ser 'nc'")
    end)

    it("deve criar um fold fechado ao redor de blocos arquivados", function()
        local buf, win = chat_view.create_popup()
        
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
            '<block id="b1" status="archived" type="raw">',
            'Texto super longo arquivado',
            '</block>',
            '<block id="s1" status="active" type="summary" covers="b1">',
            'Resumo',
            '</block>'
        })
        
        chat_view.create_folds(buf)
        vim.wait(200, function() return false end) -- Aguarda a execução da schedule queue do Neovim
        
        local fold_closed = vim.api.nvim_win_call(win, function()
            return vim.fn.foldclosed(2)
        end)
        
        assert.truthy(fold_closed ~= -1, "A linha arquivada deve estar dobrada (folded)")
    end)
end)
