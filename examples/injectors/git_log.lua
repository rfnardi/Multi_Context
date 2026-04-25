return {
    name = "git_log",
    description = "Lista os últimos 10 commits (oneline) do Git",
    execute = function()
        local root = vim.fn.system("git rev-parse --show-toplevel")
        if vim.v.shell_error ~= 0 then return "ERRO: Não é um repositório git." end
        root = root:gsub("\n", "")
        
        local log = vim.fn.system("git -C " .. vim.fn.shellescape(root) .. " log -n 10 --oneline")
        return "=== ÚLTIMOS 10 COMMITS ===\n" .. log
    end
}
