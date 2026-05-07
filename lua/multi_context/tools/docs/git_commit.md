<tool_definition>
  <name>git_commit</name>
  <description>Realiza git add nos arquivos listados e depois cria um git commit. É ESTRITAMENTE PROIBIDO usar '*' ou '.' para adicionar tudo.</description>
  <parameters>
    <parameter name="files" type="string" required="true">Lista de arquivos alterados separados por vírgula (ex: src/main.lua, README.md)</parameter>
    <parameter name="message" type="string" required="true">A mensagem do commit no formato Semantic Commits (ex: feat(ui): ajusta layout)</parameter>
  </parameters>
  <content_description>
    Você deve fornecer os parâmetros em tags XML internas:
    <files>src/main.lua, src/utils.lua</files>
    <message>feat: atualiza utilitários</message>
  </content_description>
</tool_definition>
