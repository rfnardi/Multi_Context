#!/bin/bash

# Script BDD/TDD para injetar os testes da Fase 49 no arquivo utils_spec.lua

TEST_FILE="lua/multi_context/tests/utils_spec.lua"

# Adiciona o novo bloco describe ao final do arquivo utils_spec.lua
cat << 'EOF' >> "$TEST_FILE"

describe("Fase 49 - Hotfix de Serialização Crítica (Anti-Leak):", function()
    before_each(function()
        require('multi_context.core.swarm_manager').reset()
        local popup = require('multi_context.ui.chat_view')
        popup.swarm_buffers = nil
    end)

    it("O JSON do Swarm não deve conter logs visuais (Context Overflow fix)", function()
        local utils = require('multi_context.utils.utils')
        
        -- Buffer principal
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"Linha do chat 1", "Linha do chat 2"})
        
        -- Buffer do Swarm simulando um log visual GIGANTE (vazamento)
        local mock_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(mock_buf, 0, -1, false, {"LOG GIGANTE 1", "LOG GIGANTE 2", "LOG GIGANTE 3"})
        
        -- Simulando o estado aberto da UI
        local popup = require('multi_context.ui.chat_view')
        popup.swarm_buffers = { 
            { buf = buf, name = "Main" }, 
            { buf = mock_buf, name = "coder", status = "Rodando" } 
        }
        
        local _, content = utils.build_workspace_content(buf, "chat_2026.mctx")
        
        local json_str = content:match('<content>%s*(.-)%s*</content>')
        assert.truthy(json_str, "O JSON de estado do Swarm deve ser gerado na AST")
        
        local decoded = vim.fn.json_decode(json_str)
        assert.truthy(decoded.buffers[1], "O metadado do buffer deve estar serializado")
        assert.are.same("coder", decoded.buffers[1].name)
        
        -- ASSERÇÃO CRÍTICA (TDD: DEVE FALHAR AGORA): A chave 'lines' não deve existir ou deve estar vazia
        assert.falsy(decoded.buffers[1].lines, "A chave 'lines' NÃO DEVE existir no payload JSON para evitar Context Overflow!")
    end)

    it("Deve restaurar a UI do Swarm com Placeholder Semântico Econômico", function()
        local utils = require('multi_context.utils.utils')
        local popup = require('multi_context.ui.chat_view')
        
        local buf = vim.api.nvim_create_buf(false, true)
        
        -- Simulando um workspace carregado do disco, agora SEM a chave 'lines'
        local mock_mctx = [[
<mctx_session id="999" />
<block id="sw_1" type="swarm" status="running">
<content>
{"queue": [], "reports": [], "buffers": [{"name": "devops", "status": "Restaurado"}]}
</content>
</block>
]]
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(mock_mctx, "\n"))
        
        -- Executa a hidratação da UI
        utils.load_workspace_state(buf)
        
        assert.truthy(popup.swarm_buffers, "O sistema deveria recriar os swarm_buffers")
        
        -- Pega o buffer recriado do agente "devops"
        local restored_buf = popup.swarm_buffers[1].buf
        local lines = vim.api.nvim_buf_get_lines(restored_buf, 0, -1, false)
        local content_str = table.concat(lines, "\n")
        
        -- ASSERÇÃO CRÍTICA (TDD: DEVE FALHAR AGORA): Verifica se o placeholder foi injetado
        assert.truthy(
            content_str:match("Histórico visual arquivado para economia de memória"), 
            "Deve injetar o placeholder semântico para avisar o usuário que a UI foi limpa!"
        )
    end)
end)
EOF

echo "✅ Testes da Fase 49 injetados com sucesso em lua/multi_context/tests/utils_spec.lua!"
echo "➡️  Rode sua suite de testes agora. Os testes DEVERÃO FALHAR (Fase RED do TDD)."
