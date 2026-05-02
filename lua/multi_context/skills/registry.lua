local M = {}

local function get_plugin_base_path()
    local source = debug.getinfo(1, "S").source:sub(2)
    if not source then return nil end
    local base = vim.fn.fnamemodify(source, ":p:h:h:h")
    if vim.fn.fnamemodify(base, ":t") == "lua" then return vim.fn.fnamemodify(base, ":h") end
    return base
end

M.get_skill_doc = function(skill_name)
    local base_path = get_plugin_base_path()
    if not base_path then return nil end
    local skill_file = vim.fn.join({ base_path, "lua", "multi_context", "skills", "docs", skill_name .. ".md" }, "/")
    if vim.fn.filereadable(skill_file) == 0 then
        local curr_file = debug.getinfo(1, "S").source:sub(2)
        skill_file = vim.fn.fnamemodify(curr_file, ":h") .. "/docs/" .. skill_name .. ".md"
    end
    if vim.fn.filereadable(skill_file) == 1 then return table.concat(vim.fn.readfile(skill_file), "\n") end
    return nil
end

M.build_manual_for_skills = function(skills_array)
    local ok, ontology = pcall(require, 'multi_context.ecosystem.skills_ontology')
    if not ok then return "" end
    
    local resolved = ontology.resolve_agent_skills(skills_array)
    if #resolved.raw_tools == 0 then 
        return "\n\n=== SYSTEM TOOLS ===\nWARNING: You currently have NO TOOLS available. Rely entirely on your internal reasoning and the provided context." 
    end
    
    local manual = [[=== SYSTEM TOOLS & SYNTAX (CRITICAL) ===
You are an autonomous machine connected to a Neovim IDE. You have access to the tools below.

CRITICAL RULES:
1. STRICT XML ONLY. Format: <tool_call name="name" attr="val">...</tool_call>
2. NO MARKDOWN WRAPPING. Never wrap your XML in ```xml ... ``` blocks.
3. NO INVENTED TOOLS. Use ONLY the tools explicitly listed below.
4. ONE ACTION PER TURN. Use ONE tool per response to allow the system to process it.
5. AUTO-LSP ACTIVE. The system automatically runs diagnostics after edits. Do not call get_diagnostics manually after saving.]]

    if #resolved.semantic_skills > 0 then
        manual = manual .. "\n\n=== YOUR CAPABILITIES (SKILLS) ==="
        for _, skill in ipairs(resolved.semantic_skills) do
            manual = manual .. "\n- [" .. skill.name .. "]: " .. skill.purpose
        end
    end

    manual = manual .. "\n\n=== ACTIVE TOOLS MANUAL ==="
    for _, tool in ipairs(resolved.raw_tools) do
        local doc = M.get_skill_doc(tool)
        if doc then manual = manual .. "\n" .. doc .. "\n" end
    end
    return manual
end
return M
