#!/usr/bin/env bash

echo "1. Corrigindo o erro de sintaxe no dynamic_watchdog.lua (movendo 'return M' para o fim)..."
awk '/^return M[ \t]*$/ { next } { print } END { print "\nreturn M" }' lua/multi_context/core/dynamic_watchdog.lua > tmp_wd.lua && mv tmp_wd.lua lua/multi_context/core/dynamic_watchdog.lua


echo "2. Implementando Fase 44.3: Motor de Injectors Tabular (injectors.lua)..."

# Adicionando a função process_injection logo antes do return M
awk '
/^return M[ \t]*$/ {
    print "M.process_injection = function(content_returned, bufnr)"
    print "    if type(content_returned) == \"string\" then"
    print "        return content_returned"
    print "    elseif type(content_returned) == \"table\" then"
    print "        local lines = {}"
    print "        local watchdog = require(\"multi_context.core.dynamic_watchdog\")"
    print "        local blocks_to_dispatch = {}"
    print "        for _, item in ipairs(content_returned) do"
    print "            if item.title and item.content then"
    print "                local block_id = \"inj_\" .. os.date(\"%H%M%S\") .. \"_\" .. tostring(math.random(1000, 9999))"
    print "                table.insert(lines, \"<block id=\\\"\" .. block_id .. \"\\\" type=\\\"context_injection\\\">\")"
    print "                table.insert(lines, \"<abstract>\")"
    print "                table.insert(lines, \"<summary>Indexando: \" .. item.title .. \"...</summary>\")"
    print "                table.insert(lines, \"</abstract>\")"
    print "                table.insert(lines, \"<content>\")"
    print "                for _, l in ipairs(vim.split(item.content, \"\\n\", {plain=true})) do table.insert(lines, l) end"
    print "                table.insert(lines, \"</content>\")"
    print "                table.insert(lines, \"</block>\")"
    print "                table.insert(blocks_to_dispatch, { id = block_id, content = item.content })"
    print "            end"
    print "        end"
    print "        if #blocks_to_dispatch > 0 then"
    print "            vim.schedule(function() watchdog.dispatch_parallel_jit_tasks(bufnr, blocks_to_dispatch) end)"
    print "        end"
    print "        return table.concat(lines, \"\\n\")"
    print "    end"
    print "    return \"\""
    print "end"
    print "return M"
    next
}
{print}
' lua/multi_context/ecosystem/injectors.lua > tmp_inj.lua && mv tmp_inj.lua lua/multi_context/ecosystem/injectors.lua

# Atualizando a injeção via _select para usar o process_injection
awk '
/local content_lines = vim.split\(content, "\\n", \{plain = true\}\)/ {
    print "        local target_buf = api.nvim_win_get_buf(M.parent_win)"
    print "        content = M.process_injection(content, target_buf)"
    print $0
    next
}
{print}
' lua/multi_context/ecosystem/injectors.lua > tmp_inj.lua && mv tmp_inj.lua lua/multi_context/ecosystem/injectors.lua


echo "3. Implementando Fase 44.4: Refatorando o project_dump.lua..."
cat << 'EOF' > examples/injectors/project_dump.lua
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
EOF

echo "Feito! Rode os testes novamente. Todos devem voltar para 257+ e estarem GREEN!"
