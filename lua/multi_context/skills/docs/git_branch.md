<tool_definition>
  <name>git_branch</name>
  <description>Alterna para uma branch existente ou cria uma nova branch de forma isolada.</description>
  <parameters>
    <parameter name="branch_name" type="string" required="true">O nome da branch alvo</parameter>
    <parameter name="create_new" type="boolean" required="false">Se true, cria a branch (checkout -b)</parameter>
  </parameters>
  <content_description>
    Você deve fornecer os parâmetros em tags XML internas:
    <branch_name>feature/nova-tela</branch_name>
    <create_new>true</create_new>
  </content_description>
</tool_definition>
