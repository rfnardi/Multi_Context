-- Exemplo de Skill: Integração com Jira
-- Requer a CLI do Jira instalada na máquina (jira-cli)
return {
    name = "read_jira",
    description = "Busca detalhes de um ticket no Jira usando a CLI do Jira.",
    parameters = {
        { name = "ticket_id", type = "string", required = true, desc = "O ID do ticket. Ex: PROJ-123" }
    },
    execute = function(args)
        if not args.ticket_id then return "ERRO: ticket_id é obrigatório." end
        
        -- Monta o comando seguro
        local cmd = string.format("jira issue view %s", vim.fn.shellescape(args.ticket_id))
        local output = vim.fn.system(cmd)
        
        if vim.v.shell_error ~= 0 then
            return "FALHA ao buscar ticket no Jira:\n" .. output
        end
        
        return "SUCESSO: Detalhes do Ticket:\n" .. output
    end
}
