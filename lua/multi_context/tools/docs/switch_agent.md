<tool_definition>
  <name>switch_agent</name>
  <description>Transfere o controle do seu corpo e da sua aba para outro agente em tempo real. Use isso SE você travar ou precisar que um especialista (ex: DBA, QA) assuma a tarefa imediatamente. Só funciona se o mestre lhe autorizou na flag "allow_switch".</description>
  <parameters>
    <parameter name="target_agent" type="string" required="true">
      O nome da persona/agente que deve assumir o controle a partir de agora (ex: "qa", "dba").
    </parameter>
  </parameters>
</tool_definition>
