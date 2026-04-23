-- lua/multi_context/tools.lua
local M = {}

local function get_repo_root()
    vim.fn.system("git rev-parse --show-toplevel")
    if vim.v.shell_error ~= 0 then return nil end
    return vim.fn.system("git rev-parse --show-toplevel"):gsub("\n", "")
end

local function resolve_path(path)
    if not path or path == "" then return nil end
    path = vim.trim(path)
    if path:sub(1, 1) == "/" then return path end
    local root = get_repo_root() or vim.fn.getcwd()
    return root .. "/" .. path
end

M.list_files = function()
    local root = get_repo_root()
    if not root then return "ERRO: Fora de um repositório Git." end
    local files = vim.fn.system("git -C " .. vim.fn.shellescape(root) .. " ls-files")
    return "Arquivos rastreados pelo Git:\n" .. files
end

M.read_file = function(path)
    local full_path = resolve_path(path)
    if not full_path then return "ERRO: Atributo 'path' obrigatório." end
    if vim.fn.filereadable(full_path) == 0 then return "ERRO: Arquivo não encontrado (" .. full_path .. ")" end
    
    local lines = vim.fn.readfile(full_path)
    local numbered_lines = {}
    for i, line in ipairs(lines) do
        table.insert(numbered_lines, string.format("%d | %s", i, line))
    end
    
    return table.concat(numbered_lines, "\n")
end

M.edit_file = function(path, content)
    local full_path = resolve_path(path)
    if not full_path then return "ERRO: O atributo 'path' é obrigatório." end
    
    local dir = vim.fn.fnamemodify(full_path, ":h")
    if vim.fn.isdirectory(dir) == 0 then vim.fn.mkdir(dir, "p") end

    -- Blindagem: Limpa lixo de formatação da IA
    content = content:gsub("\r", "")
    content = content:gsub("^%s*```[%w_]*\n", ""):gsub("\n%s*```%s*$", "")
    
    local lines = vim.split(content, "\n", {plain=true})
    local bufnr = vim.fn.bufnr(full_path)
    
    if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
        vim.api.nvim_buf_call(bufnr, function() vim.cmd("silent! write") end)
    else
        if vim.fn.writefile(lines, full_path) == -1 then
            return "ERRO: Falha de permissão ao salvar " .. full_path
        end
    end
    vim.notify("✅ Arquivo criado/salvo: " .. full_path, vim.log.levels.INFO)
    return "SUCESSO: Arquivo " .. full_path .. " foi sobrescrito/criado."
end

M.run_shell = function(cmd)
    if not cmd or cmd == "" then return "ERRO: Comando não fornecido." end
    local root = get_repo_root() or vim.fn.getcwd()
    cmd = vim.trim(cmd)
    local bash_script = string.format("cd %s && %s", vim.fn.shellescape(root), cmd)
    local out = vim.fn.system({'bash', '-c', bash_script})
    local status = vim.v.shell_error ~= 0 and ("FALHA (Código " .. vim.v.shell_error .. ")") or "SUCESSO"
    return string.format("Comando:\n%s\n\nStatus: %s\nSaída:\n%s", cmd, status, out)
end

M.search_code = function(query)
    local root = get_repo_root()
    if not root then return "ERRO: Fora de repositório Git." end
    if not query or query == "" then return "ERRO: 'query' obrigatória." end
    local cmd = string.format("git -C %s grep -n -i -I %s", vim.fn.shellescape(root), vim.fn.shellescape(query))
    local out = vim.fn.system(cmd)
    if vim.v.shell_error ~= 0 or out == "" then return "Nenhum resultado para: " .. query end
    if #out > 3000 then out = out:sub(1, 3000) .. "\n\n... [AVISO: TRUNCADO] ..." end
    return "Resultados da busca:\n" .. out
end

M.replace_lines = function(path, start_line, end_line, content)
    local full_path = resolve_path(path)
    if not full_path then return "ERRO: 'path' obrigatório." end
    start_line, end_line = tonumber(start_line), tonumber(end_line)
    if not start_line or not end_line then return "ERRO: 'start' e 'end' devem ser números." end
    
    local bufnr = vim.fn.bufnr(full_path)
    local lines = {}
    if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
        lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    else
        if vim.fn.filereadable(full_path) == 0 then return "ERRO: Arquivo não encontrado." end
        lines = vim.fn.readfile(full_path)
    end
    
    if start_line < 1 then start_line = 1 end
    if end_line > #lines then end_line = #lines end
    
    content = content:gsub("\r", "")
    content = content:gsub("^%s*```[%w_]*\n", ""):gsub("\n%s*```%s*$", "")
    local new_lines = content == "" and {} or vim.split(content, "\n", {plain=true})
    
    local final_lines = {}
    for i = 1, start_line - 1 do table.insert(final_lines, lines[i]) end
    for _, l in ipairs(new_lines) do table.insert(final_lines, l) end
    for i = end_line + 1, #lines do table.insert(final_lines, lines[i]) end
    
    if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, final_lines)
        vim.api.nvim_buf_call(bufnr, function() vim.cmd("silent! write") end)
    else
        vim.fn.writefile(final_lines, full_path)
    end
    vim.notify("✅ Edição aplicada: " .. full_path, vim.log.levels.INFO)
    return "SUCESSO: Edição nas linhas " .. start_line .. " a " .. end_line
