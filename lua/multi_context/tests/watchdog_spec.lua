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
        require('multi_context.config').options.user_name = "Nardi"
        config.options.user_name = "Nardi"
        captured_requests = {}
        StateManager.get('react').pending_user_prompt = nil
        StateManager.get('react').active_agent = nil
        
        config.options.cognitive_horizon = 2000
        config.options.user_tolerance = 1.0
        
        orig_defer = vim.defer_fn
        vim.defer_fn = function(cb, ms) cb() end
        
        orig_execute = api_client.execute
        api_client.execute = function(msgs, on_start, on_chunk, on_done)
            table.insert(captured_requests, msgs)
            if on_start then on_start(999) end
            if on_done then on_done({name="mock"}, {}) end
        end

        buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "## Nardi >>", "Faça uma refatoração enorme." })
        popup.popup_buf = buf
        
        orig_predict = memory_tracker.predict_next_total
    end)

    after_each(function()
        api_client.execute = orig_execute
        memory_tracker.predict_next_total = orig_predict
        vim.defer_fn = orig_defer
        vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("Deve INTERCEPTAR a requisicao e injetar o modelo Quadripartite se estourar, e depois religar sozinho", function()
        local call_count = 0
        memory_tracker.predict_next_total = function() 
            call_count = call_count + 1
            if call_count == 1 then return 2500 else return 1000 end
        end
        
        require('multi_context.core.react_orchestrator').ProcessTurn(buf)
        
        assert.are.same(2, #captured_requests, "O Motor deve ter feito a chamada do Guardiao E religado automaticamente depois!")
        
        local arquivista_msg = captured_requests[1][#captured_requests[1]].content
        assert.truthy(arquivista_msg:match("Quadripartite"))
        assert.truthy(arquivista_msg:match("<plan>"))
        
        local user_restored_msg = captured_requests[2][#captured_requests[2]].content
        assert.truthy(user_restored_msg:match("Faça uma refatoração enorme"), "A segunda requisicao deve ser a restauracao do user")
    end)
end)






