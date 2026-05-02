local M = {}
M.squads_file = vim.fn.stdpath("config") .. "/mctx_squads.json"

M.load_squads = function()
    if vim.fn.filereadable(M.squads_file) == 0 then
        local default_squads = {
            squad_dev = {
                description = "Esquadrao padrao de desenvolvimento e qualidade",
                tasks = {
                    { agent = "tech_lead", instruction = "Orquestre o desenvolvimento.", chain = {"coder", "qa"} }
                }
            }
        }
        vim.fn.writefile({vim.fn.json_encode(default_squads)}, M.squads_file)
    end

    local file = io.open(M.squads_file, 'r')
    if not file then return {} end
    local content = file:read('*a')
    file:close()
    local ok, parsed = pcall(vim.fn.json_decode, content)
    parsed = ok and parsed or {}

    local ok_ag, ag_mod = pcall(require, 'multi_context.agents')
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