end

M.get_diagnostics = function(path)
    -- 1. Exige explicitamente o caminho do arquivo
    if not path or path == "" or path == "nil" then
        return "ERRO: O atributo 'path' é OBRIGATÓRIO. Ex: <tool_call name=\"get_diagnostics\" path=\"caminho/do/arquivo.lua\"></tool_call>"
    end

    -- 2. Resolve o caminho e carrega o buffer
    path = vim.trim(path)
    local full_path = resolve_path(path)
    if not full_path then return "ERRO: 'path' inválido." end
    
    local bufnr = vim.fn.bufnr(full_path)
    if bufnr == -1 then
        if vim.fn.filereadable(full_path) == 0 then
            return "ERRO: Arquivo não encontrado: " .. full_path
        end
        bufnr = vim.fn.bufadd(full_path)
        if bufnr == 0 then return "ERRO: Não foi possível carregar o arquivo: " .. full_path end
        vim.fn.bufload(bufnr)
    end

    -- 3. Verifica presença de LSP ativo
    local has_lsp = vim.lsp.buf_is_attached and vim.lsp.buf_is_attached(bufnr)
    if not has_lsp then
        local clients = vim.lsp.get_clients and vim.lsp.get_clients({bufnr = bufnr}) or {}
        has_lsp = #clients > 0
    end

    if has_lsp then
        -- Aguarda o LSP recalcular diagnósticos (até 2s)
        vim.wait(2000, function() return false end, 50)
        vim.wait(300)
    end

    -- 4. Coleta diagnósticos
    local diagnostics = vim.diagnostic.get(bufnr)
    if not diagnostics or #diagnostics == 0 then
        if not has_lsp then
            return "AVISO: Nenhum servidor LSP ativo detectado para: " .. full_path
        end
        return "✅ Nenhum diagnóstico ou erro encontrado em: " .. full_path
    end

    -- 5. Formata e Trunca a resposta para proteger a janela de contexto
    local MAX_DIAGS = 50
    local MAX_BYTES = 3000
    local severity_names = { [1] = "ERROR", [2] = "WARN", [3] = "INFO", [4] = "HINT" }
    local out_lines = {}
    local count = math.min(#diagnostics, MAX_DIAGS)

    for i = 1, count do
        local d = diagnostics[i]
        local sev = severity_names[d.severity] or "?"
        local msg = d.message or ""
        local lnum = (d.lnum or 0) + 1
        local col = (d.col or 0) + 1
        local source = d.source or ""
        table.insert(out_lines, string.format("L%d:C%d [%s] %s%s", lnum, col, sev, msg, source ~= "" and (" ("..source..")") or ""))
    end

    local result = "Diagnósticos para " .. full_path .. ":\n" .. table.concat(out_lines, "\n")

    if #result > MAX_BYTES then
        result = result:sub(1, MAX_BYTES) .. "\n\n[AVISO: TRUNCADO - " .. #diagnostics .. " diagnósticos no total, exibindo " .. count .. "]"
    elseif #diagnostics > MAX_DIAGS then
        result = result .. "\n\n[AVISO: " .. #diagnostics .. " diagnósticos no total, exibindo os primeiros " .. MAX_DIAGS .. "]"
    end

    return result
end


M.apply_diff = function(path, diff_content)
    local full_path = resolve_path(path)
    if not full_path then return "ERRO: 'path' obrigatório." end
    
    local bufnr = vim.fn.bufnr(full_path)
    local lines = {}
    
    -- Antes de aplicar o diff em disco, garantimos que o disco está atualizado com o buffer vivo
    if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
        lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        vim.fn.writefile(lines, full_path)
    else
        if vim.fn.filereadable(full_path) == 0 then return "ERRO: Arquivo não encontrado." end
    end
    
    -- Limpa sujeira comum que as LLMs adicionam ao redor do diff
    diff_content = diff_content:gsub("\r", "")
    diff_content = diff_content:gsub("^%s*```[%w_]*\n", ""):gsub("\n%s*```%s*$", "")
    
    local tmp_patch = os.tmpname()
    vim.fn.writefile(vim.split(diff_content, "\n", {plain=true}), tmp_patch)
    
    -- Chama o binário UNIX `patch`. A flag --force impede que o binário fique pendurado esperando input no terminal se falhar.
    local cmd = string.format("patch --force -u %s -i %s", vim.fn.shellescape(full_path), vim.fn.shellescape(tmp_patch))
    local out = vim.fn.system(cmd)
    local status = vim.v.shell_error
    
    -- Limpa os rastros
    os.remove(tmp_patch)
    os.remove(full_path .. ".orig")
    os.remove(full_path .. ".rej")
    
    if status ~= 0 then
        return "FALHA ao aplicar diff (Código " .. status .. "):\n" .. out
    end
    
    -- Se o buffer estava aberto no vim, fazemos o recarregamento (hot-reload) do arquivo modificado
    if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
        local new_lines = vim.fn.readfile(full_path)
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)
        vim.api.nvim_buf_call(bufnr, function() vim.cmd("silent! write") end)
    end
    
    vim.notify("✅ Diff aplicado: " .. full_path, vim.log.levels.INFO)
    return "SUCESSO: Diff aplicado no arquivo " .. full_path
end

return M
