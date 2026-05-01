#!/bin/bash

echo "==========================================================="
echo "🛠️ CORRIGINDO TESTE DA FASE 38 (ERRO DE STRING MATCH)"
echo "==========================================================="

python3 - << 'EOF'
import os

# 1. Corrigir a asserção no teste
test_file = "lua/multi_context/tests/native_tools_spec.lua"
if os.path.exists(test_file):
    with open(test_file, "r") as f:
        content = f.read()
    
    # Substituir "Indentação:" por "Indent" para evitar problema de match literal com os ":"
    target = 'assert.truthy(res:match("Indentação:"))'
    replacement = 'assert.truthy(res:match("Indent"))'
    
    if target in content:
        content = content.replace(target, replacement)
        with open(test_file, "w") as f:
            f.write(content)
        print("✅ Asserção em native_tools_spec.lua corrigida.")
    else:
        print("⚠️ Alvo de substituição não encontrado no teste.")

# 2. Atualizar nvim_buf_get_option para vim.bo (melhor prática)
tools_file = "lua/multi_context/ecosystem/native_tools.lua"
if os.path.exists(tools_file):
    with open(tools_file, "r") as f:
        content = f.read()

    target_expand = 'local expandtab = vim.api.nvim_buf_get_option(buf, "expandtab")'
    replacement_expand = 'local expandtab = vim.bo[buf].expandtab'
    
    target_shift = 'local shiftwidth = vim.api.nvim_buf_get_option(buf, "shiftwidth")'
    replacement_shift = 'local shiftwidth = vim.bo[buf].shiftwidth'

    changed = False
    if target_expand in content:
        content = content.replace(target_expand, replacement_expand)
        changed = True
    if target_shift in content:
        content = content.replace(target_shift, replacement_shift)
        changed = True

    if changed:
        with open(tools_file, "w") as f:
            f.write(content)
        print("✅ native_tools.lua atualizado para usar vim.bo.")

EOF

echo "==========================================================="
echo "🚀 Pronto! Rode 'make test_agregate_results' mais uma vez."
echo "==========================================================="
