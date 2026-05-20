#!/usr/bin/env bash

echo "🛠️ Caçando as últimas atribuições literais (chain = ...) na base de código..."

# Substitui 'chain =' por 'queue =' (com ou sem espaços) em todos os arquivos Lua
find lua/multi_context -type f -name "*.lua" -exec sed -i 's/chain[ \t]*=/queue =/g' {} +
find lua/multi_context -type f -name "*.lua" -exec sed -i 's/chain[ \t]*:/queue :/g' {} +

# Opcional: Para ter certeza de que o teste não travou o arquivo de cache no seu PC local,
# removemos o mock residual gerado no teste (se existir na raiz)
if [ -f "mctx_squads.json" ]; then
    rm mctx_squads.json
fi

echo "✅ Atribuições de tabelas Lua corrigidas!"
echo "Rode 'make test' uma última vez. Agora as tabelas vão compilar para 'queue' no JSON!"
