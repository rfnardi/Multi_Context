-- Exemplo de Skill: Inspecionar banco SQLite local
return {
    name = "sql_inspector",
    description = "Inspeciona as tabelas e o schema de um banco de dados SQLite local.",
    parameters = {
        { name = "db_path", type = "string", required = true, desc = "Caminho para o arquivo .db" },
        { name = "query", type = "string", required = false, desc = "Query SQL customizada. Se vazio, lista as tabelas." }
    },
    execute = function(args)
        if not args.db_path then return "ERRO: db_path é obrigatório." end
        
        local query = args.query
        if not query or query == "" then
            query = ".tables" -- Fallback útil para quando a IA só quer saber o que existe no banco
        end
        
        local cmd = string.format("sqlite3 %s %s", vim.fn.shellescape(args.db_path), vim.fn.shellescape(query))
        local output = vim.fn.system(cmd)
        
        if vim.v.shell_error ~= 0 then
            return "FALHA na execução do SQL:\n" .. output
        end
        
        return "SUCESSO:\n" .. output
    end
}
