local hl = require('multi_context.ui.highlights')
local chat_view = require('multi_context.ui.chat_view')

describe("Fase 43.5: Visual Engine & Ontology Conceal/Folds", function()
    it("deve conter regras de conceal para as tags de ontologia (abstract, content, etc)", function()
        local buf = vim.api.nvim_create_buf(false, true)
        
        local cmds = {}
        local orig_cmd = vim.cmd
        vim.cmd = function(cmd_str)
            table.insert(cmds, cmd_str)
            pcall(orig_cmd, cmd_str)
        end
        
        hl.apply_chat(buf)
        vim.cmd = orig_cmd
        
        local found_ontology_tags = false
        for _, c in ipairs(cmds) do
            if c:match('ContextOntologyTag') and c:match('conceal') then
                found_ontology_tags = true
            end
        end
        
        assert.truthy(found_ontology_tags, "As novas tags XML (abstract, content) não estão sendo ocultadas (conceal)!")
    end)

    it("deve gerar fold de 1 linha amigavel para as regioes de <abstract>", function()
        local original_v = vim.v
        -- Simulamos o Neovim lendo o texto do fold de um Abstract
        vim.v = { foldstart = 1, foldend = 4 }
        
        -- Simulando um bloco abstract de 4 linhas
        vim.fn.getline = function(i)
            if i == 1 then return "<abstract>" end
            if i == 2 then return "<key_words>python, test</key_words>" end
            if i == 3 then return "<summary>Test summary</summary>" end
            if i == 4 then return "</abstract>" end
            return ""
        end
        
        local text = chat_view.fold_text()
        
        -- O foldtext deve detectar inteligentemente se é um abstract ou arquivo morto
        assert.truthy(text:match("🧠") or text:match("📦"), "O texto do fold não conteve o ícone esperado.")
        -- O fold_text extrai o resumo automaticamente tirando as tags, devendo sobrar "Test summary"
        assert.truthy(text:match("Test summary"), "O texto do fold não expôs o summary!")
        
        vim.v = original_v
    end)
end)
