local api = vim.api
local M = {}

M.define_groups = function()
    vim.cmd("highlight default ContextHeader gui=bold guifg=#FF4500 guibg=NONE")
    vim.cmd("highlight default ContextCurrentBuffer gui=bold guifg=#FFA500 guibg=NONE")
    vim.cmd("highlight default ContextUpdateMessages gui=bold guifg=#FFA500 guibg=NONE")
    vim.cmd("highlight default ContextBoldText gui=bold guifg=#FFA500 guibg=NONE")
    vim.cmd("highlight default ContextApiInfo gui=bold guifg=#FFA500 guibg=NONE")
    
    vim.cmd("highlight default link ContextUITitle ContextApiInfo")
    vim.cmd("highlight default link ContextUISection ContextHeader")
    vim.cmd("highlight default link ContextUIActive ContextBoldText")
    vim.cmd("highlight default link ContextUIData ContextBoldText")

    vim.cmd("highlight default ContextUser gui=bold guifg=#B22222 guibg=NONE")
    vim.cmd("highlight default link ContextUIInactive ContextUser")

    vim.cmd("highlight default ContextUserAI gui=bold guifg=#0000CD guibg=NONE")

    vim.cmd("highlight default ContextUIHelp guifg=#696969 guibg=NONE")
    vim.cmd("highlight default ContextUIDot guifg=#404040 guibg=NONE")
end

M.apply_chat = function(buf)
    if not api.nvim_buf_is_valid(buf) then return end
    vim.api.nvim_buf_call(buf, function()
        M.define_groups()
        vim.cmd("syntax match ContextHeader '^===.*'")
        vim.cmd("syntax match ContextHeader '^== Arquivo:.*'")
        vim.cmd("syntax match ContextCurrentBuffer '^## buffer atual ##'")
        vim.cmd("syntax match ContextUpdateMessages '\\[mensagem enviada\\]'")
        vim.cmd("syntax match ContextUpdateMessages '\\[Enviando requisição.*\\]'")
        vim.cmd("syntax match ContextUser '^## .* >>.*'")
        vim.cmd("syntax match ContextUserAI '^## IA.*'")
        vim.cmd("syntax match ContextApiInfo '^## API atual:.*'")
        vim.cmd("syntax region ContextCodeBlock start='^```' end='^```'")
        vim.cmd("highlight default link ContextCodeBlock String")
        vim.cmd("syntax region ContextBold matchgroup=ContextBoldText start='\\*\\*' end='\\*\\*'")
        vim.cmd("highlight default link ContextBold ContextBoldText")
        
        -- FASE 42.5: Ocultação de XML via Conceal
        vim.cmd("syntax match ContextBlockTag \"<block[^>]*>\" conceal")
        vim.cmd("syntax match ContextBlockEndTag \"</block>\" conceal")
    end)
end

M.apply_controls = function(buf)
    if not api.nvim_buf_is_valid(buf) then return end
    vim.api.nvim_buf_call(buf, function()
        M.define_groups()
        vim.cmd("syntax clear")
        vim.cmd("syntax match ContextUITitle '^===.*==='")
        vim.cmd("syntax match ContextUITitle 'MultiContext AI.*'")
        vim.cmd("syntax match ContextUIHelp '^.*<CR>.*<Space>.*'")
        vim.cmd("syntax match ContextUIHelp '^.*Use j/k para navegar.*'")
        vim.cmd("syntax match ContextUISection '^▶.*'")
        vim.cmd("syntax match ContextUISection '^▼.*'")
        vim.cmd("syntax match ContextUIDot '\\.\\.\\.*'")
        vim.cmd("syntax match ContextUIDot '··*'")
        vim.cmd("syntax match ContextUIActive '●'")
        vim.cmd("syntax match ContextUIActive '\\[ ON \\]'")
        vim.cmd("syntax match ContextUIActive '\\[ ✓ \\]'")
        vim.cmd("syntax match ContextUIActive '\\[ Ask \\]'")
        vim.cmd("syntax match ContextUIActive '\\[ Auto \\]'")
        vim.cmd("syntax match ContextUIActive '\\[ Semântico \\]'")
        vim.cmd("syntax match ContextUIActive '\\[ Percentual \\]'")
        vim.cmd("syntax match ContextUIActive '\\[ Fixo \\]'")
        vim.cmd("syntax match ContextUIActive '\\[ Dinâmico \\]'")
        vim.cmd("syntax match ContextUIInactive '○'")
        vim.cmd("syntax match ContextUIInactive '\\[ OFF \\]'")
        vim.cmd("syntax match ContextUIInactive '\\[   \\]'")
        vim.cmd("syntax match ContextUIInactive '\\[ Off \\]'")
        vim.cmd("syntax match ContextUIData '\\d\\+ tokens'")
        vim.cmd("syntax match ContextUIData '\\d\\+%%'")
        vim.cmd("syntax match ContextUIData '1\\.\\d\\+'")
    end)
end

return M
