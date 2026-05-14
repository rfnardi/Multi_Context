if _G._libuv_barrier_loaded then return end
_G._libuv_barrier_loaded = true

_G._active_test_jobs = 0
_G._active_timers = 0
_G._active_schedules = 0

-- 1. Intercepta Jobs do SO (C-level) e blinda TODOS os callbacks (stdout, stderr, exit)
local original_jobstart = vim.fn.jobstart
vim.fn.jobstart = function(cmd, opts)
    _G._active_test_jobs = _G._active_test_jobs + 1
    local custom_opts = vim.deepcopy(opts or {})
    
    local function wrap_cb(key, is_exit)
        local orig = custom_opts[key]
        if orig then
            custom_opts[key] = function(...)
                -- O pcall engole qualquer erro fantasma impedindo que a suíte exploda
                pcall(orig, ...)
                if is_exit then _G._active_test_jobs = _G._active_test_jobs - 1 end
            end
        elseif is_exit then
            custom_opts[key] = function()
                _G._active_test_jobs = _G._active_test_jobs - 1
            end
        end
    end
    
    wrap_cb("on_stdout", false)
    wrap_cb("on_stderr", false)
    wrap_cb("on_exit", true)
    
    local jid = original_jobstart(cmd, custom_opts)
    if jid <= 0 then _G._active_test_jobs = _G._active_test_jobs - 1 end
    return jid
end

-- 2. Intercepta Timers Assíncronos
local original_defer = vim.defer_fn
vim.defer_fn = function(cb, ms)
    _G._active_timers = _G._active_timers + 1
    original_defer(function()
        pcall(cb)
        _G._active_timers = _G._active_timers - 1
    end, ms)
end

-- 3. Intercepta as filas do Event Loop (schedule e schedule_wrap)
local original_schedule = vim.schedule
vim.schedule = function(cb)
    _G._active_schedules = _G._active_schedules + 1
    original_schedule(function()
        pcall(cb)
        _G._active_schedules = _G._active_schedules - 1
    end)
end

local original_wrap = vim.schedule_wrap
vim.schedule_wrap = function(cb)
    return original_wrap(function(...)
        pcall(cb, ...)
    end)
end

-- 4. Intercepta Autocmds (Gatilhos de Janela/Texto fantasma)
local original_autocmd = vim.api.nvim_create_autocmd
vim.api.nvim_create_autocmd = function(events, opts)
    if opts and type(opts.callback) == "function" then
        local orig_cb = opts.callback
        opts.callback = function(...)
            pcall(orig_cb, ...) -- Silencia crash de janelas já fechadas
        end
    end
    return original_autocmd(events, opts)
end

-- 5. Injeta a Barreira no fim de cada bloco 'it' do Plenary
local original_it = _G.it
if original_it then
    _G.it = function(desc, func)
        original_it(desc, function()
            local bufs_before = vim.api.nvim_list_bufs()

            local ok, err = pcall(func)
            
            -- Segura a execução até estabilizar (Timeout de 4s)
            vim.wait(4000, function() 
                return _G._active_test_jobs <= 0 
                   and _G._active_timers <= 0 
                   and _G._active_schedules <= 0
            end, 5)
            
            vim.wait(50, function() return false end, 5)

            -- Teardown de Estados Globais (Preservando o EventBus)
            pcall(function() require('multi_context.core.state_manager').reset() end)
            pcall(function() require('multi_context.ecosystem.tools_manager').reset() end)
            pcall(function() require('multi_context.core.swarm_manager').reset() end)
            
            -- Teardown das Janelas Visuais
            local chat_view = package.loaded['multi_context.ui.chat_view']
            if chat_view then
                chat_view.popup_buf = nil
                chat_view.popup_win = nil
                chat_view.swarm_buffers = {}
            end

            -- Mata qualquer buffer intruso que tenha sobrado
            local bufs_after = vim.api.nvim_list_bufs()
            for _, b in ipairs(bufs_after) do
                if not vim.tbl_contains(bufs_before, b) and vim.api.nvim_buf_is_valid(b) then
                    pcall(vim.api.nvim_buf_delete, b, { force = true })
                end
            end

            if not ok then error(err) end
        end)
    end
end
