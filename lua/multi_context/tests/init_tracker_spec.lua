local init = require('multi_context.init')
local memory_tracker = require('multi_context.utils.memory_tracker')
local api_client = require('multi_context.llm.api_client')
local popup = require('multi_context.ui.chat_view')
local config = require('multi_context.config')
local StateManager = require('multi_context.core.state_manager')
local react_orchestrator = require('multi_context.core.react_orchestrator')

describe("Fase 25 - Passo 2: Alimentando a EMA", function()
    local orig_execute, orig_defer, buf
    
    before_each(function()
        require('multi_context.config').options.user_name = "Nardi"
        config.options.user_name = "Nardi"
        memory_tracker.reset()
        config.options.watchdog = { mode = "off" } -- Garantindo que a compressao não ative e sequestre a chamada
        
        orig_defer = vim.defer_fn
        vim.defer_fn = function(cb, ms) cb() end
        
        orig_execute = api_client.execute
        api_client.execute = function(msgs, on_start, on_chunk, on_done)
            -- Simula a IA falando 12 caracteres (aprox 3 tokens) e terminando a execucao
            on_chunk("123456789012", {model="mock"}) 
            on_done({name="mock"}, {}) 
        end

        buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "## Nardi >>", "teste" })
        popup.popup_buf = buf
    end)

    after_each(function()
        api_client.execute = orig_execute
        vim.defer_fn = orig_defer
        vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("O Motor principal deve alimentar a memoria apos a IA finalizar a resposta", function()
        -- No disparo real, a resposta vai pra tela. O motor agora precisa medir o tamanho delta.
        require('multi_context.core.react_orchestrator').ProcessTurn(buf)
        
        -- Pelo design, esperamos que a contagem (count) vá de 0 para 1.
        assert.are.same(1, memory_tracker.state.count, "O on_done do ProcessTurn deveria ter acionado memory_tracker.add_turn()")
        -- 12 caracteres = 3 tokens. O tracker deve ter registrado pelo menos um valor > 0.
        assert.is_true(memory_tracker.get_ema() > 0, "A EMA deveria estar abastecida com os tokens gerados")
    end)
end)






