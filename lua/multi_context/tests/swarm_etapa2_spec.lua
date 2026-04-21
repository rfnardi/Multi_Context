local popup = require('multi_context.ui.popup')
local api = vim.api

describe("Swarm Etapa 2 - Multi-Buffers e UI:", function()
    before_each(function()
        -- Limpa qualquer janela flutuante e reseta o estado antes de cada teste
        if popup.popup_win and api.nvim_win_is_valid(popup.popup_win) then
            api.nvim_win_close(popup.popup_win, true)
        end
        popup.popup_win = nil
        popup.popup_buf = nil
        popup.swarm_buffers = {}
        popup.current_swarm_index = 1
    end)

    it("Deve criar o popup principal e registrar como buffer de indice 1", function()
        local buf, win = popup.create_popup("Teste Main")
        
        assert.is_not_nil(popup.swarm_buffers)
        assert.are.same(1, #popup.swarm_buffers)
        assert.are.same(buf, popup.swarm_buffers[1].buf)
        assert.are.same("Main", popup.swarm_buffers[1].name)
    end)

    it("Deve criar sub-buffers isolados para workers", function()
        popup.create_popup("Main")
        local sub_buf = popup.create_swarm_buffer("coder", "Tarefa: refatorar")
        
        assert.are.same(2, #popup.swarm_buffers)
        assert.are.same("coder", popup.swarm_buffers[2].name)
        assert.are.same(sub_buf, popup.swarm_buffers[2].buf)
        
        -- Verifica o isolamento rígido
        assert.are.same("nofile", vim.bo[sub_buf].buftype)
        assert.are.same("hide", vim.bo[sub_buf].bufhidden)
        assert.are.same("multicontext_chat", vim.bo[sub_buf].filetype)
    end)

    it("Deve alternar entre os buffers circularmente (Tab/S-Tab)", function()
        local main_buf, win = popup.create_popup("Main")
        local b2 = popup.create_swarm_buffer("coder", "codigo")
        local b3 = popup.create_swarm_buffer("qa", "testes")

        assert.are.same(1, popup.current_swarm_index)
        assert.are.same(main_buf, api.nvim_win_get_buf(win))

        -- Avança para o 2
        popup.cycle_swarm_buffer(1)
        assert.are.same(2, popup.current_swarm_index)
        assert.are.same(b2, api.nvim_win_get_buf(win))

        -- Avança para o 3
        popup.cycle_swarm_buffer(1)
        assert.are.same(3, popup.current_swarm_index)
        assert.are.same(b3, api.nvim_win_get_buf(win))

        -- Avança para o 1 (Circular, passou do limite)
        popup.cycle_swarm_buffer(1)
        assert.are.same(1, popup.current_swarm_index)
        assert.are.same(main_buf, api.nvim_win_get_buf(win))

        -- Volta para o 3 (Circular invertido, recuou do 1)
        popup.cycle_swarm_buffer(-1)
        assert.are.same(3, popup.current_swarm_index)
        assert.are.same(b3, api.nvim_win_get_buf(win))
    end)
end)
