local M = {}

-- Memória onde as skills carregadas vão ficar
M.skills = {}

M.reset = function()
    M.skills = {}
end

M.load_skills = function(dir_path)
    M.reset()
    -- Se o usuário não passar uma pasta, usamos o padrão ~/.config/nvim/mctx_skills
    if not dir_path then
        dir_path = vim.fn.stdpath("config") .. "/mctx_skills"
    end

    -- Se a pasta não existe, não faz nada
    if vim.fn.isdirectory(dir_path) == 0 then
        return
    end

    -- Encontra todos os arquivos .lua na pasta
    local files = vim.fn.globpath(dir_path, "*.lua", false, true)
    
    for _, file in ipairs(files) do
        -- loadfile compila o arquivo, mas não o executa. Evita crash de sintaxe.
        local chunk, err = loadfile(file)
        if chunk then
            -- pcall executa o arquivo com segurança.
            local ok, result = pcall(chunk)
            
            -- Validação estrita da estrutura da Skill
            if ok and type(result) == "table" then
                if type(result.name) == "string" and result.name ~= "" and type(result.execute) == "function" then
                    M.skills[result.name] = result
                end
            end
        end
    end
end

M.get_skills = function()
    return M.skills
end

return M
