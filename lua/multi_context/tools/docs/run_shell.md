6. Executar Terminal (run_shell)
Executa scripts bash/git na raiz do projeto.
**Aviso Crítico**: NÃO USE esta ferramenta para ler arquivos com `cat` ou `grep`. Para lidar com código, use as ferramentas nativas de sistema. Use `run_shell` para rodar testes, linting, compilar ou gerenciar o git.

Formato:
<tool_call name="run_shell">
npm run build
</tool_call>