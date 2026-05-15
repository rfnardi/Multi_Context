require("multi_context.tests.libuv_barrier")
local utils = require('multi_context.utils.utils')

describe("Utils Module:", function()
    it("Deve dividir strings por quebra de linha corretamente", function()
        local str = "linha1\nlinha2\nlinha3"
        local res = utils.split_lines(str)
        assert.are.same({"linha1", "linha2", "linha3"}, res)
    end)

    it("Deve estimar tokens corretamente (4 chars = 1 token)", function()
        local buf = vim.api.nvim_create_buf(false, true)
        -- Injeta 2 linhas. A lógica soma: (#linha + 1). Total: (5+1) + (5+1) = 12 chars
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"12345", "12345"})
        
        local tokens = utils.estimate_tokens(buf)
        -- 12 / 4 = 3 tokens
        assert.are.same(3, tokens)
    end)
end)







describe("Fase 48 - Swarm AST Serialization e Arquivamento:", function()
    before_each(function()
        require('multi_context.core.swarm_manager').reset()
    end)

    it("Deve converter a sessao Swarm salva para um <block type='swarm' status='running'>", function()
        local utils = require('multi_context.utils.utils')
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"Linha do chat 1", "Linha do chat 2"})
        
        -- Mocks do estado global
        local popup = require('multi_context.ui.chat_view')
        popup.swarm_buffers = { 
            { buf = buf, name = "Main" }, 
            { buf = buf, name = "coder", status = "Rodando" } 
        }
        
        local _, content = utils.build_workspace_content(buf, "chat_2026.mctx")
        
        -- Asserts: Não deve usar mais a tag obsoleta e deve envelopar no padrão de bloco
        assert.falsy(content:match("<swarm_state>"), "Não deve mais existir a tag isolada <swarm_state>")
        assert.truthy(content:match('<block[^>]+type="swarm"'), "O state DEVE ser salvo como um bloco AST do tipo swarm.")
        assert.truthy(content:match('status="running"'), "O status serializado deve indicar 'running'.")
        assert.truthy(content:match('<content>%s*{'), "O objeto JSON deve estar confinado dentro da child-tag <content> do bloco.")
    end)
    
    it("Deve ser capaz de ler e hidratar o estado do enxame a partir da nova AST", function()
        local utils = require('multi_context.utils.utils')
        local buf = vim.api.nvim_create_buf(false, true)
        
        -- Simulando um workspace carregado do disco
        local mock_mctx = [[
<mctx_session id="999" />
<block id="sys_1" type="interaction">Oi</block>
<block id="sw_1" type="swarm" status="running">
<content>
{"queue": [{"agent": "devops"}], "reports": [], "buffers": [{"name": "devops", "lines": ["## DEV"]}]}
</content>
</block>
]]
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(mock_mctx, "\n"))
        
        utils.load_workspace_state(buf)
        
        local swarm = require('multi_context.core.swarm_manager')
        assert.truthy(swarm.state.queue[1], "O parser deve ser capaz de extrair a 'queue' do Swarm dentro da AST Polimórfica.")
        assert.are.same("devops", swarm.state.queue[1].agent, "O carregamento de estado reverteu a propriedade agent incorretamente.")
    end)
end)
