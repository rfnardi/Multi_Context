vim.cmd([[set runtimepath+=. ]])

-- Tenta adicionar Plenary via vim-plug silenciosamente, se existir
local plenary_dir = vim.fn.expand("~/.local/share/nvim/plugged/plenary.nvim")
if vim.fn.isdirectory(plenary_dir) == 1 then
    vim.cmd("set runtimepath+=" .. plenary_dir)
end

require('multi_context.config').setup({ user_name = "Nardi", language = "pt-BR" })






