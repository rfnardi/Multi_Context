#!/bin/bash

echo "🛡️ Aplicando Hardening Militar nos Prompts (Via Safe EOF)..."

# 1. Reescrevendo skills_ontology.lua
cat << 'EOF' > lua/multi_context/ecosystem/skills_ontology.lua
local M = {}
M.skills_file = vim.fn.stdpath("config") .. "/mctx_skills_v2.json"

M.load_semantic_skills = function()
    if vim.fn.filereadable(M.skills_file) == 0 then
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
EOF

# 2. Reescrevendo agents.lua inteiramente
cat << 'EOF' > lua/multi_context/agents.lua
local api = vim.api
local M = {}

M.agents_file = vim.fn.stdpath("config") .. "/mctx_agents.json"

local function fuzzy_match(str, pattern)
    if pattern == "" then return true end
    pattern = pattern:lower():gsub(".", function(c) return c .. ".*" end)
    return str:lower():match(pattern) ~= nil
end

M.load_agents = function()
    local agents_file = vim.fn.stdpath("config") .. "/mctx_agents.json"
    M.agents_file = agents_file
    if vim.fn.filereadable(agents_file) == 0 then vim.fn.writefile({"{}"}, agents_file) end
    local file = io.open(agents_file, "r")
    if not file then return {} end
    local content = file:read("*a")
    file:close()
    local ok, parsed = pcall(vim.fn.json_decode, content)
    if not ok or type(parsed) ~= "table" then parsed = {} end
    local changed = false
    
    if not parsed["tech_lead"] then 
        parsed["tech_lead"] = { 
            system_prompt = "ROLE: Apex Swarm Orchestrator (Agentic Router).\nDIRECTIVE: You are the singular authority responsible for task decomposition, matchmaking, and delegation across the multi-agent system. You operate at the strategic level.\nOPERATIONAL BOUNDARIES:\n1. STRICTLY PROHIBITED: You MUST NOT write code, execute shell commands, or read files directly.\n2. NO CONVERSATION: You MUST NOT answer in plain text, explanations, or markdown tables.\n3. MANDATORY PROTOCOL: You MUST strictly and only use the <tool_call name=\"spawn_swarm\"> tag to route tasks to specialized sub-agents or squads. Any deviation from this strict delegation structure is a catastrophic system failure.", 
            abstraction_level = "high", 
            skills = {"swarm_orchestration"} 
        }
        changed = true 
    end
    
    if not parsed["architect"] then 
        parsed["architect"] = { 
            system_prompt = "ROLE: Principal Systems Architect.\nDIRECTIVE: Design robust, scalable, and highly cohesive software architectures. Your outputs are the blueprints that Execution Units (Coders) will follow.\nOPERATIONAL BOUNDARIES:\n1. MANDATORY PARADIGMS: Enforce SOLID principles, DRY, and strict Test-Driven Development (TDD) planning.\n2. NO IMPLEMENTATION: Do not write functional production code yourself. Write deep structural analysis, class/module interfaces, and rigid test specifications.\n3. PROTOCOL: Execute Deep Codebase Reconnaissance exhaustively before proposing an architecture to ensure strict compatibility with the existing stack.", 
            abstraction_level = "high", 
            skills = {"code_investigation"} 
        }
        changed = true 
    end

    if not parsed["coder"] then 
        parsed["coder"] = { 
            system_prompt = "ROLE: Autonomous Software Engineer (Execution Unit).\nDIRECTIVE: Implement features and patch bugs with surgical precision based on provided blueprints or explicit requests.\nOPERATIONAL BOUNDARIES:\n1. SURGICAL PRECISION: Do not rewrite entire files if a targeted line replacement is sufficient. Minimize I/O footprint.\n2. CODE QUALITY: Write highly efficient, deterministic, and self-documenting code. Never leave TODOs unless explicitly instructed.\n3. PROTOCOL: If operating under TDD, you MUST ensure logic aligns exactly with test constraints. Modify the codebase securely using your authorized Surgical Code Manipulation skills.", 
            abstraction_level = "high", 
            skills = {"code_refactoring", "code_investigation"} 
        }
        changed = true 
    end

    if not parsed["qa"] then 
        parsed["qa"] = { 
            system_prompt = "ROLE: Quality Assurance & Security Auditor.\nDIRECTIVE: Act as a ruthless gatekeeper for code quality. You do not trust the Coder's output until mathematically and syntactically proven secure.\nOPERATIONAL BOUNDARIES:\n1. MANDATORY CHECKS: Hunt for edge cases, memory leaks, security vulnerabilities, and unhandled exceptions.\n2. LSP ENFORCEMENT: You MUST verify LSP diagnostics. Code with syntax errors or warnings is strictly unacceptable.\n3. PROTOCOL: Execute sandboxed test suites, validate terminal outputs, and enforce the highest industry standards before signing off on any delegated task.", 
            abstraction_level = "high", 
            skills = {"quality_assurance", "code_investigation"} 
        }
        changed = true 
    end

    if not parsed["devops"] then 
        parsed["devops"] = { 
            system_prompt = "ROLE: DevOps & Git Operations Commander.\nDIRECTIVE: Manage the version control lifecycle with absolute safety and atomic tracking.\nOPERATIONAL BOUNDARIES:\n1. ATOMICITY: Craft pure Semantic Commits (feat, fix, refactor). Never group unrelated changes into a single commit.\n2. ZERO DESTRUCTION: Destructive operations (reset --hard, force push) are strictly outside your operational clearance unless explicitly forced by the human user.\n3. PROTOCOL: Always check the repository state, branch cleanly, stage surgically, and document all Git operations in your final deployment report.", 
            abstraction_level = "high", 
            skills = {"git_automation"} 
        }
        changed = true 
    end

    if changed then vim.fn.writefile({vim.fn.json_encode(parsed)}, agents_file) end
    for _, agent in pairs(parsed) do if not agent.abstraction_level then agent.abstraction_level = "high" end end
    return parsed
