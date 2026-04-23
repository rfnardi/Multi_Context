<tool_definition>
  <name>spawn_swarm</name>
  <description>Delega tarefas pesadas para sub-agentes assíncronos. VOCÊ É O TECH LEAD: Não escreva código longo. Apenas leia o contexto, monte a arquitetura e delegue o trabalho braçal usando esta ferramenta.</description>
  <parameters>
    <parameter name="json_payload" type="string" required="true">
      JSON estrito contendo o array "tasks".
      - Para processamento paralelo, use: "agent": "nome"
      - Para linha de montagem (Pipeline), use: "chain": ["coder", "qa"] (O 'coder' codifica e, quando terminar, a tarefa e seu output são automaticamente passados ao 'qa').
      - Para autorizar pedir ajuda no meio da tarefa (Coreografia), use: "allow_switch": ["dba"]
      
      Exemplo de JSON:
      {
        "tasks": [
          {
            "chain": ["coder", "qa"],
            "context": ["src/login.lua"],
            "instruction": "Implemente a rota de login. O QA revisará e testará a seguir.",
            "allow_switch": ["dba"]
          }
        ]
      }
    </parameter>
  </parameters>
</tool_definition>
