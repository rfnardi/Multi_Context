local M = {}

M._find_symbol_col = function(line_text, symbol)
    if not line_text or not symbol then return nil end
    local plain_symbol = symbol:gsub("([^%w])", "%%%1")
    local start_pos = string.find(line_text, plain_symbol)
    if start_pos then
        -- LSP usa indexação 0-based
        return start_pos - 1
    end
    return nil
end

M.get_definition = function(path, line, symbol)
    local full_path = path
    local root = vim.fn.system("git rev-parse --show-toplevel")
    if vim.v.shell_error == 0 then
        root = root:gsub("\n", "")
        if full_path:sub(1,1) ~= "/" then
            full_path = root .. "/" .. full_path
        end
    end

    local uri = vim.uri_from_fname(full_path)
    local lnum = tonumber(line)
    if not lnum then return "ERRO: Atributo 'line' inválido" end
    -- Neovim UI usa 1-based, LSP usa 0-based.
    lnum = lnum - 1

    local params = {
        textDocument = { uri = uri },
        position = { line = lnum, character = 0 }
    }

    local bufnr = vim.fn.bufadd(full_path)
    if bufnr and bufnr ~= 0 then
        local lines = {}
        if vim.api.nvim_buf_is_loaded(bufnr) then
            lines = vim.api.nvim_buf_get_lines(bufnr, lnum, lnum+1, false)
        else
            if vim.fn.filereadable(full_path) == 1 then
                local f_lines = vim.fn.readfile(full_path)
                if f_lines[lnum+1] then table.insert(lines, f_lines[lnum+1]) end
            end
        end
        -- Injeta a coluna se encontrar a palavra chave na linha
        if lines[1] then
            local col = M._find_symbol_col(lines[1], symbol)
            if col then params.position.character = col end
        end
    end

    -- Realiza a chamada silenciosa para o servidor LSP acoplado a este arquivo
    local responses = vim.lsp.buf_request_sync(bufnr, "textDocument/definition", params, 2000)
    
    if not responses or vim.tbl_isempty(responses) then
        return "Nenhuma definição encontrada para o símbolo via LSP."
    end
    
    -- Processa o JSON complexo de retorno do LSP e formata como string pro LLM
    for client_id, response in pairs(responses) do
        if response.result and not vim.tbl_isempty(response.result) then
            local result = response.result
            if not vim.tbl_islist(result) then result = { result } end
            
            local def = result[1]
            local target_uri = def.uri or def.targetUri
            local range = def.range or def.targetSelectionRange
            local target_path = vim.uri_to_fname(target_uri)
            local target_line = range.start.line
            
            local lines = {}
            if vim.fn.filereadable(target_path) == 1 then
                lines = vim.fn.readfile(target_path)
            end
            
            local output = {"=== LSP Go To Definition ===", "Arquivo: " .. target_path}
            
            -- Extrai a função apontada e um bloco de 15 linhas
            local s_idx = math.max(1, target_line - 2)
            local e_idx = math.min(#lines, target_line + 15)
            for i = s_idx, e_idx do
                local prefix = (i == target_line + 1) and ">> " or "   "
                table.insert(output, prefix .. i .. " | " .. lines[i])
            end
            
            return table.concat(output, "\n")
        end
    end
    
    return "Falha ao processar definição via LSP."
end

return M

M.get_references = function(path, line, symbol)
    local full_path = vim.fn.fnamemodify(path, ":p")
    local root = vim.fn.system("git rev-parse --show-toplevel")
    if vim.v.shell_error == 0 then
        root = root:gsub("\n", "")
        if path:sub(1,1) ~= "/" then full_path = root .. "/" .. path end
    end

    local uri = vim.uri_from_fname(full_path)
    local lnum = tonumber(line)
    if not lnum then return "ERRO: Atributo 'line' inválido" end
    lnum = lnum - 1

    local params = {
        textDocument = { uri = uri },
        position = { line = lnum, character = 0 },
        context = { includeDeclaration = true }
    }

    local bufnr = vim.fn.bufadd(full_path)
    if bufnr and bufnr ~= 0 then
        local lines = {}
        if vim.api.nvim_buf_is_loaded(bufnr) then
            lines = vim.api.nvim_buf_get_lines(bufnr, lnum, lnum+1, false)
        else
            if vim.fn.filereadable(full_path) == 1 then
                local f_lines = vim.fn.readfile(full_path)
                if f_lines[lnum+1] then table.insert(lines, f_lines[lnum+1]) end
            end
        end
        if lines[1] then
            local col = M._find_symbol_col(lines[1], symbol)
            if col then params.position.character = col end
        end
    end

    local responses = vim.lsp.buf_request_sync(bufnr, "textDocument/references", params, 2000)
    
    if not responses or vim.tbl_isempty(responses) then
        return "Nenhuma referência encontrada para o símbolo via LSP."
    end
    
    local output = {"=== LSP References ==="}
    local refs_count = 0
    for client_id, response in pairs(responses) do
        if response.result and not vim.tbl_isempty(response.result) then
            for _, ref in ipairs(response.result) do
                local target_uri = ref.uri
                local target_path = vim.uri_to_fname(target_uri)
                local target_line = ref.range.start.line
                table.insert(output, string.format("- %s : Linha %d", target_path, target_line + 1))
                refs_count = refs_count + 1
                if refs_count > 50 then
                    table.insert(output, "... [Truncado (Muitas referencias)]")
                    return table.concat(output, "\n")
                end
            end
        end
    end
    
    if refs_count == 0 then return "Nenhuma referência encontrada para o símbolo via LSP." end
    return table.concat(output, "\n")
end

M.get_document_symbols = function(path)
    local full_path = vim.fn.fnamemodify(path, ":p")
    local root = vim.fn.system("git rev-parse --show-toplevel")
    if vim.v.shell_error == 0 then
        root = root:gsub("\n", "")
        if path:sub(1,1) ~= "/" then full_path = root .. "/" .. path end
    end

    local uri = vim.uri_from_fname(full_path)
    local bufnr = vim.fn.bufadd(full_path)
    local params = { textDocument = { uri = uri } }
    
    local responses = vim.lsp.buf_request_sync(bufnr, "textDocument/documentSymbol", params, 2000)
    if not responses or vim.tbl_isempty(responses) then
        return "Nenhum símbolo encontrado via LSP para este arquivo."
    end
    
    local output = {"=== LSP Document Symbols (" .. path .. ") ==="}
    for client_id, response in pairs(responses) do
        if response.result and not vim.tbl_isempty(response.result) then
            local function parse_symbols(symbols, indent)
                for _, sym in ipairs(symbols) do
                    local kind = sym.kind or "?"
                    local name = sym.name or "?"
                    local range = sym.range or sym.selectionRange
                    if range then
                        table.insert(output, indent .. "- [" .. kind .. "] " .. name .. " (Linha " .. (range.start.line + 1) .. ")")
                    end
                    if sym.children then
                        parse_symbols(sym.children, indent .. "  ")
                    end
                end
            end
            parse_symbols(response.result, "")
            break
        end
    end
    return table.concat(output, "\n")
end
