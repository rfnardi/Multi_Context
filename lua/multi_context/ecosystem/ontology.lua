local M = {}
M.skills_file = vim.fn.stdpath("config") .. "/mctx_semantic_skills.json"

M.load_semantic_skills = function()
    local defaults = {
        swarm_orchestration = {
            purpose = "CAPABILITY: Agentic Task Decomposition & Swarm Routing.\nTRIGGER: Use exclusively when a complex task requires multiple steps, parallel execution, or specialized knowledge.\nPROTOCOL: Inspect available agents (Workforce Matrix) and route the workload precisely. Do not hoard tasks. You are an orchestrator, not a worker.",
            tools = {"spawn_swarm", "get_agents_info"}
        },
        code_refactoring = {
            purpose = "CAPABILITY: Surgical Code Manipulation & File I/O.\nTRIGGER: Use to alter, append, or delete source code within the local file system.\nPROTOCOL: You are strictly forbidden from guessing file structures. If you do not know the exact line numbers, read the file first. Prioritize minimal `replace_lines` over full file overwrites to prevent syntax corruption and save token bandwidth.",
            tools = {"read_file", "edit_file", "replace_lines", "apply_diff"}
        },
        code_investigation = {
            purpose = "CAPABILITY: Deep Codebase Reconnaissance & Semantic RAG (LSP/Ripgrep).\nTRIGGER: Use immediately upon receiving a task to map unknowns before acting.\nPROTOCOL: Query the Language Server Protocol (LSP) for definitions and references to map blast radius before changing critical functions. Understand the OS and stack context to avoid environment conflicts.",
            tools = {"read_file", "search_code", "list_files", "get_project_stack", "lsp_definition", "lsp_references", "lsp_document_symbols"}
        },
        quality_assurance = {
            purpose = "CAPABILITY: Sandboxed Execution & Diagnostic Validation.\nTRIGGER: Use to prove code correctness dynamically.\nPROTOCOL: Run shell commands to execute test runners (pytest, jest, cargo test). Always query LSP diagnostics after a coder edits a file to ensure zero syntax regressions.",
            tools = {"run_shell", "get_diagnostics"}
        },
        git_automation = {
            purpose = "CAPABILITY: Repository State & Version Control Management.\nTRIGGER: Use to snapshot safe codebase states or branch workflows.\nPROTOCOL: Always assess the environment (`get_git_env`) for active rebases or merge conflicts before acting. Execute granular, deterministic version control operations.",
            tools = {"git_status", "git_branch", "git_commit", "get_git_env"}
        },
        manage_project_knowledge = {
            purpose = "CAPABILITY: Long Term Memory & Project Heuristics.\nTRIGGER: Use when you discover a chronic bug, make an architectural decision, or establish a new standard.\nPROTOCOL: Edit the CONTEXT.md file surgically using update_context_md.",
            tools = {"update_context_md"}
        }
    }
    if vim.fn.filereadable(M.skills_file) == 0 then
        vim.fn.writefile({vim.fn.json_encode(defaults)}, M.skills_file)
        return defaults
    end
    local file = io.open(M.skills_file, 'r')
    if not file then return defaults end
    local content = file:read('*a')
    file:close()
    local ok, parsed = pcall(vim.fn.json_decode, content)
    if not ok or type(parsed) ~= 'table' then return defaults end
    local changed = false
    for k, v in pairs(defaults) do
        if not parsed[k] then
            parsed[k] = v
            changed = true
        end
    end
    if changed then vim.fn.writefile({vim.fn.json_encode(parsed)}, M.skills_file) end
    return parsed
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
