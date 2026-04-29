#!/bin/bash

echo "======================================================================"
echo "🧪 Executando Suíte Completa de Testes (Isolamento Plenary)..."
echo "======================================================================"

# Roda o Plenary capturando stdout e stderr
OUTPUT=$(nvim --headless -i NONE -c "PlenaryBustedDirectory lua/multi_context/tests/" 2>&1)

# Imprime a saída original colorida no terminal para você ler normalmente
echo "$OUTPUT"

# Remove todos os caracteres invisíveis de cores ANSI da saída
CLEAN_OUTPUT=$(echo "$OUTPUT" | sed "s/$(printf '\033')\\[[0-9;]*[mK]//g")

# Extrai os números pelo padrão ignorando espaços (agora livre de lixo ANSI)
SUCCESS=$(echo "$CLEAN_OUTPUT" | grep -iE "Success\s*:" | awk -F: '{print $2}' | awk '{sum+=$1} END {print sum+0}')
FAILED=$(echo "$CLEAN_OUTPUT"  | grep -iE "Failed\s*:"  | awk -F: '{print $2}' | awk '{sum+=$1} END {print sum+0}')
ERRORS=$(echo "$CLEAN_OUTPUT"  | grep -iE "Errors\s*:"  | awk -F: '{print $2}' | awk '{sum+=$1} END {print sum+0}')

echo ""
echo "======================================================================"
echo "📊 RESUMO GLOBAL AGREGADO (MULTI-CONTEXT)"
echo "======================================================================"
echo "✅ Success: $SUCCESS"
echo "❌ Failed : $FAILED"
echo "💥 Errors : $ERRORS"
echo "======================================================================"

if [ "$FAILED" -gt 0 ] || [ "$ERRORS" -gt 0 ]; then
    exit 1
fi
exit 0
