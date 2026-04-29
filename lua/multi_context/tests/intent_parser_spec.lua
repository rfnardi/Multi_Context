local IntentParser = require('multi_context.core.intent_parser')

describe("Core Arquitetura 2.0: Intent Parser", function()
    it("Deve extrair a flag --queue e limpar o texto original", function()
        local raw = "@coder faça X --queue"
        local intent = IntentParser.parse(raw)
        
        assert.is_true(intent.flags.is_queue)
        assert.is_false(intent.flags.is_moa)
        assert.are.same("coder", intent.agent)
        assert.are.same("faça X", intent.clean_text)
    end)

    it("Deve extrair a flag --moa e rotear para o tech_lead", function()
        local raw = "@architect planeje, @coder faça --moa"
        local intent = IntentParser.parse(raw)
        
        assert.is_true(intent.flags.is_moa)
        -- No modo MOA, o agente principal DEVE ser forçado para o tech_lead
        assert.are.same("tech_lead", intent.agent) 
        -- O texto limpo deve manter as menções para o tech_lead ler
        assert.truthy(intent.clean_text:match("@architect planeje, @coder faça"))
    end)

    it("Deve identificar um chat normal sem flags", function()
        local raw = "Apenas uma mensagem normal"
        local intent = IntentParser.parse(raw)
        
        assert.is_false(intent.flags.is_queue)
        assert.is_false(intent.flags.is_moa)
        assert.is_nil(intent.agent)
        assert.are.same("Apenas uma mensagem normal", intent.clean_text)
    end)
end)

describe("Core Arquitetura 2.0: Intent Parser (parse_lines)", function()
    local IntentParser = require('multi_context.core.intent_parser')

    it("Deve processar array de linhas fatiando fila e extraindo flags", function()
        local lines = {"@coder faca X --queue", "depois", "@qa teste"}
        local mock_agents = { coder = {}, qa = {} }
        
        local intent = IntentParser.parse_lines(lines, mock_agents)
        
        assert.is_true(intent.flags.is_queue)
        assert.is_false(intent.flags.is_moa)
        assert.are.same("@coder faca X\ndepois", intent.raw_current_task)
        assert.are.same("@qa teste", intent.queued_text)
    end)
    
    it("No modo --moa, não deve fatiar os agentes para a fila", function()
        local lines = {"@architect analise, @coder faca --moa"}
        local mock_agents = { architect = {}, coder = {} }
        
        local intent = IntentParser.parse_lines(lines, mock_agents)
        
        assert.is_true(intent.flags.is_moa)
        assert.are.same("@architect analise, @coder faca", intent.raw_current_task)
        assert.is_nil(intent.queued_text)
    end)
end)
