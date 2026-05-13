vim.cmd([[set runtimepath+=. ]])

local plenary_dir = vim.fn.expand("~/.local/share/nvim/plugged/plenary.nvim")
if vim.fn.isdirectory(plenary_dir) == 1 then
    vim.cmd("set runtimepath+=" .. plenary_dir)
end

require('multi_context.config').setup({ user_name = "User", language = "pt-BR" })

-- ========================================================
-- ASYNC BARRIER: Rastreamento Global de Processos Background
-- ========================================================
_G.__mctx_async_count = 0

local orig_schedule = vim.schedule
vim.schedule = function(cb)
    _G.__mctx_async_count = _G.__mctx_async_count + 1
    orig_schedule(function()
        local ok, err = pcall(cb)
        _G.__mctx_async_count = _G.__mctx_async_count - 1
        if not ok then print("\n[Background Error] Schedule: " .. tostring(err)) end
    end)
end

local orig_defer = vim.defer_fn
vim.defer_fn = function(cb, ms)
    _G.__mctx_async_count = _G.__mctx_async_count + 1
    orig_defer(function()
        local ok, err = pcall(cb)
        _G.__mctx_async_count = _G.__mctx_async_count - 1
        if not ok then print("\n[Background Error] Defer: " .. tostring(err)) end
    end, ms)
end

_G.AwaitForBackground = function()
    -- Aguarda o Neovim esvaziar a fila de eventos (Timeout de 2 segundos)
    vim.wait(2000, function() return _G.__mctx_async_count == 0 end, 10)
end