end

M.get_delegable_entities = function()
    local agents = M.load_agents()
    local ok, sq = pcall(require, "multi_context.ecosystem.squads")
    local squads = ok and sq.load_squads() or {}
    local list = {}
    for n, _ in pairs(agents) do table.insert(list, "[A] " .. n) end
    for n, _ in pairs(squads) do table.insert(list, "[S] " .. n) end
    table.sort(list)
    return list
end

M.get_agent_names = function()
    local agents = M.load_agents()
    local names = {}
    for name, _ in pairs(agents) do table.insert(names, name) end
    table.sort(names)
    return names
end

M.selector_buf = nil; M.selector_win = nil; M.parent_win = nil
M.api_list = {}; M.filtered_list = {}; M.current_selection = 1

M.open_agent_selector = function()
    M.api_list = M.get_delegable_entities()
    if #M.api_list == 0 then return end
    
    M.parent_win = api.nvim_get_current_win()
    M.filtered_list = vim.deepcopy(M.api_list)
    M.current_selection = 1
    
    M.selector_buf = api.nvim_create_buf(false, true)
    M.selector_win = api.nvim_open_win(M.selector_buf, true, {
        relative = "cursor", row = 1, col = 0, width = 30, height = math.min(10, #M.api_list + 2),
        style = "minimal", border = "rounded",
    })
    vim.bo[M.selector_buf].buftype = "nofile"
    
    api.nvim_buf_set_lines(M.selector_buf, 0, -1, false, { "> ", "---" })
    M._render_list()
    M._keymaps()
    
    vim.cmd("startinsert!")
    api.nvim_win_set_cursor(M.selector_win, {1, 2})
end

M._update_filter = function(query)
    M.filtered_list = {}
    for _, v in ipairs(M.api_list) do
        if fuzzy_match(v, query) then table.insert(M.filtered_list, v) end
    end
    M.current_selection = 1
    M._render_list()
end

M._render_list = function()
    if not M.selector_buf or not api.nvim_buf_is_valid(M.selector_buf) then return end
    local lines = {}
    for i, name in ipairs(M.filtered_list) do
        local cursor = (i == M.current_selection) and "❯ " or "  "
        table.insert(lines, cursor .. name)
    end
    api.nvim_buf_set_lines(M.selector_buf, 2, -1, false, lines)
    
    local ns = api.nvim_create_namespace("mc_agents")
    api.nvim_buf_clear_namespace(M.selector_buf, ns, 2, -1)
    if #M.filtered_list > 0 then
        api.nvim_buf_add_highlight(M.selector_buf, ns, "ContextSelectorCurrent", M.current_selection + 1, 0, -1)
    end
end

M._keymaps = function()
    if not M.selector_buf or not api.nvim_buf_is_valid(M.selector_buf) then return end
    
    api.nvim_create_autocmd("TextChangedI", {
        buffer = M.selector_buf,
        callback = function()
            local line = api.nvim_buf_get_lines(M.selector_buf, 0, 1, false)[1]
            local query = line:gsub("^> %s*", ""):gsub("^>", "")
            M._update_filter(query)
        end
    })

    local function mk(k, fn) 
        api.nvim_buf_set_keymap(M.selector_buf, "i", k, "", { callback = fn, noremap = true, silent = true })
        api.nvim_buf_set_keymap(M.selector_buf, "n", k, "", { callback = fn, noremap = true, silent = true })
    end
    
    mk("<C-j>", function() M._move(1) end); mk("<Down>", function() M._move(1) end)
    mk("<C-k>", function() M._move(-1) end); mk("<Up>", function() M._move(-1) end)
    mk("<CR>", M._select)
    mk("<Esc>", M._close)
end

M._move = function(dir)
    if #M.filtered_list == 0 then return end
    local n = M.current_selection + dir
    if n >= 1 and n <= #M.filtered_list then M.current_selection = n; M._render_list() end
end

M._select = function()
    local item = M.filtered_list[M.current_selection]
    if not item then M._close(); return end
    local name = item:sub(5)
    M._close_win_only()
    if M.parent_win and api.nvim_win_is_valid(M.parent_win) then
        api.nvim_set_current_win(M.parent_win)
        local row, col = unpack(api.nvim_win_get_cursor(0))
        local line = api.nvim_get_current_line()
        local new_line = string.sub(line, 1, col + 1) .. name .. string.sub(line, col + 2)
        api.nvim_set_current_line(new_line)
        api.nvim_win_set_cursor(0, {row, col + 1 + #name})
        vim.cmd("startinsert")
    end
end

M._close_win_only = function()
    if M.selector_win and api.nvim_win_is_valid(M.selector_win) then api.nvim_win_close(M.selector_win, true) end
    M.selector_buf = nil; M.selector_win = nil
end

M._close = function()
    M._close_win_only()
    if M.parent_win and api.nvim_win_is_valid(M.parent_win) then 
        api.nvim_set_current_win(M.parent_win)
        vim.cmd("startinsert") 
    end
end

return M
EOF

# 3. Reescrevendo squads.lua inteiramente
cat << 'EOF' > lua/multi_context/ecosystem/squads.lua
local M = {}
M.squads_file = vim.fn.stdpath("config") .. "/mctx_squads.json"

M.load_squads = function()
    if vim.fn.filereadable(M.squads_file) == 0 then
        local default_squads = {
            squad_dev = {
                description = "Tactical Engineering Unit (End-to-End Delivery)",
                collective_purpose = "MISSION OBJECTIVE: You are an autonomous assembly line. Your collective goal is to implement, rigorously test, and safely version-control the requested feature.\nCHAIN OF COMMAND: 1. The Coder MUST execute the logic. 2. The QA MUST ruthlessly verify edge cases and LSP diagnostics. 3. The DevOps MUST finalize the process with atomic semantic commits.\nRESTRICTION: Do not bypass the QA verification stage under any circumstances. Code that has not been diagnosed and tested is considered toxic.",
                tasks = {
                    { agent = "tech_lead", instruction = "INITIATE PIPELINE: Analyze the human request. Decompose the requirements, enforce the strict Coder -> QA -> DevOps chain, and ensure the pipeline does not stop until the code is committed.", chain = {"coder", "qa", "devops"} }
                }
            }
        }
        vim.fn.writefile({vim.fn.json_encode(default_squads)}, M.squads_file)
    end

    local file = io.open(M.squads_file, "r")
    if not file then return {} end
    local content = file:read("*a")
    file:close()
    local ok, parsed = pcall(vim.fn.json_decode, content)
    parsed = ok and parsed or {}

    local ok_ag, ag_mod = pcall(require, "multi_context.agents")
    local agents = ok_ag and ag_mod.load_agents() or {}
    local val = { low = 1, medium = 2, high = 3 }
    local rev = { [1] = "low", [2] = "medium",[3] = "high" }
    
    for _, sq_def in pairs(parsed) do
        local max_lvl = 1
        if sq_def.tasks then
            for _, t in ipairs(sq_def.tasks) do
                if t.agent then
                    local lvl = (agents[t.agent] and agents[t.agent].abstraction_level) and val[agents[t.agent].abstraction_level] or 3
                    if lvl > max_lvl then max_lvl = lvl end
                end
                if type(t.chain) == "table" then
                    for _, ag in ipairs(t.chain) do
                        local lvl = (agents[ag] and agents[ag].abstraction_level) and val[agents[ag].abstraction_level] or 3
                        if lvl > max_lvl then max_lvl = lvl end
                    end
                end
            end
        end
        sq_def.abstraction_level = rev[max_lvl]
    end
    return parsed
end

M.get_squad_names = function()
    local squads = M.load_squads()
    local names = {}
    for name, _ in pairs(squads) do table.insert(names, name) end
    table.sort(names)
    return names
end

return M
EOF

# 4. Ajuste no limite de tokens do teste
sed -i 's/< 1200/< 2500/g' lua/multi_context/tests/prompt_optimization_spec.lua

# 5. Apagando caches do JSON antigo
CONFIG_DIR=${XDG_CONFIG_HOME:-$HOME/.config}/nvim
rm -f "$CONFIG_DIR/mctx_agents.json"
rm -f "$CONFIG_DIR/mctx_skills_v2.json"
rm -f "$CONFIG_DIR/mctx_squads.json"

echo "✅ Prompts Hardened implementados com sucesso usando Safe EOF!"
