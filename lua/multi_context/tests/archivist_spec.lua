local init = require('multi_context') -- Usando require na raiz para capturar o mesmo cache!
local popup = require('multi_context.ui.popup')
local react_loop = require('multi_context.react_loop')
local memory_tracker = require('multi_context.memory_tracker')

describe("Fase 22 - Passo 3: A Persona @archivist e a Compressao", function()
    local buf
    local orig_send, orig_defer
    local send_called = false

    before_each(function()
        send_called = false
        orig_send = init.SendFromPopup
        init.SendFromPopup = function() send_called = true end

        orig_defer = vim.defer_fn
        vim.defer_fn = function(cb, ms) cb() end

        buf = vim.api.nvim_create_buf(false, true)
        local archivist_response = {
            "## IA (archivist) >>",
            "<genesis>Criar um plugin Neovim</genesis>",
            "<plan>Refatorar init.lua</plan>",
            "<journey>- Swarm feito</journey>",
            "<now>Testando archivist</now>"
        }
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, archivist_response)
        popup.popup_buf = buf

        react_loop.state.pending_user_prompt = "Este e o meu comando original"
        react_loop.state.active_agent = "archivist"
        memory_tracker.state.count = 5 
    end)

    after_each(function()
        init.SendFromPopup = orig_send
        vim.defer_fn = orig_defer
        vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("Deve extrair o XML Quadripartite, limpar o buffer e re-anexar o prompt pendente", function()
        init.HandleArchivistCompression(1)
        
        local final_content = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
        
        assert.truthy(final_content:match("=== MEMÓRIA CONSOLIDADA %(QUADRIPARTITE%) ==="), "Deve ter o header de memoria")
        assert.truthy(final_content:match("<genesis>\nCriar um plugin Neovim\n</genesis>"), "Deve formatar genesis")
        assert.truthy(final_content:match("<plan>\nRefatorar init.lua\n</plan>"), "Deve formatar plan")
        assert.truthy(final_content:match("Este e o meu comando original"), "Deve re-injetar o prompt pendente")
        
        assert.is_nil(react_loop.state.pending_user_prompt)
        assert.is_nil(react_loop.state.active_agent)
        assert.are.same(0, memory_tracker.state.count)
        assert.is_true(send_called, "O motor de ReAct deve ter sido religado")
    end)
end)
