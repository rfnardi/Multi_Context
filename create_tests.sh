#!/bin/bash

echo "🛡️ Criando Bateria de Testes de Regressão (I/O e Visual)..."

# =====================================================================
# 1. Teste de Regressão: Sandbox de I/O (Prevenção do Erro E482)
# =====================================================================
cat << 'EOF' > lua/multi_context/tests/regression_io_sandbox_spec.lua
require("multi_context.tests.libuv_barrier")
local native_tools = require('multi_context.ecosystem.native_tools')

describe("Regression - I/O Sandbox e Prevenção de E482:", function()
    local orig_writefile
    
    before_each(function()
        orig_writefile = vim.fn.writefile
    end)
    
    after_each(function()
        -- Restore-Before-Assert: Garante que o Neovim não fique quebrado
        vim.fn.writefile = orig_writefile
    end)

    it("NUNCA deve crashar o Neovim se a escrita falhar (Ex: Permission Denied)", function()
        -- Mockamos a função nativa do C/VimL para forçar a simulação de uma falha de Kernel (E482)
        vim.fn.writefile = function()
            error("Vim:E482: Can't open file for writing: permission denied")
        end

        -- Simulamos a IA tentando editar um arquivo
        -- Se o Auto-Sandbox não estivesse lá, essa linha causaria um Crash Fatal no Neovim.
        local result = native_tools.edit_file({ 
            attributes = { path = "/pasta_proibida_do_sistema/arquivo.txt" }, 
            content = "hack" 
        })

        -- Assegura que o sistema engoliu a exceção e devolveu como string de texto para o LLM
        assert.truthy(type(result) == "string", "O Sandbox DEVE converter a explosão de I/O em uma string segura.")
        assert.truthy(result:match("FATAL TOOL ERROR"), "O erro retornado à IA deve conter o aviso crítico do Sandbox.")
        assert.truthy(result:match("Permission Denied"), "O erro deve detalhar o motivo da recusa do Kernel.")
    end)
end)
EOF

echo "✅ Teste de Regressão I/O criado em: lua/multi_context/tests/regression_io_sandbox_spec.lua"

# =====================================================================
# 2. Teste de Regressão: UI Folds para o Swarm
# =====================================================================
cat << 'EOF' > lua/multi_context/tests/regression_ui_swarm_fold_spec.lua
require("multi_context.tests.libuv_barrier")
local chat_view = require('multi_context.ui.chat_view')

describe("Regression - Swarm UI Folds (Anti-Vazamento Visual):", function()
    local orig_cmd
    
    before_each(function()
        orig_cmd = vim.cmd
    end)
    
    after_each(function()
        vim.cmd = orig_cmd
    end)

    it("Deve gerar os comandos corretos de 'fold' do Neovim para os blocos do Enxame", function()
        local buf = vim.api.nvim_create_buf(false, true)
        
        -- Injetando um JSON gigante de Swarm no buffer (como a IA faz)
        local mock_swarm_block = {
            '<block id="sw_1" type="swarm" status="running">',
            '<content>',
            '{"gigante": "JSON", "memoria": "vazando"}',
            '</content>',
            '</block>'
        }
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, mock_swarm_block)
        
        -- Mockamos o vim.cmd para interceptarmos as ordens de 'fold' nativas disparadas
        local fold_commands_issued = ""
        vim.cmd = function(cmd)
            if type(cmd) == "string" and cmd:match("fold") then
                fold_commands_issued = fold_commands_issued .. " | " .. cmd
            else
                pcall(orig_cmd, cmd) -- deixa outras coisas (como normal! zE) passarem
            end
        end
        
        -- Aciona o motor visual
        chat_view.create_folds(buf)
        
        -- Força o event loop a processar o vim.schedule de dentro do create_folds
        vim.wait(50, function() return fold_commands_issued ~= "" end)
        
        -- Asserções: O motor DEVE dobrar do início da tag (1) até o fechamento (5)
        assert.truthy(fold_commands_issued:match("1,5fold"), "O motor de UI DEVE agrupar o bloco Swarm em uma dobra de código.")
        assert.truthy(fold_commands_issued:match("1foldclose"), "O motor de UI DEVE fechar a dobra automaticamente para proteger a visão do usuário.")
    end)
end)
EOF

echo "✅ Teste de Regressão UI criado em: lua/multi_context/tests/regression_ui_swarm_fold_spec.lua"
echo "-------------------------------------------------------------------"
echo "🚀 Bateria de Testes de Regressão instalada com sucesso!"
echo "Rode a sua suíte de testes (ex: make test). O painel deve acusar 100% de sucesso validando nossa proteção atual."
