require("multi_context.tests.libuv_barrier")
local watchdog = require('multi_context.core.dynamic_watchdog')
local session = require('multi_context.core.session')
local api = vim.api

describe("Fase 44: JIT Micro-Archiving", function()
    local buf
    
    before_each(function()
        buf = api.nvim_create_buf(false, true)
        session.clear()
    end)
    
    it("deve construir payload JIT focado estritamente em abstracao de 1 bloco", function()
        local payload = watchdog.build_jit_payload("This is a simple hello world implementation in lua.")
        
        -- Deve ser super curto para economizar tokens do modelo secundario
        assert.are.equal(2, #payload)
        assert.are.equal("system", payload[1].role)
        assert.truthy(payload[1].content:match("You are a Cognitive Librarian"))
        assert.truthy(payload[1].content:match("<key_words>"))
        assert.truthy(payload[1].content:match("<summary>"))
        
        assert.are.equal("user", payload[2].role)
        assert.are.equal("This is a simple hello world implementation in lua.", payload[2].content)
    end)

    it("deve fazer o patch cirurgico do abstract num bloco legado dentro do buffer", function()
        local initial_lines = {
            "Some chat noise",
            '<block id="b1" type="raw" role="assistant" status="active">',
            "This is the actual code.",
            "End of code.",
            '</block>',
            "More noise"
        }
        api.nvim_buf_set_lines(buf, 0, -1, false, initial_lines)
        
        local abstract_xml = "<key_words>code, end</key_words>\n<summary>Provided code block</summary>"
        
        local ok, err = pcall(watchdog.patch_block_abstract, buf, "b1", abstract_xml)
        assert.truthy(ok, "Erro ao fazer patch do bloco: " .. tostring(err))
        
        local new_lines = api.nvim_buf_get_lines(buf, 0, -1, false)
        local content = table.concat(new_lines, "\n")
        
        -- O bloco deve ter sido transmutado
        assert.truthy(content:match("<abstract>"), "Não injetou o <abstract>")
        assert.truthy(content:match("<key_words>code, end</key_words>"), "Faltaram as key_words")
        assert.truthy(content:match("<summary>Provided code block</summary>"), "Faltou o summary")
        assert.truthy(content:match("<content>\nThis is the actual code.\nEnd of code.\n</content>"), "Faltou empacotar o content original com <content>")
        assert.truthy(content:match("More noise"), "Estragou o final do buffer")
    end)
end)
