4. Substituir Bloco de Código (replace_lines) - FERRAMENTA RECOMENDADA
Edita um arquivo substituindo estritamente as linhas alvo. 
**Regra do Claude Code**: Prefira ESTA ferramenta no lugar de `edit_file` para economizar contexto e manter a integridade do arquivo. Não envie o arquivo inteiro, apenas as linhas modificadas.

Formato:
<tool_call name="replace_lines" path="arquivo.ts" start="10" end="15">
// APENAS AS NOVAS LINHAS AQUI (substituindo das linhas 10 à 15)
</tool_call>