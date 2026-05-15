#!/bin/bash

echo "🔧 Atualizando teste legado da Fase 18.5 para a nova arquitetura AST..."

lua - << 'EOF'
local file = "lua/multi_context/tests/session_spec.lua"
local f = io.open(file, "r")
if not f then 
    print("⚠️ Arquivo não encontrado: " .. file)
    os.exit(0)
end

local content = f:read("*a")
f:close()

-- Atualizamos a asserção que procurava estritamente por "<swarm_state>"
-- para procurar pelo novo padrão Polimórfico de Bloco.
local new_content = content:gsub('match%(%s*["\']<swarm_state>["\']%s*%)', "match('<block[^>]+type=\"swarm\"')")

f = io.open(file, "w")
f:write(new_content)
f:close()

print("✅ [Fix] Teste session_spec.lua compatibilizado com a Fase 48!")
EOF

echo "-------------------------------------------------------------------"
echo "🚀 TUDO PRONTO! Rode a sua suíte de testes pela última vez!"
