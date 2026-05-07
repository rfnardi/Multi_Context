return {
    name = "project_dump",
    description = "Gera um dump completo do projeto (Árvore + Fontes .lua)",
    execute = function()
        local root = vim.fn.system("git rev-parse --show-toplevel")
        if vim.v.shell_error ~= 0 then 
            root = vim.fn.getcwd() 
        else 
            root = root:gsub("\n", "") 
        end
        
        local out = {}
        
        -- Proteção 1: Filtra diretórios de cache e build no comando tree
        local tree_ignore = "'.git|node_modules|__pycache__|build|dist|target|.DS_Store|.mctx_chats'"
        local tree_cmd = "tree -f --noreport -I " .. tree_ignore .. " " .. vim.fn.shellescape(root)
        local tree_out = vim.fn.system(tree_cmd)
        
        -- Fallback de segurança caso o comando 'tree' não exista no sistema
        if vim.v.shell_error ~= 0 and (tree_out:match("not found") or tree_out == "") then
            tree_out = vim.fn.system("find " .. vim.fn.shellescape(root) .. " -maxdepth 3 -not -path '*/.git/*' -not -path '*/node_modules/*'")
        end
        table.insert(out, { title = "Project Tree", content = tree_out })
        
        -- Função de segurança estrita para I/O
        local function read_file_safe(filepath)
            local stat = vim.loop.fs_stat(filepath)
            if not stat then return nil end
            
            -- Proteção 2: Bloqueia arquivos maiores que 100KB para salvar tokens
            if stat.size > 100 * 1024 then
                return "--[ARQUIVO IGNORADO: MAIOR QUE 100KB] --"
            end
            
            -- Proteção 3: Heurística Anti-Binário (Procura por null bytes)
            local fd = vim.loop.fs_open(filepath, "r", 438) -- 438 é 0666 em octal
            if fd then
                local chunk = vim.loop.fs_read(fd, 1024, 0)
                vim.loop.fs_close(fd)
                if chunk and chunk:find("\0") then
                    return "-- [ARQUIVO BINÁRIO IGNORADO] --"
                end
            end
            
            local lines = vim.fn.readfile(filepath)
            return table.concat(lines, "\n")
        end

        local context_md = root .. "/CONTEXT.md"
        if vim.fn.filereadable(context_md) == 1 then
            local content = read_file_safe(context_md)
            if content then
                table.insert(out, { title = "CONTEXT.md", content = content })
            end
        end
        
        -- Proteção 4: Usa git ls-files se for repositório (respeitando o .gitignore estritamente)
        local files = {}
        if vim.fn.isdirectory(root .. "/.git") == 1 then
            local git_files = vim.fn.split(vim.fn.system("git -C " .. vim.fn.shellescape(root) .. " ls-files"), "\n")
            for _, f in ipairs(git_files) do
                if f:match("%.lua$") then
                    table.insert(files, root .. "/" .. f)
                end
            end
        else
            -- Fallback para projetos sem Git
            local find_cmd = "find " .. vim.fn.shellescape(root) .. " -type f -name '*.lua' -not -path '*/.git/*' -not -path '*/node_modules/*' -not -path '*/.mctx_chats/*'"
            files = vim.fn.split(vim.fn.system(find_cmd), "\n")
        end

        for _, f in ipairs(files) do
            if f ~= "" then
                local short_name = f:gsub(root .. "/", "")
                local content = read_file_safe(f)
                
                if content then
                    table.insert(out, { title = short_name, content = content })
                end
            end
        end
        
        return out
    end
}
