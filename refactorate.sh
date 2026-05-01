#!/bin/bash

echo "==========================================================="
echo "🩹 CORRIGINDO TESTES DA FASE 35 (REGISTRY E SWARM MANAGER)"
echo "==========================================================="

python3 - << 'PY_EOF'
import os
import re

def find_file(filename):
    for root, _, files in os.walk("lua/multi_context"):
        if filename in files: return os.path.join(root, filename)
    return None

# =====================================================================
# 1. FIX: Otimização Extrema de Tokens no Registry (prompt_optimization_spec)
# =====================================================================
registry_path = find_file("registry.lua")
if registry_path:
    with open(registry_path, "r") as f: content = f.read()
    
    # Vamos substituir tudo entre o SYSTEM TOOLS e ACTIVE SKILLS por uma versão ultracurta
    pattern = r"local manual = \[\[=== SYSTEM TOOLS & SYNTAX.*?=== ACTIVE SKILLS ===\]\]"
    
    hyper_synthetic_manual = """local manual = [[=== SYSTEM TOOLS & SYNTAX (CRITICAL) ===
STRICT XML ONLY: <tool_call name="name" attr="val">
NO inventing tools/tags. NO Markdown wrapping (```xml).
ONE action per turn. Auto-LSP active: DO NOT call get_diagnostics after edits.
=== ACTIVE SKILLS ===]]"""

    if re.search(pattern, content, re.DOTALL):
        content = re.sub(pattern, hyper_synthetic_manual, content, flags=re.DOTALL)
        with open(registry_path, "w") as f: f.write(content)
        print("✅ prompt_optimization_spec corrigido: Manual base sintetizado para < 280 chars.")
    else:
        print("⚠️ Padrão não encontrado no registry.lua")

# =====================================================================
# 2. FIX: Exigência do Git no Relatório do Swarm (git_tools_spec)
# =====================================================================
swarm_path = find_file("swarm_manager.lua")
if swarm_path:
    with open(swarm_path, "r") as f: content = f.read()
    
    # Injetar a obrigatoriedade do Git no <final_report> da instrução inicial do Swarm
    old_str = "ALWAYS conclude with <final_report>.\""
    new_str = "ALWAYS conclude with <final_report>. The report MUST include a clear summary of what was done, the edited files, and list in a structured way the executed Git operations (if any).\""
    
    if old_str in content:
        content = content.replace(old_str, new_str)
        with open(swarm_path, "w") as f: f.write(content)
        print("✅ git_tools_spec corrigido: Swarm Manager agora cobra explicitamente operações Git no <final_report>.")
    else:
        print("⚠️ Padrão não encontrado no swarm_manager.lua")

PY_EOF

echo "==========================================================="
echo "Concluído! Rode 'make test_agregate_results' para verificar."
echo "==========================================================="
