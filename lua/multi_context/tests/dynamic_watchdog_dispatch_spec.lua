require("multi_context.tests.libuv_barrier")
local watchdog = require('multi_context.core.dynamic_watchdog')
local api_client = require('multi_context.llm.api_client')
local config = require('multi_context.config')

describe("Fase 44.2: JIT Micro-Archiving Dispatcher", function()
    local orig_execute
    local orig_load_api_config
    local execute_called = false
    local passed_force_cfg = nil
    
    before_each(function()
        orig_execute = api_client.execute
        orig_load_api_config = config.load_api_config
        execute_called = false
        passed_force_cfg = nil
        
        -- Mock do Client de API
        api_client.execute = function(payload, on_start, on_chunk, on_done, on_error, force_cfg)
            execute_called = true
            passed_force_cfg = force_cfg
            
            -- Simula o stream e a conclusao
            if on_chunk then
                on_chunk("<key_words>test</key_words>\n<summary>mock summary</summary>")
            end
            if on_done then
                on_done(force_cfg, {})
            end
        end
        
        -- Configuração de cenário
        config.options.watchdog = {
            strategy = "dynamic",
            background_api = "fast_api_haiku"
        }
        
        config.load_api_config = function()
            return {
                apis = {
                    { name = "fast_api_haiku", model = "claude-3-haiku", api_type = "anthropic" },
                    { name = "slow_api_opus", model = "claude-3-opus", api_type = "anthropic" }
                }
            }
        end
    end)
    
    after_each(function()
    if _G.AwaitForBackground then _G.AwaitForBackground() end
        api_client.execute = orig_execute
        config.load_api_config = orig_load_api_config
    end)
    
    it("deve despachar a task JIT forcando o uso da background_api especificada", function()
        local buf = vim.api.nvim_create_buf(false, true)
        
        watchdog.dispatch_jit_task(buf, "b1", "Test content")
        
        assert.truthy(execute_called, "api_client.execute não foi chamado!")
        assert.is_not_nil(passed_force_cfg, "Não enviou o force_cfg para sobrepor a API normal!")
        assert.are.equal("fast_api_haiku", passed_force_cfg.name)
    end)

    it("nao deve despachar o client se a estrategia do watchdog for diferente de dynamic", function()
        config.options.watchdog.strategy = "semantic"
        local buf = vim.api.nvim_create_buf(false, true)
        
        watchdog.dispatch_jit_task(buf, "b1", "Test content")
        
        assert.falsy(execute_called, "O Watchdog enviou a request JIT mesmo com a estratégia desligada/semântica.")
    end)
    
    it("nao deve despachar o client se a background_api estiver em branco", function()
        config.options.watchdog.strategy = "dynamic"
        config.options.watchdog.background_api = nil
        local buf = vim.api.nvim_create_buf(false, true)
        
        watchdog.dispatch_jit_task(buf, "b1", "Test content")
        
        assert.falsy(execute_called, "O Watchdog enviou a request JIT para uma API nula.")
    end)
end)
