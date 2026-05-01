local M = {}
local i18n = require('multi_context.i18n')

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
    if not root then return i18n.t("err_not_git") end
    local files = vim.fn.system("git -C " .. vim.fn.shellescape(root) .. " ls-files")
    return i18n.t("git_tracked_files") .. files
end

M.read_file = function(path)
    local full_path = resolve_path(path)
    if not full_path then return i18n.t("err_path_req") end
    if vim.fn.filereadable(full_path) == 0 then return i18n.t("err_file_not_found", full_path) end
    
    local lines = vim.fn.readfile(full_path)
    local numbered_lines = {}
    for i, line in ipairs(lines) do
        table.insert(numbered_lines, string.format("%d | %s", i, line))
    end
    
    return table.concat(numbered_lines, "\n")
end

M.edit_file = function(path, content)
    local full_path = resolve_path(path)
    if not full_path then return i18n.t("err_path_req") end
    
    local dir = vim.fn.fnamemodify(full_path, ":h")
    if vim.fn.isdirectory(dir) == 0 then vim.fn.mkdir(dir, "p") end

    content = content:gsub("\r", "")
    content = content:gsub("^%s*```[%w_]*\n", ""):gsub("\n%s*```%s*$", "")
    
    local lines = vim.split(content, "\n", {plain=true})
    local bufnr = vim.fn.bufnr(full_path)
    
    if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
        vim.api.nvim_buf_call(bufnr, function() vim.cmd("silent! write") end)
    else
        if vim.fn.writefile(lines, full_path) == -1 then
            return i18n.t("err_perm_save", full_path)
        end
    end
    vim.notify(i18n.t("file_saved", full_path), vim.log.levels.INFO)
    return i18n.t("succ_file_saved", full_path)
end

M.run_shell = function(cmd)
    if not cmd or cmd == "" then return i18n.t("err_cmd_req") end
    local root = get_repo_root() or vim.fn.getcwd()
    cmd = vim.trim(cmd)
    local bash_script = string.format("cd %s && %s", vim.fn.shellescape(root), cmd)
    local out = vim.fn.system({'bash', '-c', bash_script})
    local status = vim.v.shell_error ~= 0 and i18n.t("fail_code", vim.v.shell_error) or i18n.t("success")
    return i18n.t("shell_output", cmd, status, out)
end

M.search_code = function(query)
    local root = get_repo_root()
    if not root then return i18n.t("err_not_git") end
    if not query or query == "" then return i18n.t("err_query_req") end
    local cmd
    if vim.fn.executable("rg") == 1 then
        cmd = string.format("rg -n -i -- %s %s", vim.fn.shellescape(query), vim.fn.shellescape(root))
    else
        cmd = string.format("git -C %s grep -n -i -I -- %s", vim.fn.shellescape(root), vim.fn.shellescape(query))
    end
    local out = vim.fn.system(cmd)
    if out == "" then return i18n.t("no_results", query) end
    if #out > 3000 then out = out:sub(1, 3000) .. "\n\n" .. i18n.t("warn_truncated") end
    return i18n.t("search_results") .. out
end

M.replace_lines = function(path, start_line, end_line, content)
    local full_path = resolve_path(path)
    if not full_path then return i18n.t("err_path_req") end
    start_line, end_line = tonumber(start_line), tonumber(end_line)
    if not start_line or not end_line then return i18n.t("err_lines_num") end
    
    local bufnr = vim.fn.bufnr(full_path)
    local lines = {}
    if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
        lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    else
        if vim.fn.filereadable(full_path) == 0 then return i18n.t("err_file_not_found_simple") end
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
    vim.notify(i18n.t("edit_applied", full_path), vim.log.levels.INFO)
    return i18n.t("succ_edit_lines", start_line, end_line)
end

