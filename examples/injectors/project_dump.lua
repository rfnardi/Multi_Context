return {
    name = "project_dump",
    description = "Gera um dump completo do projeto (Markdown + Árvore + Fontes .lua)",
    execute = function()
        local root = vim.fn.system("git rev-parse --show-toplevel")
        if vim.v.shell_error ~= 0 then root = vim.fn.getcwd() else root = root:gsub("\n", "") end
        
        local out = {}
        table.insert(out, "=== CONTEXTO COMPLETO DO PROJETO ===")
        table.insert(out, "Árvore de arquivos:")
        table.insert(out, vim.fn.system("tree -f --noreport " .. vim.fn.shellescape(root)))
        
        local context_md = root .. "/CONTEXT.md"
        if vim.fn.filereadable(context_md) == 1 then
            table.insert(out, "\n======= CONTEXT.MD =======")
            table.insert(out, table.concat(vim.fn.readfile(context_md), "\n"))
        end
        
        table.insert(out, "\n======= CÓDIGO FONTE =======")
        -- Busca apenas arquivos .lua por padrão, para evitar estourar o contexto do chat.
        -- O usuário final pode alterar '*.lua' para '*.js' ou o que preferir.
        local files = vim.fn.split(vim.fn.system("find " .. vim.fn.shellescape(root) .. " -name '*.lua'"), "\n")
        for _, f in ipairs(files) do
            if not f:match("/%.git/") and f ~= "" then
                table.insert(out, "======== " .. f .. " ========")
                table.insert(out, table.concat(vim.fn.readfile(f), "\n"))
                table.insert(out, "==============================\n")
            end
        end
        
        return table.concat(out, "\n")
    end
}
