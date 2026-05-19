#!/usr/bin/env bash

# MultiContext AI - CLI DevOps Mode Wrapper
# Fase 50 - Execução Autônoma Headless

if ! command -v nvim &> /dev/null; then
    echo "Erro: Neovim (nvim) não encontrado no seu PATH."
    exit 1
fi

SESSION_FILE=""

# Parser de Argumentos Nativos
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -f|--file)
            SESSION_FILE="$2"
            shift 2
            ;;
        -h|--help)
            echo "Uso: mctx [-f session.mctx] <seu prompt...>"
            echo ""
            echo "Opções:"
            echo "  -f, --file   Carrega/Salva o histórico de chat neste arquivo (Sessão Persistente)"
            echo "  -h, --help   Mostra esta mensagem de ajuda"
            echo ""
            echo "Exemplos:"
            echo "  mctx @devops --queue verifique o status do git e faça um commit"
            echo "  mctx -f dev_session.mctx @tech_lead --moa analise os logs e delegue a correção"
            exit 0
            ;;
        *)
            # Encontrou o início do prompt, para de analisar opções
            break
            ;;
    esac
done

# Agrupa todos os argumentos restantes separados por espaço (Elimina a necessidade de aspas)
PROMPT="$*"

if [ -z "$PROMPT" ]; then
    echo "Erro: Você precisa fornecer um prompt para a IA."
    echo "Dica: mctx @tech_lead o que temos no projeto?"
    exit 1
fi

# Executa o Neovim no modo Headless.
# Utilizamos blocos longos Lua [=[ ... ]=] para garantir que qualquer aspa digitada pelo usuário não quebre o parser.
nvim --headless -c "lua require('multi_context.cli').run([=[${PROMPT}]=], [=[${SESSION_FILE}]=])"

# O Neovim emitirá um "cquit 0" e este bash script repassará esse Exit Code para o Linux/CI automaticamente.
