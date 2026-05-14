require("multi_context.tests.libuv_barrier")
local session = require('multi_context.core.session')
local StateManager = require('multi_context.core.state_manager')

describe("Fase 43.1: Session Ontology and Dual AST Parser", function()
    before_each(function()
        session.clear()
    end)

    it("deve fazer o parse de um bloco completo contendo abstract, key_words, summary e content", function()
        local lines = {
            '<block id="b1" type="raw" role="user" status="active">',
            '<abstract>',
            '<key_words>test, parser, ast</key_words>',
            '<summary>User requested AST parsing.</summary>',
            '</abstract>',
            '<content>',
            'Please implement the new AST parser.',
            '</content>',
            '</block>'
        }
        
        session.sync_from_lines(lines)
        local msgs = session.get_messages()
        
        assert.are.equal(1, #msgs)
        local msg = msgs[1]
        
        -- Verifica se isolou o conteudo
        assert.are.equal("user", msg.role)
        assert.are.equal("Please implement the new AST parser.", vim.trim(msg.content))
        
        -- Verifica se extraiu a arvore do abstract
        assert.is_not_nil(msg.metadata.abstract)
        assert.are.equal("test, parser, ast", vim.trim(msg.metadata.abstract.key_words))
        assert.are.equal("User requested AST parsing.", vim.trim(msg.metadata.abstract.summary))
        assert.are.equal("b1", msg.metadata.id)
    end)

    it("deve realizar fallback transparente (legacy support) para blocos antigos sem tags internas", function()
        local lines = {
            '<block id="b2" type="raw" role="assistant" status="active">',
            'This is a legacy block without inner tags.',
            'It should be entirely treated as content.',
            '</block>'
        }
        
        session.sync_from_lines(lines)
        local msgs = session.get_messages()
        
        assert.are.equal(1, #msgs)
        local expected = "This is a legacy block without inner tags.\nIt should be entirely treated as content."
        assert.are.equal(expected, vim.trim(msgs[1].content))
        
        -- Abstract deve estar nulo neste caso
        assert.is_nil(msgs[1].metadata.abstract)
    end)

    it("deve compreender a natureza dupla dos summary blocks (sem necessidade de abstract formal)", function()
        local lines = {
            '<block id="b3" type="summary" role="assistant" status="active" covers="b1,b2">',
            'This is a summary block.',
            '</block>'
        }
        
        session.sync_from_lines(lines)
        local msgs = session.get_messages()
        
        assert.are.equal(1, #msgs)
        assert.are.equal("This is a summary block.", vim.trim(msgs[1].content))
        assert.are.equal("summary", msgs[1].metadata.type)
        assert.are.equal("b1,b2", msgs[1].metadata.covers)
    end)

    it("deve suportar a insercao programatica (add_message) contendo metadados de abstract", function()
        local meta = {
            id = "b4",
            type = "raw",
            status = "active",
            abstract = {
                key_words = "programmatic, add",
                summary = "Added via API"
            }
        }
        
        session.add_message("assistant", "Programmatic content", meta)
        
        local msgs = session.get_messages()
        assert.are.equal(1, #msgs)
        assert.are.equal("Programmatic content", msgs[1].content)
        
        assert.is_not_nil(msgs[1].metadata.abstract)
        assert.are.equal("programmatic, add", msgs[1].metadata.abstract.key_words)
        assert.are.equal("Added via API", msgs[1].metadata.abstract.summary)
    end)
end)
