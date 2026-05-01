local config = require('multi_context.config')
local popup = require('multi_context.ui.chat_view')
local init = require('multi_context.init')
local api_client = require('multi_context.llm.api_client')
local transport = require('multi_context.llm.transport')

describe("Integracao - Consumo das Configs do Painel pelo Motor", function()
    local orig_execute
    local orig_open_win
    local captured_win_opts

    before_each(function()
        config.options.appearance = { width = 0.5, height = 0.5, border = "double" }
        config.options.master_prompt = "DIRETRIZ_MESTRE_TESTE"
        config.options.debug_mode = true
        config.options.user_name = "User"
        
        orig_execute = api_client.execute
        
        -- Interceptamos a chamada nativa do Neovim para ver o que o plugin enviou pra lá
        orig_open_win = vim.api.nvim_open_win
        vim.api.nvim_open_win = function(buf, enter, opts)
            captured_win_opts = opts
            return orig_open_win(buf, enter, opts)
        end
    end)
    
    after_each(function()
        api_client.execute = orig_execute
        vim.api.nvim_open_win = orig_open_win
    end)

    it("popup.lua deve aplicar a largura e borda customizadas do config", function()
        if popup.popup_win and vim.api.nvim_win_is_valid(popup.popup_win) then
            vim.api.nvim_win_close(popup.popup_win, true)
        end
        
        local buf, win = popup.create_popup("Teste")
        
        local expected_w = math.ceil(vim.o.columns * 0.5)
        
        assert.is_not_nil(captured_win_opts, "Deveria ter capturado as opcoes da janela")
        assert.are.same(expected_w, captured_win_opts.width, "A largura deve corresponder a 0.5 (50%)")
        assert.are.same("double", captured_win_opts.border, "A borda original enviada deve ser 'double'")
    end)

    it("init.lua deve enviar o master_prompt customizado na requisicao", function()
        local captured_sys_prompt = ""
        
        api_client.execute = function(messages)
            captured_sys_prompt = messages[1].content
        end
        
        popup.popup_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(popup.popup_buf, 0, -1, false, {"## User >>", "Oi IA"})
        
        -- Evita defer e executa o disparo
        local orig_defer = vim.defer_fn
        vim.defer_fn = function(cb) cb() end
        
        require('multi_context.core.react_orchestrator').ProcessTurn(popup.popup_buf)
        
        vim.defer_fn = orig_defer
        assert.truthy(captured_sys_prompt:match("DIRETRIZ_MESTRE_TESTE"), "O master_prompt deve ser injetado no inicio da requisicao")
    end)

    it("transport.lua deve gerar um arquivo de log quando debug_mode for true", function()
        local log_file = vim.fn.stdpath("data") .. "/mctx_network_debug.log"
        os.remove(log_file)
        
        -- Dispara um mock de comando que simula o curl
        transport.run_http_stream({"echo", "telemetria_teste"}, "dummy.json", function() end, function() return nil end, function() end)
        
        -- Aguarda a promise do job assincrono terminar
        vim.wait(200, function() return vim.fn.filereadable(log_file) == 1 end, 10)
        
        assert.are.same(1, vim.fn.filereadable(log_file), "O arquivo de log deve ser criado porque debug_mode esta ativo")
    end)
end)
