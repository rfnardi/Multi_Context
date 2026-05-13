local controls = require('multi_context.ui.controls_view')
local config = require('multi_context.config')
local agents = require('multi_context.agents')
local tools_manager = require('multi_context.ecosystem.tools_manager')
local ontology = require('multi_context.ecosystem.ontology')
local api = vim.api

local backup_opts
local orig_stdpath
local mock_test_dir = "/tmp/mctx_test_env_" .. tostring(math.random(100000))

local orig_load_api_config, orig_load_agents, orig_load_tools, orig_get_tools, orig_load_semantic_skills

local function isolate_environment()
    backup_opts = vim.deepcopy(config.options)
    config.options.config_path = mock_test_dir .. "/context_apis.json"
    config.options.api_keys_path = mock_test_dir .. "/api_keys.json"
    vim.fn.mkdir(mock_test_dir .. "/mctx_tools", "p")
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

local function setup_mocks()
    isolate_environment()
    
    orig_load_api_config = config.load_api_config
    config.load_api_config = function()
        return { fallback_mode = true, default_api = "api_A", apis = { { name = "api_A" } } }
    end

    orig_load_agents = agents.load_agents
    agents.load_agents = function() return { tech_lead = { skills = {"run_shell"} }, coder = { skills = {"read_file"}, abstraction_level = "high" } } end

    orig_load_tools = tools_manager.load_tools
    orig_get_tools = tools_manager.get_tools
    tools_manager.load_tools = function() end
    tools_manager.get_tools = function() return { minha_skill = { name = "minha_skill", is_native = false }, read_file = { name = "read_file", is_native = true }, run_shell = { name = "run_shell", is_native = true } } end

    orig_load_semantic_skills = ontology.load_semantic_skills
    ontology.load_semantic_skills = function() return { code_refactoring = { purpose = "Refatorar codigo com seguranca.", tools = {"read_file", "edit_file"} } } end
    
    controls.reset_state()
end

local function teardown_mocks()
    config.load_api_config = orig_load_api_config
    agents.load_agents = orig_load_agents
    tools_manager.load_tools = orig_load_tools
    tools_manager.get_tools = orig_get_tools
    ontology.load_semantic_skills = orig_load_semantic_skills
    restore_environment()
end

