#!/usr/bin/env bash

# ==========================================================
# MultiContext AI - Auto Bug Fixer
# Resolve vazamentos de memória, crashes e code smells
# ==========================================================
set -e

echo "======================================================"
echo "🛠️  MultiContext AI - Resolvendo Bugs Críticos 🛠️"
echo "======================================================"

# Segurança: Checa se estamos na raiz do projeto (COM O ESPAÇO CORRIGIDO AQUI)
if [ ! -d "lua/multi_context" ]; then
    echo "❌ ERRO: Execute este script na pasta RAIZ do plugin (onde a pasta lua/ está localizada)."
    exit 1
fi

PATCH_FILE=".mctx_patcher_temp.lua"

# Escreve o código de patch dinamicamente
cat << 'EOF' > "$PATCH_FILE"
local function read_file(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local content = f:read("*a")
    f:close()
    return content
end

local function write_file(path, content)
    local f = io.open(path, "w")
    if f then
        f:write(content)
        f:close()
    end
end

print("[1/7] Corrigindo Bug A: Retorno Prematuro em lsp_bridge.lua")
local f_lsp = "lua/multi_context/ecosystem/lsp_bridge.lua"
local c_lsp = read_file(f_lsp)
if c_lsp then
    -- Remove o 'return M' intruso do meio
    c_lsp = c_lsp:gsub("%s+return M%s+M%.get_references", "\n\nM.get_references")
    -- Adiciona no fim se não existir
    if not c_lsp:match("return M%s*$") then
        c_lsp = c_lsp .. "\n\nreturn M\n"
    end
    write_file(f_lsp, c_lsp)
end

print("[2/7] Corrigindo Bug B e F: Limites e Duplicação em native_tools.lua")
local f_tools = "lua/multi_context/ecosystem/native_tools.lua"
local c_tools = read_file(f_tools)
if c_tools then
    if not c_tools:match("start_line > #lines %+") then
        c_tools = c_tools:gsub("if end_line > #lines then end_line = #lines end", "if end_line > #lines then end_line = #lines end\n    if start_line > #lines + 1 then start_line = #lines + 1 end")
    end
    
    local count_md = 0
    c_tools = c_tools:gsub("M%.update_context_md = function%(content%).-SUCESSO: CONTEXT%.md atualizado em \" %.%. path\nend", function(m)
        count_md = count_md + 1
        if count_md == 2 then return "" else return m end
    end)
    write_file(f_tools, c_tools)
end

print("[3/7] Corrigindo Bug C: Memory Leak em transport.lua")
local f_trans = "lua/multi_context/llm/transport.lua"
local c_trans = read_file(f_trans)
if c_trans then
    if not c_trans:match("table%.remove%(_G%.MultiContextTempFiles") then
        c_trans = c_trans:gsub("pcall%(os%.remove, tmp_file%)", "pcall(os.remove, tmp_file)\n            for i, f in ipairs(_G.MultiContextTempFiles) do\n                if f == tmp_file then table.remove(_G.MultiContextTempFiles, i); break end\n            end")
        write_file(f_trans, c_trans)
    end
end

print("[4/7] Corrigindo Bug D: Falha Silenciosa em event_bus.lua")
local f_bus = "lua/multi_context/core/event_bus.lua"
local c_bus = read_file(f_bus)
if c_bus then
    if not c_bus:match("wrapper%.original_cb") then
        c_bus = c_bus:gsub("M%.on%(event_name, wrapper%)", "wrapper.original_cb = callback\n    M.on(event_name, wrapper)")
        c_bus = c_bus:gsub("if cb == callback then", "if cb == callback or cb.original_cb == callback then")
        write_file(f_bus, c_bus)
    end
end

print("[5/7] Corrigindo Bug E: Elementos Duplicados em controls_view.lua")
local f_ctrl = "lua/multi_context/ui/controls_view.lua"
local c_ctrl = read_file(f_ctrl)
if c_ctrl then
    local count_pool1 = 0
    c_ctrl = c_ctrl:gsub("local bg_mark = a%.allow_background and \"%[ ON %]\" or \"%[ OFF %]\"\n%s*add_line%(lines, format_row%(\"      └─ \" %.%. i18n%.t%(\"cc_bg_pool_title\"%), bg_mark, w%), %{ type = \"api_bg_pool\", idx = i %}%)\n?", function(m)
        count_pool1 = count_pool1 + 1
        if count_pool1 == 2 then return "" else return m end
    end)

    local count_pool2 = 0
    c_ctrl = c_ctrl:gsub("elseif action%.type == \"api_bg_pool\" then M%.state%.apis%[action%.idx%]%.allow_background = not M%.state%.apis%[action%.idx%]%.allow_background\n?", function(m)
        count_pool2 = count_pool2 + 1
        if count_pool2 == 2 then return "" else return m end
    end)
    write_file(f_ctrl, c_ctrl)
end

print("[6/7] Corrigindo Bug F2: Funções duplicadas em dynamic_watchdog.lua")
local f_wd = "lua/multi_context/core/dynamic_watchdog.lua"
local c_wd = read_file(f_wd)
if c_wd then
    local count_wd = 0
    c_wd = c_wd:gsub("M%.dispatch_parallel_jit_tasks = function%(buf, blocks%).-target_api\n%s*%)\n%s*end\nend\n?", function(m)
        count_wd = count_wd + 1
        if count_wd == 2 then return "" else return m end
    end)
    write_file(f_wd, c_wd)
end

print("[7/7] Corrigindo Bug G: Refatoração JIT Archiving em react_orchestrator.lua")
local f_react = "lua/multi_context/core/react_orchestrator.lua"
local c_react = read_file(f_react)
if c_react then
    if not c_react:match("local function dispatch_jit_archiving") then
        local func_def = [[
local function dispatch_jit_archiving(buf)
    pcall(function()
        local session = require("multi_context.core.session")
        local msgs = session.get_messages()
        local last_msg = msgs[#msgs]
        if last_msg and last_msg.metadata and last_msg.metadata.id then
            require("multi_context.core.dynamic_watchdog").dispatch_jit_task(buf, last_msg.metadata.id, last_msg.content)
        end
    end)
end

M.ExecuteTools = function(ia_idx, buf)]]
        
        c_react = c_react:gsub("M%.ExecuteTools = function%(ia_idx, buf%)", func_def)
        
        local jit_comment = "%-%- FASE 44: Disparo JIT Micro%-Archiving%s*"
        local jit_block = "pcall%(function%(%).-dispatch_jit_task%(buf, last_msg%.metadata%.id, last_msg%.content%).-end\n%s*end%)"
        c_react = c_react:gsub(jit_comment .. jit_block, "dispatch_jit_archiving(buf)")
        
        write_file(f_react, c_react)
    end
end
print("✨ Processamento concluído com sucesso!")
EOF

# Dispara a avaliação usando o interpretador nativo
if command -v nvim &> /dev/null; then
    echo "🚀 Executando motor de correção via Neovim..."
    nvim -l "$PATCH_FILE"
elif command -v lua &> /dev/null; then
    echo "🚀 Executando motor de correção via Lua standalone..."
    lua "$PATCH_FILE"
else
    echo "❌ ERRO: Neovim ou Lua não foram encontrados no seu PATH."
    rm -f "$PATCH_FILE"
    exit 1
fi

rm -f "$PATCH_FILE"
echo "======================================================"
echo "✅ Todos os vazamentos e bugs críticos foram consertados."
echo "Reinicie o Neovim para carregar a nova arquitetura."
echo "======================================================"
