#!/bin/bash

echo "🔧 Corrigindo teste de integração (Tech Lead Agent)..."

# Atualizamos a string de busca na asserção do teste para a nova topologia semântica
sed -i '60,80s/"spawn_swarm"/"swarm_orchestration"/g' lua/multi_context/tests/swarm_etapa1_spec.lua
sed -i "60,80s/'spawn_swarm'/'swarm_orchestration'/g" lua/multi_context/tests/swarm_etapa1_spec.lua

# Para garantir caso a mensagem de erro do assert também cite a skill antiga
sed -i '60,80s/skill spawn_swarm/skill swarm_orchestration/g' lua/multi_context/tests/swarm_etapa1_spec.lua

echo "✅ Teste do @tech_lead atualizado para procurar por 'swarm_orchestration'!"
echo "Isso resolverá a última ponta de compatibilidade com testes mecanicistas antigos! 🚀"