M.get_diagnostics = function(path)
    if not path or path == "" or path == "nil" then
        return i18n.t("err_path_req_diag")
    end

    path = vim.trim(path)
    local full_path = resolve_path(path)
    if not full_path then return i18n.t("err_path_invalid") end
    
    local bufnr = vim.fn.bufnr(full_path)
    if bufnr == -1 then
        if vim.fn.filereadable(full_path) == 0 then return i18n.t("err_file_not_found", full_path) end
        bufnr = vim.fn.bufadd(full_path)
        if bufnr == 0 then return i18n.t("err_load_file", full_path) end
        vim.fn.bufload(bufnr)
    end

    local has_lsp = vim.lsp.buf_is_attached and vim.lsp.buf_is_attached(bufnr)
    if not has_lsp then
        local clients = vim.lsp.get_clients and vim.lsp.get_clients({bufnr = bufnr}) or {}
        has_lsp = #clients > 0
    end

    if has_lsp then
        vim.wait(50, function() return false end, 10)
    end

    local diagnostics = vim.diagnostic.get(bufnr)
    if not diagnostics or #diagnostics == 0 then
        if not has_lsp then return i18n.t("warn_no_lsp", full_path) end
        return i18n.t("diag_clean", full_path)
    end

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

    local result = i18n.t("diag_for", full_path) .. table.concat(out_lines, "\n")

    if #result > MAX_BYTES then
        result = result:sub(1, MAX_BYTES) .. i18n.t("diag_trunc_1", #diagnostics, count)
    elseif #diagnostics > MAX_DIAGS then
        result = result .. i18n.t("diag_trunc_2", #diagnostics, MAX_DIAGS)
    end

    return result
end

M.apply_diff = function(path, diff_content)
    local full_path = resolve_path(path)
    if not full_path then return i18n.t("err_path_req") end
    
    local bufnr = vim.fn.bufnr(full_path)
    local lines = {}
    
    if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
        lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        vim.fn.writefile(lines, full_path)
    else
        if vim.fn.filereadable(full_path) == 0 then return i18n.t("err_file_not_found_simple") end
    end
    
    diff_content = diff_content:gsub("\r", "")
    diff_content = diff_content:gsub("^%s*```[%w_]*\n", ""):gsub("\n%s*```%s*$", "")
    
    local tmp_patch = os.tmpname()
    vim.fn.writefile(vim.split(diff_content, "\n", {plain=true}), tmp_patch)
    
    local cmd = string.format("patch --force -u %s -i %s", vim.fn.shellescape(full_path), vim.fn.shellescape(tmp_patch))
    local out = vim.fn.system(cmd)
    local status = vim.v.shell_error
    
    os.remove(tmp_patch)
    os.remove(full_path .. ".orig")
    os.remove(full_path .. ".rej")
    
    if status ~= 0 then return i18n.t("fail_diff", status, out) end
    
    if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
        local new_lines = vim.fn.readfile(full_path)
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)
        vim.api.nvim_buf_call(bufnr, function() vim.cmd("silent! write") end)
    end
    
    vim.notify(i18n.t("diff_applied", full_path), vim.log.levels.INFO)
    return i18n.t("succ_diff", full_path)
end

M.git_status = function()
    local root = get_repo_root()
    if not root then return i18n.t("err_not_git") end
    local out = vim.fn.system("git -C " .. vim.fn.shellescape(root) .. " status -s")
    if vim.v.shell_error ~= 0 then return i18n.t("err_git_status", out) end
    if out == "" then return i18n.t("git_status_clean") end
    return i18n.t("git_status_header") .. out
end

M.git_branch = function(branch_name, create_new)
    local root = get_repo_root()
    if not root then return i18n.t("err_not_git") end
    if not branch_name or branch_name == "" then return i18n.t("err_branch_req") end
    local flag = ""
    if create_new == true or create_new == "true" then flag = "-b " end
    local cmd = string.format("git -C %s checkout %s%s", vim.fn.shellescape(root), flag, vim.fn.shellescape(branch_name))
    local out = vim.fn.system(cmd)
    if vim.v.shell_error ~= 0 then return i18n.t("fail_branch", out) end
    return i18n.t("succ_branch", out)
end

M.git_commit = function(files_str, message)
    local root = get_repo_root()
    if not root then return i18n.t("err_not_git") end
    if not files_str or files_str == "" then return i18n.t("err_files_req") end
    if not message or message == "" then return i18n.t("err_msg_req") end
    
    if files_str:match("^%s*%.%s*$") or files_str:match("%*") or files_str:match("%-A") or files_str:match("%-%-all") then
        return i18n.t("err_git_add_all")
    end
    
    local files = vim.split(files_str, ",", {trimempty=true})
    if #files == 0 then return i18n.t("err_no_valid_files") end
    
    local escaped_files = {}
    for _, f in ipairs(files) do table.insert(escaped_files, vim.fn.shellescape(vim.trim(f))) end
    
    local add_cmd = string.format("git -C %s add %s", vim.fn.shellescape(root), table.concat(escaped_files, " "))
    local add_out = vim.fn.system(add_cmd)
    if vim.v.shell_error ~= 0 then return i18n.t("err_git_add", add_out) end
    
    local commit_cmd = string.format("git -C %s commit -m %s", vim.fn.shellescape(root), vim.fn.shellescape(message))
    local commit_out = vim.fn.system(commit_cmd)
    if vim.v.shell_error ~= 0 then return i18n.t("err_git_commit", commit_out) end
    
    return i18n.t("succ_commit", commit_out)
end


M.get_agents_info = function()
    local agents = require('multi_context.agents').load_agents()
    local out = {"=== AGENTES DISPONÍVEIS E SUAS FERRAMENTAS ==="}
    for name, data in pairs(agents) do
        table.insert(out, "- @" .. name .. " [Nível: " .. (data.abstraction_level or "high") .. "]: " .. table.concat(data.skills or {}, ", "))
    end
    return table.concat(out, "\n")
end

M.get_project_stack = function(buf)
    local root = get_repo_root() or vim.fn.getcwd()
    local out = {"=== PROJECT STACK & ENVIRONMENT ==="}
    
    local os_info = vim.loop.os_uname()
    table.insert(out, "SO: " .. os_info.sysname .. " " .. os_info.release .. " (" .. os_info.machine .. ")")
    table.insert(out, "Shell: " .. vim.o.shell)

    if buf and vim.api.nvim_buf_is_valid(buf) then
        local expandtab = vim.bo[buf].expandtab
        local shiftwidth = vim.bo[buf].shiftwidth
        table.insert(out, "Indentação do Buffer Atual: " .. (expandtab and "Espaços" or "Tabs") .. " (Tamanho: " .. shiftwidth .. ")")

        local clients = vim.lsp.get_clients and vim.lsp.get_clients({bufnr = buf}) or {}
        if #clients > 0 then
            local lsp_names = {}
            for _, c in ipairs(clients) do table.insert(lsp_names, c.name) end
            table.insert(out, "LSP Ativo Neste Arquivo: Sim (" .. table.concat(lsp_names, ", ") .. ")")
        else
            table.insert(out, "LSP Ativo Neste Arquivo: Não")
        end
    end

    local markers = {"Makefile", "package.json", "Cargo.toml", "requirements.txt", "pom.xml", "go.mod", "tests/", "spec/", "docker-compose.yml"}
    local found_markers = {}
    for _, m in ipairs(markers) do
        if vim.fn.glob(root .. "/" .. m) ~= "" then table.insert(found_markers, m) end
    end
    if #found_markers > 0 then
        table.insert(out, "Marcadores de Ecossistema Encontrados: " .. table.concat(found_markers, ", "))
    end

    return table.concat(out, "\n")
end

M.get_git_env = function()
    local root = get_repo_root()
    if not root then return i18n.t("err_not_git") end

    local out = {"=== GIT ENVIRONMENT ==="}
    local branch = vim.fn.system("git -C " .. vim.fn.shellescape(root) .. " branch --show-current"):gsub("\n", "")
    table.insert(out, "Branch atual: " .. (branch == "" and "Detached HEAD" or branch))

    local status_ahead_behind = vim.fn.system("git -C " .. vim.fn.shellescape(root) .. " rev-list --left-right --count origin/" .. branch .. "..." .. branch .. " 2>/dev/null")
    if vim.v.shell_error == 0 then
        local parts = vim.split(status_ahead_behind, "\t")
        if #parts == 2 then
            table.insert(out, "Commits: " .. vim.trim(parts[2]) .. " ahead, " .. vim.trim(parts[1]) .. " behind origin")
        end
    end

    local is_merge = vim.fn.filereadable(root .. "/.git/MERGE_HEAD") == 1
    local is_rebase = vim.fn.isdirectory(root .. "/.git/rebase-merge") == 1 or vim.fn.isdirectory(root .. "/.git/rebase-apply") == 1
    
    if is_merge then table.insert(out, "⚠️ ESTADO CRÍTICO: MERGE EM PROGRESSO (Resolva os conflitos antes de prosseguir)") end
    if is_rebase then table.insert(out, "⚠️ ESTADO CRÍTICO: REBASE EM PROGRESSO") end

    return table.concat(out, "\n")
end

return M
