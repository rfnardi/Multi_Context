local M = {}

local valid_tools_list = {
    "list_files", "read_file", "search_code", "edit_file", 
    "run_shell", "replace_lines", "apply_diff", "rewrite_chat_buffer", "get_diagnostics", "spawn_swarm", "switch_agent",
    "lsp_definition", "lsp_references", "lsp_document_symbols", "git_status", "git_branch", "git_commit"
}

-- 1. SANITIZADOR ANTI-ALUCINAÇÃO DE SINTAXE
M.sanitize_payload = function(content)
    local c = content
    -- Corrigido para[^<]* para que ele engula o ">" do </arg_value>tool_call>
    c = c:gsub("</[^<]*tool_call%s*>", "</tool_call>")
    c = c:gsub("<tool_call>%s*([a-zA-Z_]+)%s*>", '<tool_call name="%1">')
    
    -- Aliases de Sanitização (Alucinações do LLM)
    c = c:gsub("<bash%s*>", '<tool_call name="run_shell">')
    c = c:gsub("</bash%s*>", '</tool_call>')
    c = c:gsub("<execute%s*>", '<tool_call name="run_shell">')
    c = c:gsub("</execute%s*>", '</tool_call>')
    c = c:gsub("<execute_command%s*>", '<tool_call name="run_shell">')
    c = c:gsub("</execute_command%s*>", '</tool_call>')
    c = c:gsub("<read%s+path=", '<tool_call name="read_file" path=')
    c = c:gsub("</read%s*>", '</tool_call>')

    for _, tool in ipairs(valid_tools_list) do
        c = c:gsub("<" .. tool .. "%s*>", '<tool_call name="' .. tool .. '">')
        c = c:gsub("<" .. tool .. "%s+([^>]+)>", '<tool_call name="' .. tool .. '" %1>')
        c = c:gsub("</" .. tool .. "%s*>", "</tool_call>")
    end
    return c
end

local function get_attr(attrs, n) 
    if not attrs then return nil end
    return attrs:match(n .. '%s*=%s*["\']([^"\']+)["\']') 
end

-- 2. LIMPEZA PROFUNDA DE LIXO INTERNO (Crases e tags aninhadas)
M.clean_inner_content = function(inner, name)
    local clean = inner
    if not name or name == "" or name == "nil" then return clean end

    -- Remove tags inventadas que circundam o JSON
    local h_tags = {"content", "code", "command", "arg_value", "argument", "parameters", "parameter", "text", "source", "tool_call", "json_payload"}
    local changed = true
    while changed do
        changed = false
        local before_md = clean
        clean = clean:gsub("^%s*```[%w_]*\n", ""):gsub("\n%s*```%s*$", "")
        if before_md ~= clean then changed = true end
        
        for _, tag in ipairs(h_tags) do
            local pat_full = "^%s*<" .. tag .. "[^>]*>%s*(.-)%s*</" .. tag .. ">%s*$"
            local val = clean:match(pat_full)
            if val then clean = val; changed = true end
            
            local pat_end = "%s*</" .. tag .. ">%s*$"
            if clean:match(pat_end) then clean = clean:gsub(pat_end, ""); changed = true end
            
            local pat_start = "^%s*<" .. tag .. "[^>]*>%s*"
            if clean:match(pat_start) then clean = clean:gsub(pat_start, ""); changed = true end
        end
    end
    return clean
end

-- 3. EXTRATOR ITERATIVO (Acha a próxima tag a partir do cursor)
M.parse_next_tool = function(content_to_process, cursor)
    local tag_start, tag_end = content_to_process:find("<tool_call[^>]*>", cursor)
    if not tag_start then return nil end

    local text_before = content_to_process:sub(cursor, tag_start - 1)
    local _, tick_count = text_before:gsub("```", "")
    
    local tag_str = content_to_process:sub(tag_start, tag_end)
    local is_self_closing = tag_str:match("/%s*>$")
    local close_start, close_end, inner

    if is_self_closing then
        inner = ""
        close_start = tag_end + 1
        close_end = tag_end
    else
        close_start, close_end = content_to_process:find("</tool_call%s*>", tag_end + 1)
        local next_open = content_to_process:find("<tool_call", tag_end + 1)
        
        if next_open and (not close_start or next_open < close_start) then
            close_start = next_open
            close_end = next_open - 1
            inner = content_to_process:sub(tag_end + 1, close_start - 1)
        elseif not close_start then 
            inner = content_to_process:sub(tag_end + 1)
            close_end = #content_to_process
        else 
            inner = content_to_process:sub(tag_end + 1, close_start - 1) 
        end
    end

    -- Se for impar, é block de código markdown falando SOBRE a tag, ignoramos
    if tick_count % 2 ~= 0 then
        return { is_invalid = true, text_before = text_before, raw_tag = tag_str, inner = inner, close_end = close_end, close_start = close_start }
    end

    local name = get_attr(tag_str, "name")
    local path = get_attr(tag_str, "path")
    local query = get_attr(tag_str, "query")
    local start_line = get_attr(tag_str, "start") or get_attr(tag_str, "line")
    local end_line = get_attr(tag_str, "end")

    -- Fallback se a IA mandou como JSON dentro do XML
    if not name or name == "" then
        local ok, json = pcall(vim.fn.json_decode, vim.trim(inner))
        if ok and type(json) == "table" then
            name = json.name
            if type(json.arguments) == "table" then
                path = json.arguments.path; query = json.arguments.query
                start_line = json.arguments.start or json.arguments.start_line
                end_line = json.arguments["end"] or json.arguments.end_line
                inner = json.arguments.command or json.arguments.content or json.arguments.code or inner
            end
        end
    end

    local clean_inner = M.clean_inner_content(inner, name)

    -- Fallback agressivo: Se a IA mandou o parametro dentro de uma tag interna em vez do atributo
    if not path or path == "" then
        local inner_path = clean_inner:match("<path>(.-)</path>")
        if inner_path then path = vim.trim(inner_path) end
    end
    if not query or query == "" then
        local inner_query = clean_inner:match("<query>(.-)</query>")
        if inner_query then query = vim.trim(inner_query) end
    end
    if not start_line or start_line == "" then
        local inner_start = clean_inner:match("<start>(.-)</start>") or clean_inner:match("<line>(.-)</line>")
        if inner_start then start_line = vim.trim(inner_start) end
    end
    if not end_line or end_line == "" then
        local inner_end = clean_inner:match("<end>(.-)</end>")
        if inner_end then end_line = vim.trim(inner_end) end
    end

    return {
        is_invalid = false,
        text_before = text_before,
        raw_tag = tag_str,
        name = name,
        path = path,
        query = query,
        start_line = start_line,
        end_line = end_line,
        inner = clean_inner,
        close_start = close_start,
        close_end = close_end
    }
end

return M
