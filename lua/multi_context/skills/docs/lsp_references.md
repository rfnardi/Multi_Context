<tool_definition>
  <name>lsp_references</name>
  <description>Retorna uma lista de arquivos e linhas onde uma função/variável/classe está sendo usada no projeto (Find References).</description>
  <parameters>
    <parameter name="path" type="string" required="true">Caminho do arquivo onde a definição ocorre</parameter>
    <parameter name="line" type="number" required="true">Linha do símbolo</parameter>
  </parameters>
  <content_description>O nome do símbolo</content_description>
</tool_definition>
