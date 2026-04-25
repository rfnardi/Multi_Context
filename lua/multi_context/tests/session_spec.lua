local utils = require('multi_context.utils')
local swarm = require('multi_context.swarm_manager')
local popup = require('multi_context.ui.popup')

describe("Fase 18.5 - Session & State Management:", function()
    before_each(function()
        swarm.reset()
        popup.swarm_buffers = {}
    end)

    it("Deve gerar tag de sessao e injetar o swarm_state", function()
        -- Simulando um estado complexo no enxame
        swarm.state.queue = { { agent = "qa", instruction = "teste unitario" } }
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"## User >>", "Oi, IA"})
        popup.popup_buf = buf
        
        local filename, exported_text = utils.build_workspace_content(buf, nil)
        
        assert.truthy(exported_text:match("<mctx_session id="), "Deve conter tag de sessao no topo")
        assert.truthy(exported_text:match("<swarm_state>"), "Deve conter tag de estado do enxame no final")
        assert.truthy(exported_text:match("qa"), "Deve conter os dados da fila exportados em JSON")
        assert.truthy(filename:match("%.mctx$"), "Deve gerar o nome do arquivo corretamente")
    end)
    
    it("Deve desserializar e reconstruir o enxame ao carregar o chat", function()
        local payload = [[
<mctx_session id="999" created="2026-04-21T00:00:00" updated="2026-04-21T00:00:00" />
## User >>
Teste
<swarm_state>
{"queue":[{"agent":"coder","instruction":"faz_algo"}], "buffers":[{"name":"coder","lines":["## IA >>","Codando..."]}]}
</swarm_state>
]]
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(payload, "\n", {plain=true}))
        
        -- Simulando Aba Main na UI
        popup.swarm_buffers = { { buf = buf, name = "Main" } }
        
        utils.load_workspace_state(buf)
        
        -- Afirmações de Ressurreição de Estado
        assert.are.same(1, #swarm.state.queue, "A fila devera ter voltado a vida")
        assert.are.same("coder", swarm.state.queue[1].agent)
        assert.truthy(#popup.swarm_buffers > 1, "Deve ter recriado o buffer do worker paralelo na memoria")
        assert.are.same("coder", popup.swarm_buffers[2].name)
    end)
end)

    it("Deve orquestrar o load pelo comando ToggleWorkspaceView (init.lua)", function()
        local init = require('multi_context.init')
        local utils = require('multi_context.utils')
        
        -- Configura um buffer simulando um arquivo aberto em disco
        local buf = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_buf_set_name(buf, "/caminho/falso/chat_123.mctx")
        vim.api.nvim_set_current_buf(buf)
        
        -- Simulamos a UI limpa
        popup.popup_win = nil
        init.current_workspace_file = nil
        
        -- Adiciona payload no buffer
        local payload = {
            '<mctx_session id="123" />',
            '## User >>',
            'Contexto'
        }
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, payload)
        
        -- Mockamos as funções pesadas da UI para não travar o ambiente Headless
        local orig_create_popup = popup.create_popup
        local was_popup_called = false
        popup.create_popup = function(b) 
            was_popup_called = true
            popup.popup_buf = b
        end
        
        -- Ação E2E: Usuário digita o comando para carregar a sessão!
        init.ToggleWorkspaceView()
        
        -- Asserts: O core do plugin tem que entender que isso é um load
        assert.truthy(init.current_workspace_file:match("chat_123%.mctx"), "O arquivo de workspace atual não foi setado!")
        assert.is_true(was_popup_called, "A janela flutuante não foi invocada pelo init.lua!")
        
        -- Cleanup
        popup.create_popup = orig_create_popup
    end)






