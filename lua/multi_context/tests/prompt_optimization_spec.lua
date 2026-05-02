local assert = require("luassert")

describe("Fase 24 - Otimização de System Prompt (Token Saving):", function()
    
    it("O system prompt base deve ser limpo e não possuir gorduras", function()
        local parser = require('multi_context.llm.prompt_parser')
        local base = "You are an AI."
        local mem = "Memory 1"
        local agent = "coder"
        local agents = { coder = { system_prompt = "Code well", skills = {"code_refactoring"} } }
        
        local p = parser.build_system_prompt(base, mem, agent, agents)
        -- Verificar que não injeta marcadores obsoletos (ex: <bash> ou <execute>)
        assert.is_nil(p:match("<bash>"))
        assert.is_nil(p:match("<execute>"))
    end)

    it("O cabeçalho do manual de habilidades deve ser altamente sintetizado", function()
        local registry = require('multi_context.skills.registry')
        
        -- Simulando um ambiente onde a ontologia resolve para 1 ferramenta
        package.loaded['multi_context.ecosystem.skills_ontology'] = {
            resolve_agent_skills = function()
                return {
                    semantic_skills = { { name = "test_skill", purpose = "To test." } },
                    raw_tools = { "dummy_tool" },
                    tools_set = { dummy_tool = true }
                }
            end
        }
        
        registry.get_skill_doc = function() return "<tool_definition><name>dummy_tool</name></tool_definition>" end
        
        local manual = registry.build_manual_for_skills({"test_skill"})
        
        -- O novo limite precisa ser ligeiramente maior pois agora inclui propósitos semânticos.
        -- Ajustado para <= 1200 tokens (bytes) mantendo a ideia de "sintético", porém suportando o novo bloco de regras da Fase 40
        assert.is_true(#manual < 1200, "O manual base deve ser hiper-sintético para economizar tokens. Tamanho atual: " .. #manual)
        
        -- Confirma as regras críticas otimizadas
        assert.is_true(manual:match("CRITICAL RULES") ~= nil)
        assert.is_true(manual:match("STRICT XML ONLY") ~= nil)
        assert.is_true(manual:match("NO MARKDOWN WRAPPING") ~= nil)
    end)
end)
