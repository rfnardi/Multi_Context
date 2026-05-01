local M = {}

local function get_plugin_base_path()
    local source = debug.getinfo(1, "S").source:sub(2)
    if not source then return nil end
    local base = vim.fn.fnamemodify(source, ":p:h:h:h")
    if vim.fn.fnamemodify(base, ":t") == "lua" then
        return vim.fn.fnamemodify(base, ":h")
    end
    return base
end

M.get_skill_doc = function(skill_name)
    local base_path = get_plugin_base_path()
    if not base_path then return nil end
    
    local skill_file = vim.fn.join({ base_path, "lua", "multi_context", "skills", "docs", skill_name .. ".md" }, "/")
    
    if vim.fn.filereadable(skill_file) == 0 then
        local curr_file = debug.getinfo(1, "S").source:sub(2)
        local fallback_dir = vim.fn.fnamemodify(curr_file, ":h") .. "/docs/"
        skill_file = fallback_dir .. skill_name .. ".md"
    end
    
    if vim.fn.filereadable(skill_file) == 1 then
        return table.concat(vim.fn.readfile(skill_file), "\n")
    end
    return nil
end

M.build_manual_for_skills = function(skills_array)
    if not skills_array or #skills_array == 0 then 
        return "\n\n=== SYSTEM TOOLS ===\nWARNING: You currently have NO TOOLS available. You cannot read files, edit code, or run commands. Rely entirely on your internal reasoning and the provided context." 
    end
    local manual = [[=== SYSTEM TOOLS & SYNTAX (CRITICAL) ===
You are an autonomous machine connected to a Neovim IDE. You have access to the tools below.

CRITICAL RULES:
1. STRICT XML ONLY. Format: <tool_call name="name" attr="val">...</tool_call>
2. NO MARKDOWN WRAPPING. Never wrap your XML in ```xml ... ``` blocks.
3. NO INVENTED TOOLS. Use ONLY the tools explicitly listed below.
4. ONE ACTION PER TURN. Use ONE tool per response to allow the system to process it.
5. AUTO-LSP ACTIVE. The system automatically runs diagnostics after edits. Do not call get_diagnostics manually after saving.

=== ACTIVE SKILLS ===]]

    for _, skill in ipairs(skills_array) do
        local doc = M.get_skill_doc(skill)
        if doc then
            manual = manual .. "\n" .. doc .. "\n"
        end
    end
    return manual
end

return M
