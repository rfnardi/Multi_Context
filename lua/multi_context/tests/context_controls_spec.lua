local controls = require('multi_context.ui.context_controls')
local config = require('multi_context.config')
local api = vim.api

local backup_opts
local orig_stdpath
local mock_test_dir = "/tmp/mctx_test_env_" .. tostring(math.random(100000))

local function isolate_environment()
    backup_opts = vim.deepcopy(config.options)
    vim.fn.mkdir(mock_test_dir .. "/mctx_skills", "p")
    vim.fn.mkdir(mock_test_dir .. "/mctx_injectors", "p")
    vim.fn.mkdir(mock_test_dir .. "/.mctx_chats", "p")
    
    orig_stdpath = vim.fn.stdpath
    vim.fn.stdpath = function(what)
        if what == "config" or what == "data" then return mock_test_dir end
        return orig_stdpath(what)
    end
end

local function restore_environment()
    config.options = vim.deepcopy(backup_opts)
    vim.fn.stdpath = orig_stdpath
    vim.fn.delete(mock_test_dir, "rf")
end

describe("Fase 26 - Passo 1: Expansão do Motor Virtual e IAM", function()
    before_each(function()
        isolate_environment()
        package.loaded['multi_context.ui.context_controls'] = nil
        controls = require('multi_context.ui.context_controls')
        controls.reset_state()
        
        config.load_api_config = function()
            return { fallback_mode = true, default_api = "api_A", apis = { { name = "api_A" } } }
        end
        package.loaded['multi_context.agents'] = {
            load_agents = function() return { tech_lead = { skills = {"run_shell"} } } end
        }
        package.loaded['multi_context.ecosystem.skills_manager'] = {
            load_skills = function() end,
            get_skills = function() return { minha_skill = {} } end
        }
    end)
    after_each(restore_environment)

    it("Deve inicializar as novas sessoes e carregar agentes e skills na memoria", function()
        controls.init_state()
        assert.truthy(#controls.state.sections >= 6)
        assert.is_not_nil(controls.state.agents["tech_lead"])
        assert.is_not_nil(controls.state.all_skills["minha_skill"])
    end)

    it("Deve renderizar os botoes de criar Agente e Skill ao expandir as seções", function()
        controls.init_state()
        controls.toggle_section(5) 
        controls.toggle_section(6) 
        local lines = controls.render()
        local str_lines = table.concat(lines, "\n")
        assert.truthy(str_lines:match("%+ Criar Novo Agente"))
        assert.truthy(str_lines:match("%+ Criar Nova Skill"))
        assert.truthy(str_lines:match("%[%+%] tech_lead"))
    end)
    
    it("Deve permitir Drill-down (Expandir um Agente) revelando a arvore de skills", function()
        controls.init_state()
        controls.toggle_section(5)
        controls.state.expanded_agents["tech_lead"] = true
        local lines = controls.render()
        local found = false
        for _, line in ipairs(lines) do
            if line:match("├─ run_shell") and line:match("%[ ✓ %]") then found = true end
        end
        assert.is_true(found)
    end)
end)

describe("Fase 26.1 - Interatividade e Mutação (Toggles e Edição)", function()
    before_each(function()
        isolate_environment()
        package.loaded["multi_context.ui.context_controls"] = nil
        controls = require("multi_context.ui.context_controls")
        controls.reset_state()
        controls.init_state()
        
        controls.state.agents = { coder = { skills = {"read_file"}, abstraction_level = "high" } }
        controls.state.all_skills = { read_file = { name = "read_file", is_native = true }, run_shell = { name = "run_shell", is_native = true } }
    end)
    after_each(restore_environment)

    it("Deve ligar e desligar uma skill do agente ao usar o espaco (handle_space)", function()
        controls.line_map = {
            [1] = { type = "agent_skill_toggle", agent = "coder", skill = "run_shell" },
            [2] = { type = "agent_skill_toggle", agent = "coder", skill = "read_file" }
        }
        local orig_cursor = vim.api.nvim_win_get_cursor
        
        vim.api.nvim_win_get_cursor = function() return {1, 0} end
        controls.handle_space()
        assert.is_true(vim.tbl_contains(controls.state.agents["coder"].skills, "run_shell"))
        
        vim.api.nvim_win_get_cursor = function() return {2, 0} end
        controls.handle_space()
        assert.is_false(vim.tbl_contains(controls.state.agents["coder"].skills, "read_file"))
        
        vim.api.nvim_win_get_cursor = orig_cursor
    end)
    
    it("Deve alterar a Identidade e Limites com a tecla c (handle_edit)", function()
        controls.line_map = {[1] = { type = "limit_identity" }, [2] = { type = "limit_loops" } }
        local orig_cursor = vim.api.nvim_win_get_cursor
        local orig_input = vim.ui.input
        
        vim.api.nvim_win_get_cursor = function() return {1, 0} end
        vim.ui.input = function(opts, cb) cb("DevMaster") end
        controls.handle_edit()
        assert.are.same("DevMaster", controls.state.identity)
        
        vim.api.nvim_win_get_cursor = orig_cursor
        vim.ui.input = orig_input
    end)
end)

describe("Fase 26.2 - Atalhos", function()
    before_each(function()
        isolate_environment()
        package.loaded["multi_context.ui.context_controls"] = nil; controls = require("multi_context.ui.context_controls")
        controls.reset_state(); controls.init_state()
    end)
    after_each(restore_environment)

    it("Deve criar um novo agente via handle_cr no painel", function()
        controls.line_map = { [1] = { type = "create_agent" } }
        local orig_cursor = vim.api.nvim_win_get_cursor
        local orig_input = vim.ui.input
        local orig_save = controls.save_config
        
        vim.api.nvim_win_get_cursor = function() return {1, 0} end
        vim.ui.input = function(opts, cb) cb("arquiteto_teste") end
        controls.save_config = function() end 
        
        controls.handle_cr() 
        assert.is_not_nil(controls.state.agents["arquiteto_teste"])
        
        vim.api.nvim_win_get_cursor = orig_cursor
        vim.ui.input = orig_input
        controls.save_config = orig_save
    end)
end)

describe("Fase A - Refatoracao Visual UX e Footer", function()
    before_each(function()
        isolate_environment()
        package.loaded["multi_context.ui.context_controls"] = nil; controls = require("multi_context.ui.context_controls")
        controls.reset_state(); controls.init_state()
        
        controls.state.sections[1].desc = "(Gerencie chaves...)"
        controls.state.sections[1].expanded = false
        controls.state.sections[2].expanded = true
        controls.state.fallback_mode = true
    end)
    after_each(restore_environment)

    it("Deve renderizar [+] e a descricao para secoes ocultas, e [-] sem descricao para abertas", function()
        local lines = controls.render()
        local str_lines = table.concat(lines, "\n")
        assert.truthy(str_lines:match("%[%+%] %[1%] PROVEDORES"))
        assert.truthy(str_lines:match("%(Gerencie chaves"))
        assert.truthy(str_lines:match("%[%-%] %[2%] ORQUESTRAÇÃO"))
    end)
end)

describe("Fase B a G - Integridade Visual Geral", function()
    before_each(function()
        isolate_environment()
        package.loaded["multi_context.ui.context_controls"] = nil; controls = require("multi_context.ui.context_controls")
        controls.reset_state(); controls.init_state()
    end)
    after_each(restore_environment)

    it("As secoes Injetores, Squads, Aparencia, Historico e Cofre devem ser renderizadas na memoria", function()
        assert.truthy(#controls.state.sections >= 12)
    end)
end)

describe("Fase H - Correcoes UX Avançadas (Edicao, Footer Dinâmico, Agentes e Swarm Levels)", function()
    before_each(function()
        isolate_environment()
        package.loaded["multi_context.ui.context_controls"] = nil
        controls = require("multi_context.ui.context_controls")
        controls.reset_state()
        controls.init_state()
        
        controls.state.apis = { { name = "api_mock", abstraction_level = "medium", allow_spawn = true } }
        controls.state.agents = { tester = { system_prompt = "Sou o tester", abstraction_level = "high", skills = {} } }
    end)
    after_each(restore_environment)

    it("Deve renderizar e permitir alternar o Nivel de Abstracao das APIs no Swarm", function()
        controls.state.sections[2].expanded = true
        local lines = controls.render()
        local str_lines = table.concat(lines, "\n")
        
        assert.truthy(str_lines:match("└─ Abstraction Level"), "Deve exibir a opcao de nivel de abstracao")
        assert.truthy(str_lines:match("%[ medium %]"), "Deve mostrar o nivel atual")

        controls.line_map = { [1] = { type = "api_level_swarm", idx = 1 } }
        local orig_cursor = vim.api.nvim_win_get_cursor
        vim.api.nvim_win_get_cursor = function() return {1, 0} end
        
        controls.handle_space() -- medium vira low
        assert.are.same("low", controls.state.apis[1].abstraction_level)
        
        controls.handle_space() -- low vira high
        assert.are.same("high", controls.state.apis[1].abstraction_level)
        
        vim.api.nvim_win_get_cursor = orig_cursor
    end)

    it("Deve renderizar os botoes de Editar Prompt e Deletar Agente", function()
        controls.state.sections[5].expanded = true
        controls.state.expanded_agents["tester"] = true
        
        local lines = controls.render()
        local str_lines = table.concat(lines, "\n")
        
        assert.truthy(str_lines:match("%[ Editar System Prompt %]"), "Deve exibir botao de editar")
        assert.truthy(str_lines:match("%[ Deletar Agente %]"), "Deve exibir botao de deletar")
    end)

    it("Deve deletar o agente ao confirmar e atualizar o estado", function()
        controls.line_map = { [1] = { type = "delete_agent", name = "tester" } }
        local orig_cursor = vim.api.nvim_win_get_cursor
        local orig_confirm = vim.fn.confirm
        
        vim.api.nvim_win_get_cursor = function() return {1, 0} end
        vim.fn.confirm = function() return 1 end
        
        controls.handle_cr()
        
        assert.is_nil(controls.state.agents["tester"], "O agente deveria ter sido deletado da memoria")
        
        vim.api.nvim_win_get_cursor = orig_cursor
        vim.fn.confirm = orig_confirm
    end)

    it("Abertura de arquivos deve fechar a janela do painel ANTES de dar o edit (evita E37)", function()
        controls.line_map = { [1] = { type = "edit_skill", name = "skill_teste" } }
        controls.state.all_skills = { skill_teste = { is_native = false } }
        vim.fn.writefile({"-- teste"}, mock_test_dir .. "/mctx_skills/skill_teste.lua")
        
        local execution_order = {}
        
        local buf = vim.api.nvim_create_buf(false, true)
        controls.win = vim.api.nvim_open_win(buf, true, {relative='editor', width=10, height=10, row=0, col=0})
        
        vim.api.nvim_create_autocmd("WinClosed", {
            pattern = tostring(controls.win),
            callback = function() table.insert(execution_order, "close") end
        })
        vim.api.nvim_create_autocmd("BufEnter", {
            pattern = "*skill_teste.lua",
            callback = function() table.insert(execution_order, "edit") end
        })
        
        local orig_cursor = vim.api.nvim_win_get_cursor
        vim.api.nvim_win_get_cursor = function() return {1, 0} end
        
        controls.handle_open_file()
        
        assert.are.same("close", execution_order[1], "A janela do painel deve ser fechada PRIMEIRO")
        assert.are.same("edit", execution_order[2], "O comando edit deve ocorrer DEPOIS do fechamento")
        
        vim.api.nvim_win_get_cursor = orig_cursor
    end)

    it("Deve atualizar o footer via nvim_win_set_config de forma dinamica", function()
        local buf = vim.api.nvim_create_buf(false, true)
        controls.win = vim.api.nvim_open_win(buf, true, {relative='editor', width=10, height=10, row=0, col=0, border='rounded'})
        controls.buf = buf
        controls.line_map = { [1] = { type = "toggle_debug" } }
        
        controls.update_footer(1)
        
        local conf = vim.api.nvim_win_get_config(controls.win)
        local has_footer = false
        if conf.footer then has_footer = true end
        
        if vim.fn.has("nvim-0.10") == 1 then
            assert.is_true(has_footer, "Deveria ter atualizado o footer da janela no Neovim 0.10+")
        else
            assert.is_true(true, "Ignorando teste de footer em versão antiga do Nvim")
        end
        pcall(vim.api.nvim_win_close, controls.win, true)
    end)
    
    it("A edicao do prompt de agente deve criar um buffer isolado via arquivo temporario", function()
        controls.line_map = { [1] = { type = "edit_agent_prompt", name = "tester" } }
        
        local buf = vim.api.nvim_create_buf(false, true)
        controls.win = vim.api.nvim_open_win(buf, true, {relative='editor', width=10, height=10, row=0, col=0})
        
        local orig_cursor = vim.api.nvim_win_get_cursor
        vim.api.nvim_win_get_cursor = function() return {1, 0} end
        
        controls.handle_cr()
        
        local win_valid = vim.api.nvim_win_is_valid(controls.win)
        assert.is_false(win_valid, "Deve fechar o painel de controles primeiro")
        
        local current_file = vim.api.nvim_buf_get_name(0)
        assert.truthy(current_file:match("mctx_agent_tester_"), "Deve abrir um arquivo temporario nomeado corretamente")
        
        vim.api.nvim_win_get_cursor = orig_cursor
    end)
end)

describe("Fase 34 - Sincronização de Memória do Watchdog (Bug 1)", function()
    before_each(function()
        isolate_environment()
        package.loaded["multi_context.ui.context_controls"] = nil
        controls = require("multi_context.ui.context_controls")
        controls.reset_state()
        controls.init_state()
    end)
    after_each(restore_environment)

    it("Deve espelhar o limite do watchdog em memória (config.options) ao salvar o painel", function()
        -- 1. Mudamos no UI state (Simulando interação do usuário)
        controls.state.horizon = 150000
        controls.state.watchdog.mode = "auto"
        
        -- 2. Acionamos o salvamento (Aperta <CR> no painel)
        controls.save_config()
        
        -- 3. As opções em RAM do motor principal devem refletir a mudança
        assert.are.same(150000, config.options.cognitive_horizon, "A memória global (config.options.cognitive_horizon) não foi atualizada!")
        assert.are.same("auto", config.options.watchdog.mode, "A memória global (config.options.watchdog.mode) não foi atualizada!")
    end)
end)
