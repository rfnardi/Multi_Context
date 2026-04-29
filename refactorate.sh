#!/bin/bash

echo "==========================================================="
echo "🧹 FASE 4: SEPARAÇÃO FÍSICA DE DIRETÓRIOS (CLEAN ARCHITECTURE)"
echo "==========================================================="

python3 - << 'PY_EOF'
import os
import re
import shutil

base_dir = "lua/multi_context"

# 1. Criação das pastas de domínio
for d in ["core", "llm", "ecosystem", "ui", "utils"]:
    os.makedirs(os.path.join(base_dir, d), exist_ok=True)

# 2. Mapa exato de movimentações
moves = {
    "swarm_manager.lua": "core/swarm_manager.lua",
    "conversation.lua": "core/conversation.lua",
    "api_client.lua": "llm/api_client.lua",
    "api_handlers.lua": "llm/api_handlers.lua",
    "prompt_parser.lua": "llm/prompt_parser.lua",
    "transport.lua": "llm/transport.lua",
    "tools.lua": "ecosystem/tools.lua",
    "skills_manager.lua": "ecosystem/skills_manager.lua",
    "injectors.lua": "ecosystem/injectors.lua",
    "lsp_utils.lua": "ecosystem/lsp_utils.lua",
    "tool_parser.lua": "ecosystem/tool_parser.lua",
    "tool_runner.lua": "ecosystem/tool_runner.lua",
    "squads.lua": "ecosystem/squads.lua",
    "context_controls.lua": "ui/context_controls.lua",
    "memory_tracker.lua": "utils/memory_tracker.lua",
    "utils.lua": "utils/utils.lua",
    "context_builders.lua": "utils/context_builders.lua",
}

# 3. Executando a movimentação física dos arquivos
for old_file, new_file in moves.items():
    old_path = os.path.join(base_dir, old_file)
    new_path = os.path.join(base_dir, new_file)
    if os.path.exists(old_path):
        shutil.move(old_path, new_path)
        print(f"📦 Movido: {old_file} -> {new_file}")

# 4. Gerando as chaves de substituição (De->Para de Imports)
modules = {}
for old_file, new_file in moves.items():
    old_mod = "multi_context." + old_file.replace(".lua", "")
    new_mod = "multi_context." + new_file.replace(".lua", "").replace("/", ".")
    modules[old_mod] = new_mod

# Ordenando pelas strings mais longas para evitar colisões de prefixo
sorted_mods = sorted(modules.keys(), key=len, reverse=True)

def process_file(filepath):
    if not filepath.endswith(".lua") and not filepath.endswith(".md"):
        return
    with open(filepath, "r") as f:
        content = f.read()
    
    orig = content
    for old_mod in sorted_mods:
        new_mod = modules[old_mod]
        # Regex seguro: Substitui APENAS quando o caminho está entre aspas simples ou duplas.
        # Ex: require('multi_context.utils') -> require('multi_context.utils.utils')
        content = re.sub(r"(['\"])" + re.escape(old_mod) + r"(['\"])", r"\g<1>" + new_mod + r"\g<2>", content)
        
    if orig != content:
        with open(filepath, "w") as f:
            f.write(content)
        print(f"🔄 Requires atualizados em: {filepath}")

# 5. Aplicar o Regex em todos os arquivos .lua e testes
for root, _, files in os.walk(base_dir):
    for file in files:
        process_file(os.path.join(root, file))

print("\n✅ FASE 4 CONCLUÍDA: A Arquitetura Domain-Driven foi estabelecida com sucesso!")
PY_EOF
