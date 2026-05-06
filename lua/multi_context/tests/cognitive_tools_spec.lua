local session = require('multi_context.core.session')
local tools = require('multi_context.ecosystem.native_tools')

describe("Fase 43.3/43.4: Cognitive Tools (Local RAG e Micro-Archiving)", function()
    before_each(function()
        session.clear()
        -- Mock de um histórico existente na RAM
        session.add_message("user", "Hello, please build a login function.", { 
            id = "b1", status = "active", 
            abstract = { summary = "User requested login function", key_words = "login" } 
        })
        session.add_message("assistant", "def login(): pass", { 
            id = "b2", status = "active", 
            abstract = { summary = "Provided mock python login", key_words = "python, mock" } 
        })
    end)

    it("deve recuperar o texto cru de blocos especificos via read_block_content", function()
        local result = tools.read_block_content("b1, b2")
        
        -- A IA que chamar isso deve receber de volta o conteúdo literal
        assert.truthy(result:match("Hello, please build a login function."))
        assert.truthy(result:match("def login%(%): pass"))
        assert.truthy(result:match("b1"))
        assert.truthy(result:match("b2"))
    end)

    it("deve retornar aviso se tentar ler um bloco inexistente", function()
        local result = tools.read_block_content("b99")
        assert.truthy(result:match("Nenhum bloco correspondente"))
    end)

    it("deve arquivar blocos ativamente e gerar um summary via archive_blocks", function()
        local result = tools.archive_blocks("b1,b2", "Resumo das saudações iniciais e mock")
        
        -- Verifica se a tool emite um sinal de sucesso para a IA
        assert.truthy(result:match("Sucesso"))
        
        local msgs = session.get_messages()
        
        -- Teremos os 2 originais (agora arquivados) + 1 resumo novo = 3 mensagens
        assert.are.equal(3, #msgs)
        
        assert.are.equal("archived", msgs[1].metadata.status)
        assert.are.equal("archived", msgs[2].metadata.status)
        
        local summary_msg = msgs[3]
        assert.are.equal("summary", summary_msg.metadata.type)
        assert.are.equal("b1,b2", summary_msg.metadata.covers)
        assert.are.equal("Resumo das saudações iniciais e mock", summary_msg.content)
    end)
end)
