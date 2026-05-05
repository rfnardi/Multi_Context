local conv = require('multi_context.core.conversation')
local config = require('multi_context.config')
local session = require('multi_context.core.session')
local StateManager = require('multi_context.core.state_manager')

describe("Conversation Module:", function()
    before_each(function()
        StateManager.reset()
        session.clear()
        config.options.user_name = "Nardi"
    end)

    it("Deve encontrar a última linha de comando do usuário", function()
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
            "## Nardi >> primeirao",
            "## IA >> resposta",
            "## Nardi >> ultimo comando"
        })
        
        local idx, line = conv.find_last_user_line(buf)
        assert.are.same(2, idx)
        assert.are.same("## Nardi >> ultimo comando", line)
    end)

    it("Deve ignorar mensagens de [Sistema] na hora de ler o último comando", function()
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
            "## Nardi >> faça algo",
            "## IA >> <tool_call...",
            "## Nardi >> [Sistema]: Ferramentas executadas"
        })
        local idx, line = conv.find_last_user_line(buf)
        assert.are.same(2, idx)
        assert.truthy(line:match("%[Sistema%]"))
    end)

    it("Deve construir o array de mensagens (build_history) perfeitamente", function()
        local buf = vim.api.nvim_create_buf(false, true)
        
        -- Multi-linhas passadas como múltiplos itens de array para respeitar o nvim_buf_set_lines
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
            '<block id="1" type="raw" role="user" status="active">Primeiro comando',
            'Detalhes do comando</block>',
            '<block id="2" type="raw" role="assistant" status="active">Resposta da IA',
            'Mais texto da IA</block>',
            '<block id="3" type="raw" role="user" status="active">Segundo comando</block>'
        })
        
        local msgs = conv.build_history(buf)
        
        assert.are.same(3, #msgs)
        assert.are.same("user", msgs[1].role)
        assert.truthy(msgs[1].content:match("Primeiro comando\nDetalhes do comando"))
        assert.are.same("assistant", msgs[2].role)
        assert.truthy(msgs[2].content:match("Resposta da IA\nMais texto da IA"))
        assert.are.same("user", msgs[3].role)
        assert.truthy(msgs[3].content:match("Segundo comando"))
    end)
end)
