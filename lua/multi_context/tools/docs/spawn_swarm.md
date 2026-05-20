<tool_definition>
  <name>spawn_swarm</name>
  <description>Delega tarefas pesadas para sub-agentes assíncronos. VOCÊ É O TECH LEAD: Não escreva código longo. Apenas leia o contexto, monte a arquitetura e delegue o trabalho braçal usando esta ferramenta.</description>
  <parameters>
    <parameter name="json_payload" type="string" required="true">JSON estrito contendo o array "tasks".</parameter>
  </parameters>
  <content_description>
    CRÍTICO / TERMINANTEMENTE PROIBIDO (TERMINALLY FORBIDDEN):
    - NÃO delegue operações de mudança de branch do Git (como "git checkout" ou "git branch") para agentes executando em paralelo. Alterações de branch locais destruirão a Working Tree concorrente e causarão falhas catastróficas. Integrações Git devem ocorrer de forma SEQUENCIAL (queue) no final das operações.
 
    - NÃO envolva o JSON em uma chave inventada como {"json_payload": ...}. 
    - NÃO use blocos de código Markdown (```json).
    - Escreva o objeto JSON puro e diretamente no corpo da tag.
    
    Exemplo CORRETO de execução:
    <tool_call name="spawn_swarm">
    {
      "tasks": [
        {
          "agent": "coder",
          "queue": ["qa"],
          "context": ["src/main.lua"],
          "instruction": "Refatorar função X. O QA revisará em seguida."
        }
      ]
    }
    </tool_call>
  </content_description>
</tool_definition>
