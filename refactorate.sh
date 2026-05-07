cat << 'EOF' > fix_final_fold.lua
local file = "lua/multi_context/ui/chat_view.lua"
local content = table.concat(vim.fn.readfile(file), "\n")

-- Localiza cirurgicamente o início e fim da função
local func_start = content:find("function M%.create_folds%(buf%)")
local func_end = content:find("function M%.update_title%(%)")

if func_start and func_end then
    local before = content:sub(1, func_start - 1)
    local after = content:sub(func_end)
    
    local new_func = [[
function M.create_folds(buf)
    if not buf or not vim.api.nvim_buf_is_valid(buf) then return end
    vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(buf) then return end
        local windows = vim.fn.win_findbuf(buf)
        for _, win in ipairs(windows) do
            if vim.api.nvim_win_is_valid(win) then
                vim.api.nvim_win_call(win, function()
                    vim.wo.foldmethod = "manual"
                    vim.wo.foldenable = true
                    vim.wo.foldtext = "v:lua.require('multi_context.ui.chat_view').fold_text()"
                    pcall(vim.cmd, 'normal! zE')

                    local total_lines = vim.api.nvim_buf_line_count(buf)
                    local fold_stack = {}
                    local fold_cmds = {}

                    for lnum = 1, total_lines do
                        local line = vim.api.nvim_buf_get_lines(buf, lnum - 1, lnum, false)[1]
                        if line then
                            if line:match('<block.-status="archived"') then
                                table.insert(fold_stack, { type = "block", start = lnum })
                            elseif line:match('<abstract>') then
                                table.insert(fold_stack, { type = "abstract", start = lnum })
                            end
                            
                            if line:match('</block>') then
                                for i = #fold_stack, 1, -1 do
                                    if fold_stack[i].type == "block" then
                                        local start_fold = fold_stack[i].start
                                        if lnum > start_fold then
                                            table.insert(fold_cmds, string.format("%d,%dfold", start_fold, lnum))
                                            table.insert(fold_cmds, string.format("%dfoldclose", start_fold))
                                        end
                                        table.remove(fold_stack, i)
                                        break
                                    end
                                end
                            elseif line:match('</abstract>') then
                                for i = #fold_stack, 1, -1 do
                                    if fold_stack[i].type == "abstract" then
                                        local start_fold = fold_stack[i].start
                                        if lnum > start_fold then
                                            table.insert(fold_cmds, string.format("%d,%dfold", start_fold, lnum))
                                            table.insert(fold_cmds, string.format("%dfoldclose", start_fold))
                                        end
                                        table.remove(fold_stack, i)
                                        break
                                    end
                                end
                            end
                        end
                    end
                    
                    -- Agrupa dezenas de dobras em uma única execução em C para performance extrema
                    if #fold_cmds > 0 then
                        pcall(vim.cmd, table.concat(fold_cmds, " | "))
                    end

                    local win_height = vim.api.nvim_win_get_height(win)
                    local target_scrolloff = math.floor(win_height / 3)
                    local current_so = vim.wo.scrolloff
                    vim.wo.scrolloff = target_scrolloff
                    pcall(vim.cmd, "normal! zb")
                    vim.wo.scrolloff = current_so
                end)
            end
        end
    end)
end

]]
    local final_content = before .. new_func .. after
    vim.fn.writefile(vim.split(final_content, "\n"), file)
    print("Função create_folds reescrita com sucesso!")
else
    print("ERRO: Não encontrou os limites da função no arquivo.")
end
EOF

nvim --headless -c "luafile fix_final_fold.lua" -c "q"
rm fix_final_fold.lua
