#!/bin/bash

# Adiciona a vírgula que faltou nas chaves anteriores no dicionário em Inglês
sed -i 's/cc_saved = "Settings and Permissions saved!"/cc_saved = "Settings and Permissions saved!",/g' lua/multi_context/i18n.lua

# Adiciona a vírgula que faltou nas chaves anteriores no dicionário em Português
sed -i 's/cc_saved = "Configurações e Permissões salvas!"/cc_saved = "Configurações e Permissões salvas!",/g' lua/multi_context/i18n.lua

echo "✅ Erro de sintaxe (vírgula) corrigido no i18n.lua!"
