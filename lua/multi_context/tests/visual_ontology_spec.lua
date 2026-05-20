require("multi_context.tests.libuv_barrier")
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
        
        assert.truthy(found_ontology_tags, "As novas tags XML não estão sendo ocultadas (conceal)!")
    end)

    it("deve gerar fold de 1 linha amigavel para as regioes de <abstract>", function()
        local original_v = vim.v
        local original_getline = vim.fn.getline
        
        vim.v = { foldstart = 1, foldend = 4 }
        vim.fn.getline = function(i)
            if i == 1 then return "<abstract>" end
            if i == 2 then return "<key_words>python, test</key_words>" end
            if i == 3 then return "<summary>Test summary</summary>" end
            if i == 4 then return "</abstract>" end
            return ""
        end
        
        local text = chat_view.fold_text()
        
        vim.v = original_v
        vim.fn.getline = original_getline
        
        assert.truthy(text:match("") or text:match(""), "O texto do fold não conteve o resumo esperado.")
        assert.truthy(text:match("Test summary"), "O texto do fold não expôs o summary!")
    end)
end)
