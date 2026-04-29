#!/bin/bash

echo "==========================================================="
echo "🐛 CORRIGINDO O BUG DO GSUB EM LUA"
echo "==========================================================="

python3 - << 'EOF'
import os

filepath = "lua/multi_context/core/intent_parser.lua"
with open(filepath, "r") as f:
    content = f.read()

target = 'table.insert(cleaned_lines, line:gsub("%s*%-%-queue", ""):gsub("%s*%-%-moa", ""))'
replacement = 'table.insert(cleaned_lines, (line:gsub("%s*%-%-queue", ""):gsub("%s*%-%-moa", "")))'

if target in content:
    content = content.replace(target, replacement)
    with open(filepath, "w") as f:
        f.write(content)
    print("✅ Bug do string.gsub() com múltiplos retornos isolado por parênteses!")
else:
    print("⚠️ Target não encontrado no intent_parser.lua")
EOF

echo "==========================================================="
echo "🧪 Executando os Testes Novamente (Rumo aos 141!)..."
echo "==========================================================="