describe("Fase 26 - Passo 1: Expansão do Motor Virtual e IAM", function()
    before_each(setup_mocks)
    after_each(teardown_mocks)

    it("Deve inicializar as novas sessoes e carregar agentes e skills na memoria", function()
        controls.init_state()
        assert.truthy(#controls.state.sections >= 6)
        assert.is_not_nil(controls.state.agents["tech_lead"])
        assert.is_not_nil(controls.state.all_tools["minha_skill"])
    end)

    it("Deve renderizar os botoes de criar Agente e Skill ao expandir as seções", function()
        controls.init_state()
        controls.toggle_section(5) 
        controls.toggle_section(6) 
        local lines = controls.render()
        local str_lines = table.concat(lines, "\n")
        assert.truthy(str_lines:match("%+ Criar Novo Agente"))
        assert.truthy(str_lines:match("Criar Nova Skill Sem"))
        assert.truthy(str_lines:match("%[%+%] tech_lead"))
    end)
    
    it("Deve permitir Drill-down (Expandir um Agente) revelando a arvore de skills", function()
        controls.init_state()
        controls.state.sections[5].expanded = true
        controls.state.expanded_agents["tech_lead"] = true
        
        local lines = controls.render()
        local found = false
        for _, line in ipairs(lines) do
            if line:match("├─ code_refactoring") then found = true end
        end
        assert.is_true(found, "Gatekeeper deve listar a skill semantica")
    end)
end)

describe("Fase 26.1 - Interatividade e Mutação (Toggles e Edição)", function()
    before_each(setup_mocks)
    after_each(teardown_mocks)

    it("Deve ligar e desligar uma skill do agente ao usar o espaco (handle_space)", function()
        controls.init_state()
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
        controls.init_state()
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
    before_each(setup_mocks)
    after_each(teardown_mocks)

    it("Deve criar um novo agente via handle_cr no painel", function()
        controls.init_state()
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

describe("Fase A a G - UI, Rendering, Footer", function()
    before_each(setup_mocks)
    after_each(teardown_mocks)

    it("Deve renderizar [+] e a descricao para secoes ocultas, e [-] sem descricao para abertas", function()
        controls.init_state()
        controls.state.sections[1].desc = "(Gerencie chaves...)"
        controls.state.sections[1].expanded = false
        controls.state.sections[2].expanded = true
        
        local lines = controls.render()
        local str_lines = table.concat(lines, "\n")
        assert.truthy(str_lines:match("%[%+%] %[1%] PROVEDORES"))
        assert.truthy(str_lines:match("%(Gerencie chaves"))
        assert.truthy(str_lines:match("%[%-%] %[2%] ORQUESTRAÇÃO"))
    end)

    it("As secoes Injetores, Squads, Aparencia, Historico e Cofre devem ser renderizadas na memoria", function()
        controls.init_state()
        assert.truthy(#controls.state.sections >= 12)
    end)
end)

describe("Fase H - Correcoes UX Avançadas (Edicao, Footer Dinâmico, Agentes)", function()
    before_each(setup_mocks)
    after_each(teardown_mocks)

    it("Deve renderizar e permitir alternar o Nivel de Abstracao das APIs no Swarm", function()
        controls.init_state()
        controls.state.apis = { { name = "api_mock", abstraction_level = "medium", allow_spawn = true } }
        controls.state.sections[2].expanded = true
        
        local lines = controls.render()
        local str_lines = table.concat(lines, "\n")
        
        assert.truthy(str_lines:match("└─ Abstraction Level"), "Deve exibir a opcao de nivel de abstracao")

        controls.line_map = { [1] = { type = "api_level_swarm", idx = 1 } }
        local orig_cursor = vim.api.nvim_win_get_cursor
        vim.api.nvim_win_get_cursor = function() return {1, 0} end
        
        controls.handle_space() -- medium vira low
        assert.are.same("low", controls.state.apis[1].abstraction_level)
        
        vim.api.nvim_win_get_cursor = orig_cursor
    end)

    it("Deve deletar o agente ao confirmar e atualizar o estado", function()
        controls.init_state()
        controls.state.agents = { tester = { system_prompt = "Sou o tester", abstraction_level = "high", skills = {} } }
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

    it("Abertura de arquivos deve fechar a janela do painel ANTES de dar o edit", function()
        controls.init_state()
        controls.line_map = { [1] = { type = "edit_tool", name = "skill_teste" } }
        controls.state.all_tools = { skill_teste = { is_native = false } }
        vim.fn.writefile({"-- teste"}, mock_test_dir .. "/mctx_tools/skill_teste.lua")
        
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
        
        vim.api.nvim_win_get_cursor = orig_cursor
    end)
end)

describe("Fase 41 - UI Semantica (MoA e MCP)", function()
    before_each(setup_mocks)
    after_each(teardown_mocks)

    it("Contrato 3.1 e 3.2: Deve permitir toggle state na memoria (Mutadores)", function()
        controls.init_state()
        controls.state.agents = { coder = { skills = {} } }
        controls.state.semantic_skills = { code_refactoring = { tools = {} } }
        
        -- Toggle skill no agente
        controls.line_map = { [1] = { type = "agent_skill_toggle", agent = "coder", skill = "code_investigation" } }
        local orig_cursor = vim.api.nvim_win_get_cursor
        vim.api.nvim_win_get_cursor = function() return {1, 0} end
        controls.handle_space()
        assert.is_true(vim.tbl_contains(controls.state.agents["coder"].skills, "code_investigation"))

        -- Toggle tool na skill semantica
        controls.line_map = { [1] = { type = "semantic_skill_tool_toggle", skill = "code_refactoring", tool = "run_shell" } }
        controls.handle_space()
        assert.is_true(vim.tbl_contains(controls.state.semantic_skills["code_refactoring"].tools, "run_shell"))
        
        vim.api.nvim_win_get_cursor = orig_cursor
    end)
end)
