#!/bin/bash

echo "==========================================================="
echo "🐛 CORRIGINDO O BUG DO 'a' NOS MENUS (AGENTS & INJECTORS)"
echo "==========================================================="

python3 - << 'EOF'
import os

files =[
    "lua/multi_context/agents.lua",
    "lua/multi_context/ecosystem/injectors.lua"
]

for filepath in files:
    if os.path.exists(filepath):
        with open(filepath, "r") as f:
            content = f.read()
        
        # Substitui a injeção manual da tecla "a" pela chamada limpa da API
        if 'api.nvim_feedkeys("a", "n", true)' in content:
            content = content.replace('api.nvim_feedkeys("a", "n", true)', 'vim.cmd("startinsert")')
            with open(filepath, "w") as f:
                f.write(content)
            print(f"✅ Bug do 'a' corrigido em {filepath}")
        else:
            print(f"⚠️ Chamada de feedkeys não encontrada em {filepath} (talvez já corrigida).")
    else:
        print(f"⚠️ Arquivo não encontrado: {filepath}")

EOF

echo "==========================================================="
echo "✅ Pronto! Teste abrir o menu com @ ou \ e verifique se o"
echo "texto é inserido perfeitamente sem letras extras no final."
echo "==========================================================="
