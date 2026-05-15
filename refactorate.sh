#!/bin/bash
set -e

echo "🛠️ 1. Criando Spec de Teste Isolado para o Gatekeeper do Swarm..."

cat << 'EOF' > lua/multi_context/tests/swarm_gatekeeper_spec.lua
local assert = require("luassert")
local tool_runner = require("multi_context.ecosystem.tool_runner")
local StateManager = require("multi_context.core.state_manager")

describe("Swarm Gatekeeper Fix", function()
    before_each(function()
        StateManager.reset()
    end)

    it("tool_runner.execute DEVE aceitar active_agent_override para Sub-Agentes do Swarm", function()
        -- Mocks locais: tech_lead não tem ferramentas. devops tem git.
        local agents = {
            tech_lead = { skills = {} },
            devops = { skills = {"git_automation"} }
        }
        
        local mock_ontology = {
            resolve_agent_skills = function(skills)
                if skills and skills[1] == "git_automation" then
                    return { tools_set = { get_git_env = true } }
                end
                return { tools_set = {} }
            end
        }
        
        -- Injeção no package.loaded
        package.loaded["multi_context.agents"] = { load_agents = function() return agents end }
        package.loaded["multi_context.ecosystem.ontology"] = mock_ontology
        
        -- Simulando que o estado global React ainda é o Tech Lead
        StateManager.patch("react", { active_agent = "tech_lead" })
        
        local tool_data = { name = "get_git_env", inner = "" }
        local ref = { value = true }
        
        -- Teste A (Bug Antigo): Sem override, DEVE negar (Tech Lead não pode rodar Git)
        local out_denied = tool_runner.execute(tool_data, true, ref, 1)
        assert.truthy(out_denied:match("Operação negada"))
        
        -- Teste B (Nova Funcionalidade): Com override do Swarm, DEVE autorizar o Devops
        local out_allowed = tool_runner.execute(tool_data, true, ref, 1, "devops")
        assert.falsy(out_allowed:match("Operação negada"))
        
        -- Cleanup
        package.loaded["multi_context.agents"] = nil
        package.loaded["multi_context.ecosystem.ontology"] = nil
    end)
end)
EOF

echo "✨ 2. Aplicando Patches Cirúrgicos nos Módulos..."

cat << 'EOF' > fix_swarm_bugs.py
import os

# --- Correção 1: tool_runner.lua ---
tr_path = "lua/multi_context/ecosystem/tool_runner.lua"
with open(tr_path, "r") as f:
    tr_content = f.read()

tr_content = tr_content.replace(
    "M.execute = function(tool_data, is_autonomous, approve_all_ref, buf)",
    "M.execute = function(tool_data, is_autonomous, approve_all_ref, buf, active_agent_override)"
)
tr_content = tr_content.replace(
    "local active_agent = StateManager.get('react').active_agent",
    "local active_agent = active_agent_override or StateManager.get('react').active_agent"
)

with open(tr_path, "w") as f:
    f.write(tr_content)

# --- Correção 2: swarm_manager.lua ---
sm_path = "lua/multi_context/core/swarm_manager.lua"
with open(sm_path, "r") as f:
    sm_content = f.read()

sm_content = sm_content.replace(
    "local tag_out = tool_runner.execute(parsed, true, approve_ref, buf_id)",
    "local tag_out = tool_runner.execute(parsed, true, approve_ref, buf_id, task.agent)"
)

# Refatorando o bug de Loop Duplo do Switch Count
buggy_loop_logic = """                                local switch_target = new_content:match("SWITCH_AGENT_REQUEST:([%w_]+)")
                                task.switch_count = (task.switch_count or 0) + 1
                                if task.switch_count > 3 then switch_target = nil; new_content = "FATAL ERROR: Loop infinito de troca de agente detectado." end
                                task.switch_count = (task.switch_count or 0) + 1
                                if task.switch_count > 3 then switch_target = nil; new_content = "FATAL ERROR: Loop infinito de troca de agente detectado (limite de 3) excedido." end
                                if switch_target then"""

fixed_loop_logic = """                                local switch_target = new_content:match("SWITCH_AGENT_REQUEST:([%w_]+)")
                                
                                task.turn_count = (task.turn_count or 0) + 1
                                if task.turn_count > 15 then
                                    new_content = "FATAL ERROR: Limite máximo de 15 turnos autônomos excedido no Swarm."
                                    switch_target = nil
                                end
                                
                                if switch_target then
                                    task.switch_count = (task.switch_count or 0) + 1
                                    if task.switch_count > 3 then 
                                        switch_target = nil
                                        new_content = "FATAL ERROR: Loop infinito de troca de agente detectado (limite de 3) excedido." 
                                    end
                                end
                                
                                if switch_target then"""

sm_content = sm_content.replace(buggy_loop_logic, fixed_loop_logic)

with open(sm_path, "w") as f:
    f.write(sm_content)

print("✅ Arquivos tool_runner.lua e swarm_manager.lua corrigidos com sucesso.")
EOF

python3 fix_swarm_bugs.py
rm fix_swarm_bugs.py

echo "🧪 3. Executando a Suíte de Testes Agregada..."
make test_agregate_results
