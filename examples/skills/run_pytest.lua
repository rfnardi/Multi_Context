-- Exemplo de Skill: Rodar Testes em Python
-- Delega a execução da suíte para o bash local e devolve o status para a IA
return {
    name = "run_pytest",
    description = "Executa testes Python usando pytest no diretório atual.",
    parameters = {
        { name = "target", type = "string", required = false, desc = "Caminho do arquivo ou diretório de testes. Padrão: roda tudo." }
    },
    execute = function(args)
        local cmd = "pytest"
        
        if args.target and args.target ~= "" then
            cmd = cmd .. " " .. vim.fn.shellescape(args.target)
        end
        
        local output = vim.fn.system(cmd)
        local status = vim.v.shell_error
        
        if status == 0 then
            return "SUCESSO: Todos os testes passaram!\n" .. output
        else
            return "FALHA: Alguns testes falharam (Código " .. status .. "):\n" .. output
        end
    end
}
