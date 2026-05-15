#!/bin/bash

echo "🚀 Iniciando criação dos testes (Fase RED) para as Etapas 1 e 2 da Fase 48..."

# =====================================================================
# 1. Teste TDD: Guardrail de Paralelismo Git (Anti-Branching)
# =====================================================================
cat << 'EOF' >> lua/multi_context/tests/prompt_hardening_spec.lua

describe("Fase 48 - Swarm Guardrails e Anti-Branching:", function()
    it("O manual do spawn_swarm deve proibir estritamente paralelismo com branches do Git", function()
        local registry = require('multi_context.tools.registry')
        
        -- Força a leitura simulada passando a string de fallback ou lendo real
        local manual = registry.build_manual_for_skills({"spawn_swarm"})
        
        assert.truthy(manual:match("TERMINALLY FORBIDDEN"), "O manual de spawn_swarm deve conter a string TERMINALLY FORBIDDEN para maior peso.")
        
        local has_branch_guard = manual:match("git checkout") or manual:match("branch") or manual:match("branches")
        assert.truthy(has_branch_guard, "O manual deve proibir explicitamente operações paralelas envolvendo manipulação de branches.")
    end)
end)
EOF

echo "✅ Teste adicionado em: lua/multi_context/tests/prompt_hardening_spec.lua"

# =====================================================================
# 2. Teste TDD: UX Minimalista - O Carrossel de Abas do Swarm
# =====================================================================
cat << 'EOF' >> lua/multi_context/tests/chat_view_spec.lua

describe("Fase 48 - UX Minimalista do Carrossel de Abas do Swarm:", function()
    it("O título deve exibir apenas a aba Main e a aba do agente ativo", function()
        local config = require('multi_context.config')
        config.options.auto_inject_context_md = false -- simplifica a string gerada
        
        local popup = require('multi_context.ui.chat_view')
        local buf, win = popup.create_popup("Inicio")
        
        -- Simulando múltiplos buffers do swarm em andamento
        popup.swarm_buffers = {
            { buf = buf, name = "Main" },
            { buf = 2, name = "coder" },
            { buf = 3, name = "qa" },
            { buf = 4, name = "devops" }
        }
        
        -- Definindo a aba ativa do Swarm como a 3 ('qa')
        popup.current_swarm_index = 3
        
        -- Atualiza o título (este método deverá ser refatorado na fase GREEN)
        popup.update_title()
        
        -- Pegar o título que foi renderizado na janela
        local conf = vim.api.nvim_win_get_config(win)
        local title = (type(conf.title) == "table" and conf.title[1][1]) or conf.title or ""
        
        -- Asserts
        assert.truthy(title:match("Main") or title:match("%[1:Main%]"), "O título DEVE conter referência à aba Main.")
        assert.truthy(title:match("qa"), "O título DEVE conter o nome do worker atual (qa).")
        assert.falsy(title:match("coder"), "O título NÃO deve exibir abas inativas para economizar espaço visual (coder).")
        assert.falsy(title:match("devops"), "O título NÃO deve exibir abas inativas para economizar espaço visual (devops).")
    end)
end)
EOF

echo "✅ Teste adicionado em: lua/multi_context/tests/chat_view_spec.lua"
echo "-------------------------------------------------------------------"
echo "🎯 PRÓXIMO PASSO:"
echo "Execute seus testes. Eles devem FALHAR (Fase RED). Confirme as falhas para seguirmos com o script 'refactorate.sh' e resolvermos o código!"
