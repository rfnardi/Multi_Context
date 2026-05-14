require("multi_context.tests.libuv_barrier")
local init = require('multi_context')
local memory_tracker = require('multi_context.utils.memory_tracker')
local api_client = require('multi_context.llm.api_client')
local popup = require('multi_context.ui.chat_view')
local config = require('multi_context.config')
local StateManager = require('multi_context.core.state_manager')
local react_orchestrator = require('multi_context.core.react_orchestrator')

describe("Fase 22 - Passo 2: O Interceptador do Watchdog", function()
    local orig_execute, orig_predict, orig_defer
    local captured_requests = {}
    local buf

    before_each(function()
        StateManager.reset()
        memory_tracker.reset()
        
        config.options = vim.deepcopy(config.defaults)
        config.options.user_name = "User"
        config.options.cognitive_horizon = 2000
        config.options.user_tolerance = 1.0
        
        config.options.watchdog = {
            mode = "off",
            strategy = "semantic",
            percent = 0.3,
            fixed_target = 1500,
            background_api = ""
        }
        
        captured_requests = {}
        
        orig_defer = vim.defer_fn
        vim.defer_fn = function(cb, ms) cb() end
        
        orig_execute = api_client.execute
        api_client.execute = function(msgs, on_start, on_chunk, on_done)
            table.insert(captured_requests, msgs)
            if on_start then on_start(999) end
            if on_done then on_done({name="mock"}, {}) end
        end

        buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "## User >>", "Faça uma refatoração enorme." })
        popup.popup_buf = buf
        
        orig_predict = memory_tracker.predict_next_total
    end)

    after_each(function()
    if _G.AwaitForBackground then _G.AwaitForBackground() end
        api_client.execute = orig_execute
        memory_tracker.predict_next_total = orig_predict
        vim.defer_fn = orig_defer
        if vim.api.nvim_buf_is_valid(buf) then
            vim.api.nvim_buf_delete(buf, { force = true })
        end
    end)

    it("Deve INTERCEPTAR a requisicao e injetar o modelo Quadripartite se estourar, e depois religar sozinho", function()
        local call_count = 0
        memory_tracker.predict_next_total = function() 
            call_count = call_count + 1
            return (call_count == 1) and 2500 or 1000
        end
        
        require('multi_context.core.react_orchestrator').ProcessTurn(buf)
        
        assert.are.same(2, #captured_requests, "O Motor deve ter feito a chamada do Guardiao E religado automaticamente depois!")
    end)
end)
