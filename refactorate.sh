#!/bin/bash

echo "==========================================================="
echo "🩹 CORRIGINDO OS TESTES DE RENDERIZAÇÃO DOS MENUS (CLAMPING)"
echo "==========================================================="

python3 - << 'EOF'
import os

filepath = "lua/multi_context/tests/ui_menus_spec.lua"
if os.path.exists(filepath):
    with open(filepath, "r") as f:
        content = f.read()

    # Correção para o Módulo agents.lua
    old_agents = """        it("Deve renderizar a lista corretamente com o cursor apontando para a selecao", function()
            agents.selector_buf = vim.api.nvim_create_buf(false, true)
            agents.current_selection = 2"""

    new_agents = """        it("Deve renderizar a lista corretamente com o cursor apontando para a selecao", function()
            agents.selector_buf = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_buf_set_lines(agents.selector_buf, 0, -1, false, { "> ", "---" })
            agents.current_selection = 2"""

    # Correção para o Módulo injectors.lua
    old_injectors = """        it("Deve renderizar a lista de injetores corretamente", function()
            injectors.selector_buf = vim.api.nvim_create_buf(false, true)
            injectors.current_selection = 1"""

    new_injectors = """        it("Deve renderizar a lista de injetores corretamente", function()
            injectors.selector_buf = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_buf_set_lines(injectors.selector_buf, 0, -1, false, { "> ", "---" })
            injectors.current_selection = 1"""

    changed = False
    if old_agents in content:
        content = content.replace(old_agents, new_agents)
        changed = True
    
    if old_injectors in content:
        content = content.replace(old_injectors, new_injectors)
        changed = True

    if changed:
        with open(filepath, "w") as f:
            f.write(content)
        print("✅ ui_menus_spec.lua ajustado: os buffers agora inicializam com o header padrão (> e ---) previnindo Index Clamping.")
    else:
        print("⚠️ Trechos não encontrados. Verifique a formatação do arquivo de teste.")
else:
    print(f"⚠️ Arquivo {filepath} não encontrado.")
EOF

echo "==========================================================="
echo "🚀 Pronto! Rode 'make test_agregate_results' mais uma vez."
echo "A marca dos 200+ testes no verde absoluto deve ser atingida agora!"
echo "==========================================================="
