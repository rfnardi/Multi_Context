require("multi_context.tests.libuv_barrier")
local prompt_parser = require('multi_context.llm.prompt_parser')

describe("Fase 43.2: Visão Assimétrica (prompt_parser e memory_tier)", function()
    local messages
    
    before_each(function()
        messages = {
            {
                role = "user",
                content = "Write a python script",
                metadata = {
                    id = "b1", type = "raw", status = "active",
                    abstract = { summary = "User requested python script.", key_words = "python, script" }
                }
            },
            {
                role = "assistant",
                content = "print('hello')",
                metadata = {
                    id = "b2", type = "raw", status = "active",
                    abstract = { summary = "Provided hello world script.", key_words = "hello, world" }
                }
            },
            {
                role = "user",
                content = "Now make it print 'universe'",
                metadata = { id = "b3", type = "raw", status = "active" }
            }
        }
    end)

    it("deve construir payload STANDARD (exibindo apenas content sem metadados)", function()
        local payload = prompt_parser.build_asymmetric_payload("System Prompt", messages, "standard")
        
        assert.are.equal(4, #payload) -- system + 3 messages
        assert.are.equal("system", payload[1].role)
        
        -- M1 (user)
        assert.are.equal("user", payload[2].role)
        assert.are.equal("Write a python script", vim.trim(payload[2].content))
        
        -- M2 (assistant)
        assert.are.equal("assistant", payload[3].role)
        assert.are.equal("print('hello')", vim.trim(payload[3].content))
        
        -- M3 (user - last)
        assert.are.equal("Now make it print 'universe'", vim.trim(payload[4].content))
    end)

    it("deve construir payload META (exibindo apenas abstracts no historico, mas conteudo total no ultimo turno)", function()
        local payload = prompt_parser.build_asymmetric_payload("System Prompt", messages, "meta")
        
        assert.are.equal(4, #payload)
        
        -- M1 (historico) -> Apenas abstract
        assert.truthy(payload[2].content:match("%[ID: b1%]"))
        assert.truthy(payload[2].content:match("Abstract: User requested python script."))
        assert.truthy(payload[2].content:match("Keywords: python, script"))
        assert.falsy(payload[2].content:match("Write a python script")) -- raw content escondido!
        
        -- M2 (historico) -> Apenas abstract
        assert.truthy(payload[3].content:match("%[ID: b2%]"))
        assert.truthy(payload[3].content:match("Abstract: Provided hello world script."))
        assert.falsy(payload[3].content:match("print%('hello'%)")) -- raw content escondido!
        
        -- M3 (ultimo turno) -> Conteudo RAW integral mantido para orquestracao imediata
        assert.are.equal("Now make it print 'universe'", vim.trim(payload[4].content))
        assert.falsy(payload[4].content:match("Abstract:"))
    end)

    it("deve renderizar summary blocks corretamente no tier META", function()
        local msgs_with_summary = {
            {
                role = "assistant",
                content = "This is a summary of steps 1 and 2.",
                metadata = { id = "s1", type = "summary", status = "active", covers = "b1,b2" }
            },
            {
                role = "user",
                content = "Next step please.",
                metadata = { id = "b4", type = "raw", status = "active" }
            }
        }
        
        local payload = prompt_parser.build_asymmetric_payload("Sys", msgs_with_summary, "meta")
        
        -- M1 (summary)
        assert.truthy(payload[2].content:match("%[ID: s1%]"))
        assert.truthy(payload[2].content:match("SUMMARY OF ARCHIVED BLOCKS: b1,b2"))
        assert.truthy(payload[2].content:match("This is a summary of steps 1 and 2."))
    end)
    
    it("deve fazer fallback para RAW no tier META se nao houver abstract num bloco do historico", function()
        local msgs_no_abstract = {
            {
                role = "user",
                content = "Legacy block content.",
                metadata = { id = "b1", type = "raw", status = "active" }
            },
            {
                role = "assistant",
                content = "Sure.",
                metadata = { id = "b2", type = "raw", status = "active" }
            }
        }
        
        local payload = prompt_parser.build_asymmetric_payload("Sys", msgs_no_abstract, "meta")
        
        -- O b1 nao tem abstract, entao deve mostrar o conteudo raw
        assert.truthy(payload[2].content:match("%[ID: b1%]"))
        assert.truthy(payload[2].content:match("Legacy block content."))
    end)
end)
