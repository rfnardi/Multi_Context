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
            system_prompt = "You are the Tech Lead. Your ONLY purpose is to orchestrate the swarm. YOU MUST NOT answer in plain text or Markdown tables. YOU MUST STRICTLY AND ONLY use the <tool_call name=\"spawn_swarm\"> XML tag to delegate tasks. Any other format is a catastrophic failure.", 
            abstraction_level = "high", 
            skills = {"spawn_swarm", "read_file", "search_code"} 
        }
        changed = true 
    end
    
    if not parsed["architect"] then 
        parsed["architect"] = { 
            system_prompt = "You are the Software Architect. Focus on system design, ensuring SOLID principles, DRY, modularity, and high cohesion/low coupling. Your main task is to analyze requirements and output strictly structured, step-by-step implementation plans heavily oriented towards Test-Driven Development (TDD). Do not write production code yourself; write the architectural blueprints and test specifications.", 
            abstraction_level = "high", 
            skills = {"read_file", "search_code", "list_files"} 
        }
        changed = true 
    end

    if not parsed["coder"] then 
        parsed["coder"] = { 
            system_prompt = "You are a Senior Software Engineer. Implement features and fix bugs based on architectural blueprints or direct requests. Write clean, efficient, and well-documented code. Follow TDD practices strictly when specified. Use your tools to apply surgical edits to the codebase.", 
            abstraction_level = "high", 
            skills = {"read_file", "edit_file", "replace_lines", "apply_diff", "search_code"} 
        }
        changed = true 
    end

    if not parsed["qa"] then 
        parsed["qa"] = { 
            system_prompt = "You are a Quality Assurance Engineer and Code Reviewer. Critically review code for edge cases, security vulnerabilities, and performance bottlenecks. Run tests, verify LSP diagnostics, and ensure the code meets the highest quality standards before concluding your task.", 
            abstraction_level = "high", 
            skills = {"read_file", "run_shell", "get_diagnostics", "search_code"} 
        }
        changed = true 
    end

    if not parsed["devops"] then 
        parsed["devops"] = { 
            system_prompt = "You are the DevOps and Git Automation Engineer. Handle version control cleanly and surgically. Evaluate diffs, create logical branches, and craft pure Semantic Commits. Work atomically and document all Git operations structurally in your final report.", 
            abstraction_level = "high", 
            skills = {"git_status", "git_branch", "git_commit", "run_shell", "read_file"} 
        }
        changed = true 
    end

    if changed then vim.fn.writefile({vim.fn.json_encode(parsed)}, agents_file) end
    for _, agent in pairs(parsed) do if not agent.abstraction_level then agent.abstraction_level = "high" end end
    return parsed
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
    M.api_list = M.get_agent_names()
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
    local name = M.filtered_list[M.current_selection]
    M._close_win_only()
    if M.parent_win and api.nvim_win_is_valid(M.parent_win) then
        api.nvim_set_current_win(M.parent_win)
        local row, col = unpack(api.nvim_win_get_cursor(0))
        local line = api.nvim_get_current_line()
        local new_line = string.sub(line, 1, col + 1) .. name .. string.sub(line, col + 2)
        api.nvim_set_current_line(new_line)
        api.nvim_win_set_cursor(0, {row, col + 1 + #name})
        api.nvim_feedkeys("a", "n", true)
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
        api.nvim_feedkeys("a", "n", true) 
    end
end

return M
