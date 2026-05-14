require("multi_context.tests.libuv_barrier")
local assert = require("luassert")
local session = require("multi_context.core.session")

describe("Fase 45.3 e 45.4 - O Harvester e a Skill de Conhecimento", function()

    describe("45.3: skills_ontology.lua - manage_project_knowledge", function()
        it("deve carregar a skill semantica manage_project_knowledge com a tool update_context_md", function()
            local ontology = require("multi_context.ecosystem.ontology")
            local skills = ontology.load_semantic_skills()
            assert.is_not_nil(skills.manage_project_knowledge, "Skill manage_project_knowledge não encontrada")
            
            local has_tool = false
            for _, t in ipairs(skills.manage_project_knowledge.tools or {}) do
                if t == "update_context_md" then has_tool = true; break end
            end
            assert.is_true(has_tool, "A tool update_context_md não foi associada à skill.")
        end)
    end)

    describe("45.3: native_tools.lua - update_context_md", function()
        it("deve atualizar ou criar o CONTEXT.md na raiz do projeto", function()
            local tools = require("multi_context.ecosystem.native_tools")
            local old_system = vim.fn.system
            local old_writefile = vim.fn.writefile
            local old_filereadable = vim.fn.filereadable
            local old_readfile = vim.fn.readfile
            
            vim.fn.system = function(cmd) return "/fake/root\n" end
            vim.fn.filereadable = function() return 1 end
            vim.fn.readfile = function() return {"# Base Context"} end
            
            local written_path = ""
            local written_lines = {}
            vim.fn.writefile = function(lines, path)
                written_path = path
                written_lines = lines
                return 0
            end
            
            local res = tools.update_context_md("Nova Decisao: Usar LuaJIT")
            assert.are.equal("/fake/root/CONTEXT.md", written_path)
            assert.is_truthy(res:match("SUCESSO"))
            
            -- Deve ter anexado a nova linha ao contexto existente
            local found = false
            for _, l in ipairs(written_lines) do
                if l:match("Nova Decisao: Usar LuaJIT") then found = true end
            end
            assert.is_true(found, "O conteudo não foi anexado corretamente no arquivo.")
            
            vim.fn.system = old_system
            vim.fn.writefile = old_writefile
            vim.fn.filereadable = old_filereadable
            vim.fn.readfile = old_readfile
        end)
    end)

    describe("45.4: dynamic_watchdog.lua - The Harvester", function()
        it("deve construir o payload do Harvester pedindo a extração de fatos arquiteturais", function()
            local wd = require("multi_context.core.dynamic_watchdog")
            session.clear()
            session.add_message("user", "Corrija o bug de nil pointer no parser.", {})
            session.add_message("assistant", "Corrigido. Adicionei a regra de checar != nil antes.", {})
            
            local payload = wd.build_harvester_payload()
            assert.is_not_nil(payload)
            
            -- A primeira mensagem (system prompt) deve instruir a extrair regras/fatos
            assert.is_truthy(payload[1].content:match("fatos arquiteturais") or payload[1].content:match("regras"))
            
            -- A ultima mensagem (historico) deve conter a memoria da sessao atual
            assert.is_truthy(payload[#payload].content:match("checar %!= nil"))
        end)
    end)
end)
