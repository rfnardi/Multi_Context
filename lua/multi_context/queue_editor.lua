-- lua/multi_context/queue_editor.lua
-- Buffer interativo para reordenar a fila de APIs e alternar allow_spawn (dd/p para mover, <Space> para alternar, :w para salvar).
local api = vim.api
local M   = {}

M.open_editor = function()
    local config = require('multi_context.config')
    local cfg    = config.load_api_config()
    if not cfg then
        vim.notify("Configuração não encontrada.", vim.log.levels.ERROR)
        return
    end

    local lines_out = {}
    for _, a in ipairs(cfg.apis) do
        local box = a.allow_spawn and "[x]" or "[ ]"
        table.insert(lines_out, box .. " " .. a.name)
    end

    local buf = api.nvim_create_buf(false, true)
    api.nvim_buf_set_lines(buf, 0, -1, false, lines_out)

    -- buftype 'acwrite' permite :w sem arquivo físico (evita E32)
    vim.bo[buf].buftype = 'acwrite'
    api.nvim_buf_set_name(buf, "MultiContext_Queue_Editor")

    local height = math.min(#lines_out + 2, 20)
    local win    = api.nvim_open_win(buf, true, {
        relative  = 'editor',
        width     = 58,
        height    = height,
        row       = 5,
        col       = 10,
        border    = 'rounded',
        title     = ' Ordenar Fila (<Space> spawn · dd/p mover · :w salvar) ',
        title_pos = 'center',
    })

    api.nvim_create_autocmd("BufWriteCmd", {
        buffer   = buf,
        callback = function()
            local lines     = api.nvim_buf_get_lines(buf, 0, -1, false)
            local reordered = {}
            for _, line in ipairs(lines) do
                local is_spawn = line:match("%[x%]") ~= nil
                local name = line:match("%[%s*x?%s*%]%s*(.*)")
                
                if name then
                    name = vim.trim(name)
                    for _, a in ipairs(cfg.apis) do
                        if a.name == name then
                            local new_a = vim.deepcopy(a)
                            new_a.allow_spawn = is_spawn
                            table.insert(reordered, new_a)
                            break
                        end
                    end
                end
            end
            
            cfg.apis = reordered
            if config.save_api_config(cfg) then
                vim.notify("Fila salva!", vim.log.levels.INFO)
                vim.bo[buf].modified = false
                api.nvim_win_close(win, true)
            else
                vim.notify("Erro ao salvar.", vim.log.levels.ERROR)
            end
        end,
    })

    api.nvim_buf_set_keymap(buf, "n", "q", ":q!<CR>", { noremap = true, silent = true })
    api.nvim_buf_set_keymap(buf, "n", "<Space>", "<Cmd>lua require('multi_context.queue_editor').toggle_spawn()<CR>", { noremap = true, silent = true })
end

M.toggle_spawn = function()
    local buf = api.nvim_get_current_buf()
    local row = api.nvim_win_get_cursor(0)[1] - 1
    local line = api.nvim_buf_get_lines(buf, row, row + 1, false)[1]
    
    if not line then return end

    if line:match("%[x%]") then
        line = line:gsub("%[x%]", "[ ]", 1)
    elseif line:match("%[%s*%]") then
        line = line:gsub("%[%s*%]", "[x]", 1)
    end

    api.nvim_buf_set_lines(buf, row, row + 1, false, { line })
end

return M
