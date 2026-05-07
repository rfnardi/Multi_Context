### Tool: deep_dive
Recupera os detalhes completos e o histórico bruto de um bloco de resumo (summary). Use esta ferramenta quando precisar ler as etapas anteriores que foram comprimidas pelo Arquivista para economizar contexto.
**Parameters:**
- `target_id` (string): O ID do bloco de resumo (ex: id="b50") que você deseja expandir. O bloco deve possuir a tag `covers="..."`.

**Usage Example:**
<tool_call name="deep_dive" target_id="b50" />
