<tool_definition>
  <name>lsp_definition</name>
  <description>Retorna a linha exata e o código fonte onde uma função/classe foi definida (Go to Definition). Sempre tente usar o search_code ou document_symbols antes para saber o nome do arquivo.</description>
  <parameters>
    <parameter name="path" type="string" required="true">Caminho do arquivo onde o símbolo está sendo chamado</parameter>
    <parameter name="line" type="number" required="true">Linha onde a chamada ocorre</parameter>
  </parameters>
  <content_description>O nome do símbolo (ex: nome da função ou variável)</content_description>
</tool_definition>
