local commands = require('multi_context.commands')
local popup = require('multi_context.ui.chat_view')
local StateManager = require('multi_context.core.state_manager')

describe("Fase 37 - TEMA 4: Entrypoints e Comandos do Usuário", function()
    local orig_create_popup
    local captured_content = nil

    before_each(function()
        captured_content = nil
        orig_create_popup = popup.create_popup
        
        popup.create_popup = function(content)
            captured_content = content
            return 999, 999 -- Mocks para buf e win
        end
        
        -- Garante que o Neovim tenha um buffer válido
        local b = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_set_current_buf(b)
    end)

    after_each(function()
        popup.create_popup = orig_create_popup
    end)

    it("ContextFolder deve chamar create_popup com a tag de diretório atual", function()
        commands.ContextChatFolder()
        assert.is_not_nil(captured_content)
        assert.truthy(captured_content:match("CONTEÚDO DA PASTA ATUAL"), "O conteúdo injetado deve conter o cabeçalho da pasta")
    end)

    it("ContextRepo deve injetar a tag de todo o repositório", function()
        commands.ContextChatRepo()
        assert.is_not_nil(captured_content)
        assert.truthy(captured_content:match("=== CONTEÚDO DE TODO O REPOSITÓRIO GIT ===") or captured_content:match("Não é um repositório Git"), "Deve tentar injetar o contexto do repositório")
    end)

    it("ContextGit deve injetar a tag de diff do git", function()
        commands.ContextChatGit()
        assert.is_not_nil(captured_content)
        assert.truthy(captured_content:match("GIT DIFF") or captured_content:match("Não é um repositório Git"), "Deve tentar injetar o diff")
    end)

    it("ContextTree deve injetar a árvore de arquivos", function()
        commands.ContextTree()
        assert.is_not_nil(captured_content)
        assert.truthy(captured_content:match("=== TREE E CONTEÚDO ==="), "Deve injetar a árvore")
    end)

    it("ContextBuffers deve injetar o conteudo de todos os buffers", function()
        commands.ContextBuffers()
        assert.is_not_nil(captured_content)
    end)

    it("ContextChatFull deve abrir um chat totalmente limpo", function()
        commands.ContextChatFull()
        assert.are.same("", captured_content, "ContextChatFull deve passar uma string vazia para iniciar limpo")
    end)

    it("ContextChatHandler com selecao visual envia o trecho", function()
        local buf = vim.api.nvim_get_current_buf()
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"Line 1", "Line 2", "Line 3"})
        commands.ContextChatHandler(1, 2)
        assert.is_not_nil(captured_content)
        assert.truthy(captured_content:match("SELEÇÃO"), "Deve capturar a seleção visual")
    end)
end)

describe("Fase 37 - TEMA 4: Desfazer Seguro (ContextUndo)", function()
    local main = require('multi_context')
    local popup = require('multi_context.ui.chat_view')
    local orig_notify
    local notifications = {}

    before_each(function()
        notifications = {}
        orig_notify = vim.notify
        vim.notify = function(msg, level)
            table.insert(notifications, msg)
        end
        
        popup.popup_buf = vim.api.nvim_create_buf(false, true)
        StateManager.get('react').last_backup = nil
    end)

    after_each(function()
        vim.notify = orig_notify
    end)

    it("Se NÃO houver backup, ContextUndo emite aviso e não quebra", function()
        assert.has_no.errors(function()
            main.ContextUndo()
        end)
        assert.are.same(1, #notifications)
        assert.truthy(notifications[1]:match("Nenhum backup de compressão encontrado"), "Deve avisar o usuário graciosamente")
    end)

    it("Se houver backup, ContextUndo restaura o conteúdo no buffer", function()
        StateManager.get('react').last_backup = {"Linha 1 do Backup", "Linha 2 do Backup"}
        
        main.ContextUndo()
        
        local lines = vim.api.nvim_buf_get_lines(popup.popup_buf, 0, -1, false)
        assert.are.same("Linha 1 do Backup", lines[1])
        assert.are.same("Linha 2 do Backup", lines[2])
        
        local success_msg_found = false
        for _, msg in ipairs(notifications) do
            if msg:match("Chat restaurado") then success_msg_found = true end
        end
        assert.is_true(success_msg_found, "Deve emitir mensagem de sucesso")
    end)
end)

describe("Fase 37 - TEMA 4: TogglePopup", function()
    local commands = require('multi_context.commands')
    local popup = require('multi_context.ui.chat_view')
    local orig_hide

    before_each(function()
        orig_hide = vim.api.nvim_win_hide
    end)

    after_each(function()
        vim.api.nvim_win_hide = orig_hide
    end)

    it("Deve esconder a janela se ela estiver aberta e válida", function()
        local hide_called = false
        vim.api.nvim_win_hide = function(win) hide_called = true end
        
        popup.popup_win = vim.api.nvim_open_win(vim.api.nvim_create_buf(false, true), false, {relative="editor", width=10, height=10, row=0, col=0})
        
        commands.TogglePopup()
        
        assert.is_true(hide_called, "A janela deve ser escondida (nvim_win_hide)")
        pcall(vim.api.nvim_win_close, popup.popup_win, true)
    end)
    
    it("Deve abrir janela se popup_buf existir mas win for nil", function()
        popup.popup_win = nil
        popup.popup_buf = vim.api.nvim_create_buf(false, true)
        
        commands.TogglePopup()
        assert.is_not_nil(popup.popup_win)
        
        pcall(vim.api.nvim_win_close, popup.popup_win, true)
    end)
end)
