require("multi_context.tests.libuv_barrier")
local chat_view = require('multi_context.ui.chat_view')

describe("Regression - Swarm UI Folds (Anti-Vazamento Visual):", function()
    local orig_cmd
    
    before_each(function()
        orig_cmd = vim.cmd
    end)
    
    after_each(function()
        vim.cmd = orig_cmd
    end)

    it("Deve gerar os comandos corretos de 'fold' do Neovim para os blocos do Enxame", function()
        local buf = vim.api.nvim_create_buf(false, true)
        
        -- [CORREÇÃO CRÍTICA]: Atrela o buffer à janela atual. 
        -- Sem isso, o motor de UI aborta a renderização por otimização de performance!
        vim.api.nvim_set_current_buf(buf)
        
        local mock_swarm_block = {
            '<block id="sw_1" type="swarm" status="running">',
            '<content>',
            '{"gigante": "JSON", "memoria": "vazando"}',
            '</content>',
            '</block>'
        }
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, mock_swarm_block)
        
        local fold_commands_issued = ""
        vim.cmd = function(cmd)
            if type(cmd) == "string" and cmd:match("fold") then
                fold_commands_issued = fold_commands_issued .. " | " .. cmd
            else
                pcall(orig_cmd, cmd)
            end
        end
        
        -- Aciona o motor visual
        chat_view.create_folds(buf)
        
        -- Aguarda o vim.schedule() resolver os folds (Assíncrono)
        vim.wait(200, function() return fold_commands_issued:match("fold") ~= nil end)
        
        -- Asserções
        assert.truthy(fold_commands_issued:match("1,5fold"), "O motor de UI DEVE agrupar o bloco Swarm em uma dobra de código.")
        assert.truthy(fold_commands_issued:match("1foldclose"), "O motor de UI DEVE fechar a dobra automaticamente.")
    end)
end)
