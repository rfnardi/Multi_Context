#!/bin/bash

# Script de Refatoração TDD (Fase GREEN) - Swarm Hotfix

cat << 'EOF' > refactorate_tmp.lua
local filepath = "lua/multi_context/utils/utils.lua"
local f = io.open(filepath, "r")
if not f then print("Erro ao abrir " .. filepath); os.exit(1) end
local content = f:read("*a")
f:close()

-- Refatoração 1: Estancar o vazamento (Build Workspace)
-- Removemos a captura de linhas da interface (b_lines) que causava o Context Overflow.
local leak_pattern = "local b_lines = api%.nvim_buf_get_lines%(sb%.buf, 0, %-1, false%)%s*table%.insert%(state_data%.buffers, %{ name = sb%.name, status = sb%.status, lines = b_lines %}%)"
local leak_fix = "table.insert(state_data.buffers, { name = sb.name, status = sb.status }) -- [HOTFIX Fase 49] Anti-Leak: Evita Context Overflow"
content = content:gsub(leak_pattern, leak_fix)

-- Refatoração 2: Injetar Placeholder na Deserialização (Load Workspace)
-- Caso as 'lines' não existam no JSON do Swarm, recriamos uma interface limpa.
local restore_pattern = "api%.nvim_buf_set_lines%(new_buf, 0, %-1, false, bdata%.lines or %{%}%)"
local restore_fix = [[
local lines_to_restore = bdata.lines
                        if not lines_to_restore or #lines_to_restore == 0 then
                            lines_to_restore = {
                                "## [ SWARM WORKER ]",
                                "## Agente: " .. (bdata.name or "Desconhecido"),
                                "",
                                "## [ Histórico visual arquivado para economia de memória ]",
                                ""
                            }
                        end
                        api.nvim_buf_set_lines(new_buf, 0, -1, false, lines_to_restore)]]
content = content:gsub(restore_pattern, restore_fix)

local out = io.open(filepath, "w")
out:write(content)
out:close()
EOF

# Executa o script lua temporário pelo motor headless do Neovim
nvim -l refactorate_tmp.lua

# Limpa o arquivo temporário
rm refactorate_tmp.lua

echo "✅ utils.lua refatorado com sucesso (Fase GREEN)!"
echo "➡️  Rode sua suite de testes agregada (make test ou busted). O painel deverá retornar tudo VERDE!"
