local M = {}
M.skills = {}

M.reset = function() M.skills = {} end

M.load_skills = function(dir_path)
    M.reset()
    if not dir_path then dir_path = vim.fn.stdpath("config") .. "/mctx_skills" end
    if vim.fn.isdirectory(dir_path) == 0 then return end

    local files = vim.fn.globpath(dir_path, "*", false, true)
    
    for _, file in ipairs(files) do
        if file:match("%.lua$") then
            local chunk, err = loadfile(file)
            if chunk then
                local ok, result = pcall(chunk)
                if ok and type(result) == "table" and type(result.name) == "string" and type(result.execute) == "function" then
                    M.skills[result.name] = result
                end
            end
        elseif vim.fn.executable(file) == 1 then
            -- POLYGLOT SKILL: Script executavel genérico (Bash, Fish, JS, Python)
            local name = vim.fn.fnamemodify(file, ":t:r")
            local desc = "Script externo: " .. name
            local params = {}
            
            local lines = vim.fn.readfile(file, "", 20)
            for _, line in ipairs(lines) do
                local d = line:match("DESC:%s*(.*)")
                if d then desc = vim.trim(d) end
                
                local p_name, p_type, p_req, p_desc = line:match("PARAM:%s*(%S+)%s*|%s*(%S+)%s*|%s*(%S+)%s*|%s*(.*)")
                if p_name then
                    table.insert(params, { 
                        name = vim.trim(p_name), type = vim.trim(p_type), 
                        required = (vim.trim(p_req) == "true"), desc = vim.trim(p_desc) 
                    })
                end
            end
            
            M.skills[name] = {
                name = name,
                description = desc,
                parameters = params,
                execute = function(args)
                    local env_vars = "env "
                    if args then
                        for k, v in pairs(args) do
                            env_vars = env_vars .. string.format("MCTX_%s=%s ", string.upper(k), vim.fn.shellescape(tostring(v)))
                        end
                    end
                    return vim.fn.system(env_vars .. vim.fn.shellescape(file))
                end
            }
        end
    end
end

M.get_skills = function() return M.skills end
return M
