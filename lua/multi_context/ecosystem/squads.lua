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
