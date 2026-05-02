local M = {}
M.skills_file = vim.fn.stdpath("config") .. "/mctx_skills_v2.json"

M.load_semantic_skills = function()
    if vim.fn.filereadable(M.skills_file) == 0 then
        local defaults = {
            swarm_orchestration = {
                purpose = "Orchestrate other agents and delegate tasks appropriately.",
                tools = {"spawn_swarm", "get_agents_info"}
            },
            code_refactoring = {
                purpose = "Safely modify existing code using surgical tools.",
                tools = {"read_file", "edit_file", "replace_lines", "apply_diff"}
            },
            code_investigation = {
                purpose = "Explore the codebase to find definitions and references.",
                tools = {"read_file", "search_code", "list_files", "get_project_stack", "lsp_definition", "lsp_references", "lsp_document_symbols"}
            },
            quality_assurance = {
                purpose = "Run tests and checks to guarantee code quality.",
                tools = {"run_shell", "get_diagnostics"}
            },
            git_automation = {
                purpose = "Manage version control, create branches, and execute commits.",
                tools = {"git_status", "git_branch", "git_commit", "get_git_env"}
            }
        }
        vim.fn.writefile({vim.fn.json_encode(defaults)}, M.skills_file)
    end
    
    local file = io.open(M.skills_file, 'r')
    if not file then return {} end
    local content = file:read('*a')
    file:close()
    local ok, parsed = pcall(vim.fn.json_decode, content)
    return ok and parsed or {}
end

M.resolve_agent_skills = function(agent_skills_list)
    local semantics = M.load_semantic_skills()
    local resolved = { semantic_skills = {}, raw_tools = {}, tools_set = {} }
    
    for _, item in ipairs(agent_skills_list or {}) do
        if semantics[item] then
            table.insert(resolved.semantic_skills, { name = item, purpose = semantics[item].purpose })
            for _, t in ipairs(semantics[item].tools or {}) do
                if not resolved.tools_set[t] then
                    resolved.tools_set[t] = true
                    table.insert(resolved.raw_tools, t)
                end
            end
        else
            if not resolved.tools_set[item] then
                table.insert(resolved.semantic_skills, { name = item, purpose = "Direct tool access: " .. item })
                resolved.tools_set[item] = true
                table.insert(resolved.raw_tools, item)
            end
        end
    end
    return resolved
end
return M
