local M = {}
local StateManager = require('multi_context.core.state_manager')
local i18n = require('multi_context.i18n')

local EXTENSION_MAP = {
    ["rs"] = "rust_analyzer",
    ["py"] = "pyright",
    ["go"] = "gopls",
    ["ts"] = "ts_ls",
    ["tsx"] = "ts_ls",
    ["js"] = "ts_ls",
    ["jsx"] = "ts_ls",
    ["lua"] = "lua_ls",
    ["c"] = "clangd",
    ["cpp"] = "clangd",
    ["cs"] = "omnisharp",
    ["java"] = "jdtls",
    ["php"] = "intelephense",
    ["rb"] = "solargraph",
    ["html"] = "html",
    ["css"] = "cssls"
}

M._get_lsp_name = function(path)
    local ext = path:match("^.+%.(.+)$")
    if not ext then return nil end
    return EXTENSION_MAP[ext]
end

M.ensure_lsp_for_file = function(path)
    if not path or path == "" then return false end
    
    local lsp_name = M._get_lsp_name(path)
    if not lsp_name then return false end -- Linguagem não mapeada
    
    local state = StateManager.get('react')
    if not state.rejected_lsps then state.rejected_lsps = {} end
    
    -- JIT Gatekeeper: Usuário já recusou antes?
    if state.rejected_lsps[lsp_name] then return false end

    -- Degradation Graceful: Tem Mason instalado?
    local has_mason, registry = pcall(require, "mason-registry")
    if not has_mason then return false end

    local ok, pkg = pcall(function() return registry.get_package(lsp_name) end)
    if not ok or not pkg then return false end

    -- Já está instalado? Segue o jogo.
    if pkg:is_installed() then return true end

    -- Interceptação! Pausa a IA e pergunta ao usuário
    local filename = vim.fn.fnamemodify(path, ":t")
    local msg = i18n.t("lsp_prompt_install", filename, lsp_name)
    local choice = vim.fn.confirm(msg, i18n.t("confirm_opts"):gsub("&Todos\n", ""), 1)

    -- Se escolheu "Não" (2) ou Cancelou (0)
    if choice == 2 or choice == 0 then
        state.rejected_lsps[lsp_name] = true
        return false
    end

    -- Inicia instalação via Mason
    vim.notify(i18n.t("lsp_installing", lsp_name), vim.log.levels.INFO)
    pkg:install()

    -- Segura o Event Loop sincronamente (mas permitindo background jobs do Mason rodarem)
    -- Timeout de 60 segundos
    vim.wait(60000, function() return pkg:is_installed() end, 200, false)

    if pkg:is_installed() then
        vim.notify(i18n.t("lsp_installed", lsp_name), vim.log.levels.INFO)
        -- Tenta forçar o attachment recarregando o buffer se ele existir
        local bufnr = vim.fn.bufnr(path)
        if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
            vim.api.nvim_buf_call(bufnr, function()
                vim.cmd("silent! doautocmd BufReadPost " .. vim.fn.fnameescape(path))
            end)
        end
        return true
    else
        vim.notify(i18n.t("lsp_failed", lsp_name), vim.log.levels.ERROR)
        return false
    end
end

return M
