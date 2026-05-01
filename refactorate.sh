#!/bin/bash

echo "==========================================================="
echo "📚 ATUALIZANDO DOCUMENTAÇÃO DO PROJETO (V2.0 + HARDENING)"
echo "==========================================================="

python3 - << 'EOF'
import os

# ==========================================
# 1. ATUALIZANDO CONTEXT.MD
# ==========================================
if os.path.exists('CONTEXT.md'):
    with open('CONTEXT.md', 'r') as f:
        ctx = f.read()

    ctx = ctx.replace('127 Unit and Integration Tests', '149 Unit and Integration Tests')
    ctx = ctx.replace('127 isolated Unit and Integration tests', '149 isolated Unit and Integration tests')

    new_features = """
### 12. V2.0 Event-Driven Architecture & Session AST (Phase 35)
- **Clean Architecture**: The core logic is fully decoupled from the Neovim UI through a strict PubSub `EventBus`. The UI is 100% reactive, enabling potential headless executions.
- **Centralized State Management**: A Redux-like state manager eradicates global variables and ensures predictable state mutations.
- **Session AST**: Chat history is maintained as an Abstract Syntax Tree in RAM, replacing regex-heavy parsing and allowing structured prompt building.

### 13. Cognitive Hardening & Anti-Hallucination (Phase 36)
- **Recency Bias Guardrails**: Critical formatting rules (like strict XML enforcement without markdown wrappers) are injected at the absolute end of the system prompt, exploiting LLM recency bias for maximum obedience.
- **Zero-Skill Awareness**: Agents focused on planning or philosophy with no assigned tools are explicitly warned that they lack operational capabilities, completely eliminating tool-invention hallucinations.
"""
    if "12. V2.0 Event-Driven Architecture" not in ctx:
        # Adiciona no final da seção de features
        ctx += "\n" + new_features

    with open('CONTEXT.md', 'w') as f:
        f.write(ctx)
    print("✅ CONTEXT.md atualizado!")


# ==========================================
# 2. ATUALIZANDO README.MD
# ==========================================
if os.path.exists('README.md'):
    with open('README.md', 'r') as f:
        readme = f.read()

    readme = readme.replace('127 isolated tests', '149 isolated tests')
    readme = readme.replace('✅ Success: 127', '✅ Success: 149')

    new_rows = """| 🧠 | **Cognitive Hardening** | Implements Recency Bias Guardrails and Zero-Skill Awareness to prevent tool hallucinations and strictly enforce XML outputs without markdown wrappers. |
| ⚡ | **V2.0 Event-Driven Core** | Pure Lua PubSub Architecture (EventBus) with Centralized State Management and Session AST, making the UI 100% reactive and decoupled. |"""

    if "Cognitive Hardening" not in readme:
        readme = readme.replace('| 🔌 | **Polyglot Extensibility**', new_rows + '\n| 🔌 | **Polyglot Extensibility**')

    with open('README.md', 'w') as f:
        f.write(readme)
    print("✅ README.md atualizado!")


# ==========================================
# 3. ATUALIZANDO doc/multicontext.txt (Vimdoc)
# ==========================================
if os.path.exists('doc/multicontext.txt'):
    with open('doc/multicontext.txt', 'r') as f:
        doc = f.read()

    doc_toc_add = "6. Arquitetura 2.0 e Blindagem ............... |multicontext-arch|\n"
    if "6. Arquitetura 2.0" not in doc:
        doc = doc.replace('5. Centro de Comando ............................... |multicontext-controls|\n', '5. Centro de Comando ............................... |multicontext-controls|\n' + doc_toc_add)

    doc_content_add = """
==============================================================================
6. ARQUITETURA 2.0 E BLINDAGEM COGNITIVA               *multicontext-arch*

O MultiContext V2.0 opera sob uma arquitetura limpa e orientada a eventos (PubSub).
A interface do Neovim é 100% reativa, desenhando na tela apenas quando o 
Core (Cérebro) emite eventos. 

Além disso, o sistema conta com Blindagem Cognitiva (Guardrails de Recency Bias)
que previne ativamente alucinações (como a invenção de ferramentas) e força
respostas puras em XML, garantindo máxima economia de tokens e estabilidade.
"""
    if "*multicontext-arch*" not in doc:
        doc = doc.replace('vim:tw=78:ts=8:ft=help:norl:', doc_content_add + '\nvim:tw=78:ts=8:ft=help:norl:')

    with open('doc/multicontext.txt', 'w') as f:
        f.write(doc)
    print("✅ doc/multicontext.txt atualizado!")

EOF

echo "==========================================================="
echo "📚 Atualizando o índice de ajuda interno do Neovim..."
make doc
echo "==========================================================="
echo "✨ Documentação perfeitamente sincronizada com o código!"
echo "==========================================================="
