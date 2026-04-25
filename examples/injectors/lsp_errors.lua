return {
    name = "lsp_errors",
    description = "Lista todos os erros e avisos do LSP no workspace ativo",
    execute = function()
        local diags = vim.diagnostic.get(nil)
        if #diags == 0 then return "Nenhum problema encontrado pelo LSP no projeto." end
        
        local severity_names = { [1] = "ERROR", [2] = "WARN", [3] = "INFO", [4] = "HINT" }
        local out = {"=== PROBLEMAS NO PROJETO (LSP) ==="}
        
        for _, d in ipairs(diags) do
            local sev = severity_names[d.severity] or "?"
            local file = vim.api.nvim_buf_get_name(d.bufnr)
            -- Deixa o caminho relativo à raiz para economizar tokens
            file = vim.fn.fnamemodify(file, ":.")
            table.insert(out, string.format("%s:%d:%d [%s] %s", file, d.lnum + 1, d.col + 1, sev, d.message))
        end
        
        return table.concat(out, "\n")
    end
}
