-- lua/multi_context/skills/registry.lua
local M = {}

M.get_skill_doc = function(skill_name)
    local curr_file = debug.getinfo(1, "S").source:sub(2)
    local docs_dir = vim.fn.fnamemodify(curr_file, ":h") .. "/docs/"
    local skill_file = docs_dir .. skill_name .. ".md"
    
    if vim.fn.filereadable(skill_file) == 1 then
        return table.concat(vim.fn.readfile(skill_file), "\n")
    end
    return nil
end

M.build_manual_for_skills = function(skills_array)
    if not skills_array or #skills_array == 0 then return "" end
    
    local manual = [[
=== FERRAMENTAS DO SISTEMA (SYSTEM TOOLS) ===
Você é um Agente Autônomo rodando nativamente dentro do editor Neovim do usuário.

REGRA ABSOLUTA DE FORMATO:
Para invocar uma ferramenta, você DEVE usar ESTRITAMENTE o formato de tags XML exemplificado abaixo. É ESTRITAMENTE PROIBIDO usar formato JSON. NÃO ENVOLVA os argumentos com tags extras.

=== SMART PUSH (AUTO-LSP) ===
Sempre que usar ferramentas de edição, a geração de texto será pausada e o sistema injetará automaticamente os erros sintáticos (LSP). NÃO CHAME get_diagnostics logo após editar, leia a resposta do sistema.

=== HABILIDADES ATIVAS (SKILLS) ===
Você tem permissão exclusiva para usar apenas as ferramentas abaixo:
]]
    
    for _, skill in ipairs(skills_array) do
        local doc = M.get_skill_doc(skill)
        if doc then manual = manual .. "\n" .. doc .. "\n" end
    end
    
    return manual
end

return M
