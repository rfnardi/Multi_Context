local assert = require("luassert")
local config = require("multi_context.config")
local utils = require("multi_context.utils.utils")
local session = require("multi_context.core.session")
local controls = require("multi_context.ui.controls_view")
local chat_view = require("multi_context.ui.chat_view")

describe("Fase 45.1 e 45.2 - Ecossistema de Contexto Vivo (CONTEXT.md)", function()
    before_each(function()
        config.setup({
            auto_inject_context_md = true
        })
        session.clear()
        controls.reset_state()
    end)

    describe("45.1: Configuração e UI (controls_view & i18n)", function()
        it("deve inicializar auto_inject_context_md como true por padrão", function()
            assert.is_true(config.options.auto_inject_context_md)
        end)

        it("deve exibir o toggle 'Auto-Inject CONTEXT.md' no painel de controle (Seção Limits)", function()
            controls.init_state()
            controls.state.auto_inject_context_md = true
            
            -- Força a expansão da seção limits
            for _, sec in ipairs(controls.state.sections) do
                if sec.id == "limits" then
                    sec.expanded = true
                end
            end
            
            local lines = controls.render()
            local found = false
            for _, line in ipairs(lines) do
                if line:match("Auto%-Inject CONTEXT") and line:match("%[%s*ON%s*%]") then
                    found = true
                    break
                end
            end
            assert.is_true(found, "O toggle 'Auto-Inject CONTEXT.md' não foi renderizado corretamente na UI.")
        end)
    end)

    describe("45.2: utils.lua - Resolução do CONTEXT.md", function()
        it("deve localizar e retornar o caminho absoluto do CONTEXT.md", function()
            local old_system = vim.fn.system
            vim.fn.system = function(cmd)
                if cmd:match("git rev%-parse") then return "/fake/repo/root\n" end
                return ""
            end
            local old_filereadable = vim.fn.filereadable
            vim.fn.filereadable = function(path)
                if path == "/fake/repo/root/CONTEXT.md" then return 1 end
                return 0
            end

            local path = utils.get_context_md_path()
            assert.are.equal("/fake/repo/root/CONTEXT.md", path)

            vim.fn.system = old_system
            vim.fn.filereadable = old_filereadable
        end)
    end)

    describe("45.2: session.lua - Injeção Silenciosa na AST", function()
        it("deve anexar o conteúdo do CONTEXT.md no build_payload como mensagem system", function()
            local old_path_fn = utils.get_context_md_path
            utils.get_context_md_path = function() return "/fake/CONTEXT.md" end
            
            local old_readfile = vim.fn.readfile
            vim.fn.readfile = function(p)
                if p == "/fake/CONTEXT.md" then return {"# Fake Context", "Regra 1: TDD"} end
                return {}
            end

            session.add_message("user", "Implemente a API", {})
            local payload = session.build_payload("Prompt Base.")

            local found_context = false
            for _, msg in ipairs(payload) do
                if msg.role == "system" and msg.content:match("Regra 1: TDD") then
                    found_context = true
                    break
                end
            end

            assert.is_true(found_context, "O conteúdo do CONTEXT.md não foi injetado silenciosamente no LLM payload.")

            utils.get_context_md_path = old_path_fn
            vim.fn.readfile = old_readfile
        end)
    end)

    describe("45.2: chat_view.lua - Indicador Visual no Popup", function()
        it("deve incluir o indicador visual '[📖 CONTEXT.md: Active]' no título da janela", function()
            local old_path_fn = utils.get_context_md_path
            utils.get_context_md_path = function() return "/fake/CONTEXT.md" end
            
            -- Simula a janela
            local buf, win = chat_view.create_popup("")
            chat_view.update_title()

            local conf = vim.api.nvim_win_get_config(win)
            assert.is_not_nil(conf.title, "O popup deveria ter um título.")
            
            local title_str = type(conf.title) == "table" and conf.title[1][1] or conf.title
            assert.is_truthy(title_str:match("%[📖 CONTEXT%.md: Active%]"), "O título não contém a badge de contexto ativo.")

            utils.get_context_md_path = old_path_fn
            pcall(vim.api.nvim_win_close, win, true)
            pcall(vim.api.nvim_buf_delete, buf, {force=true})
        end)
    end)
end)
