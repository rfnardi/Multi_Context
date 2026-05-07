  <tool_definition>
    <name>apply_diff</name>
    <description>Aplica um patch estrito de Unified Diff em um arquivo existente. Ideal e RECOMENDADO para fazer pequenas/médias modificações em arquivos longos, economizando tokens e evitando alucinações.</description>
    <parameters>
      <parameter name="path" type="string" required="true">Caminho do arquivo (ex: src/main.lua).</parameter>
      <parameter name="content" type="string" required="true">O código absoluto no formato Unified Diff contendo as flags --- a/file e +++ b/file originais e inalteradas.</parameter>
    </parameters>
  </tool_definition>
