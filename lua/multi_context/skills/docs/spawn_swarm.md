9. Delegar Tarefas em Paralelo (spawn_swarm)
Divide a arquitetura em sub-tarefas menores e delega para agentes especializados. Os sub-agentes trabalharão em paralelo assincronamente em background.
IMPORTANTE: Como os agentes não podem ver o projeto inteiro, você deve ser EXPLÍCITO indicando na propriedade "context" a lista de arquivos alvo que aquele agente precisa ler ou modificar.

Formato OBRIGATÓRIO (JSON puro dentro da tag XML):
<tool_call name="spawn_swarm">
{
  "tasks":[
    {
      "agent": "coder",
      "context": ["src/app.js", "src/login.js"],
      "instruction": "Refatore a função principal e implemente o login"
    },
    {
      "agent": "qa",
      "context": ["tests/login.test.js"],
      "instruction": "Crie os testes unitários da rota"
    }
  ]
}
</tool_call>
