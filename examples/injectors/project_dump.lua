return {
    name = "project_dump",
    description = "Gera um dump completo do projeto (Árvore + Fontes .lua)",
    execute = function()
        local root = vim.fn.system("git rev-parse --show-toplevel")
        if vim.v.shell_error ~= 0 then root = vim.fn.getcwd() else root = root:gsub("\n", "") end
        
        local out = {}
        
        local tree_out = vim.fn.system("tree -f --noreport " .. vim.fn.shellescape(root))
        table.insert(out, { title = "Project Tree", content = tree_out })
        
        local context_md = root .. "/CONTEXT.md"
        if vim.fn.filereadable(context_md) == 1 then
            table.insert(out, { title = "CONTEXT.md", content = table.concat(vim.fn.readfile(context_md), "\n") })
        end
        
        local files = vim.fn.split(vim.fn.system("find " .. vim.fn.shellescape(root) .. " -name '*.lua'"), "\n")
        for _, f in ipairs(files) do
            if not f:match("/%.git/") and f ~= "" then
                local short_name = f:gsub(root .. "/", "")
                table.insert(out, { title = short_name, content = table.concat(vim.fn.readfile(f), "\n") })
            end
        end
        
        return out
    end
}
