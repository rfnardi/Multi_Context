local prompt_parser = require('multi_context.llm.prompt_parser')
local registry = require('multi_context.skills.registry')
local config = require('multi_context.config')

describe("Fase 36 - Prompt Hardening e Anti-Alucinação:", function()
    before_each(function()
        -- Mock simples do config para evitar poluição
        config.options.language = "en"
    end)

    it("Deve informar explicitamente quando um agente NÃO possui ferramentas", function()
        -- Simulando um agente sem skills
        local mock_agents = {
            filosofo = { system_prompt = "Sou apenas uma IA de texto.", skills = {} }
        }
        
        local prompt = prompt_parser.build_system_prompt("Base", nil, "filosofo", mock_agents, 100)
        
        assert.truthy(prompt:match("WARNING: You currently have NO TOOLS available"), 
            "O prompt DEVE alertar a IA que ela não possui braços/ferramentas para evitar alucinações.")
    end)

    it("Deve aplicar o Recency Bias Guardrails no final absoluto do prompt", function()
        local mock_agents = { coder = { system_prompt = "Codifique.", skills = {"read_file"} } }
        local prompt = prompt_parser.build_system_prompt("Base", "Mem", "coder", mock_agents, 100)
        
        assert.truthy(prompt:match("FINAL GUARDRAILS %(OBEY STRICTLY%)"), "A seção de guardrails finais deve existir.")
        
        -- Verifica se a regra contra Markdown XML está presente
        assert.truthy(prompt:match("NEVER output ```xml wrappers around your tags"), 
            "Deve proibir ativamente os wrappers markdown ao redor do XML.")
        
        -- Garante que o Guardrail é a última grande instrução injetada
        local pos_guardrail = prompt:find("FINAL GUARDRAILS")
        local pos_sys = prompt:find("CURRENT PROJECT STATE")
        assert.truthy(pos_guardrail > pos_sys, "Os Guardrails DEVEM vir no fim do arquivo para aproveitar o Recency Bias da IA.")
    end)
    
    it("O Registry de Skills deve conter as regras críticas para agentes operacionais", function()
        local manual = registry.build_manual_for_skills({"edit_file", "run_shell"})
        
        assert.truthy(manual:match("STRICT XML ONLY"), "O manual de ferramentas deve forçar XML.")
        assert.truthy(manual:match("ONE ACTION PER TURN"), "O manual de ferramentas deve forçar 1 ação por turno.")
        assert.truthy(manual:match("AUTO%-LSP ACTIVE"), "Deve avisar a IA sobre o diagnóstico automático.")
    end)
end)
