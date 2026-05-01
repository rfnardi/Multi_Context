#!/bin/bash

echo "==========================================================="
echo "🩹 ATUALIZANDO TESTES PARA A ARQUITETURA V2.0"
echo "==========================================================="

python3 - << 'EOF'
import os

def patch_file(filepath, replacements):
    if not os.path.exists(filepath):
        print(f"Arquivo não encontrado: {filepath}")
        return
        
    with open(filepath, 'r') as f:
        content = f.read()
        
    original = content
    for old, new in replacements:
        content = content.replace(old, new)
        
    if content != original:
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"✅ Teste corrigido: {filepath}")

# 1. global_flags_spec.lua
patch_file('lua/multi_context/tests/global_flags_spec.lua', [
    ("require('multi_context.core.react_orchestrator').ProcessTurn()", "require('multi_context.core.react_orchestrator').ProcessTurn(buf)"),
    ("before_each(function()", "before_each(function()\n        require('multi_context.config').options.user_name = \"Nardi\"")
])

# 2. integration_spec.lua
patch_file('lua/multi_context/tests/integration_spec.lua', [
    ("require('multi_context.core.react_orchestrator').ProcessTurn()", "require('multi_context.core.react_orchestrator').ProcessTurn(popup.popup_buf)")
])

# 3. init_tracker_spec.lua
patch_file('lua/multi_context/tests/init_tracker_spec.lua', [
    ("require('multi_context.core.react_orchestrator').ProcessTurn()", "require('multi_context.core.react_orchestrator').ProcessTurn(buf)"),
    ("before_each(function()", "before_each(function()\n        config.options.user_name = \"Nardi\"")
])

# 4. watchdog_spec.lua
patch_file('lua/multi_context/tests/watchdog_spec.lua', [
    ("require('multi_context.core.react_orchestrator').ProcessTurn()", "require('multi_context.core.react_orchestrator').ProcessTurn(buf)"),
    ("before_each(function()", "before_each(function()\n        config.options.user_name = \"Nardi\"")
])

EOF

echo "==========================================================="
echo "🚀 Pronto! Rode 'make test_agregate_results'."
echo "==========================================================="
