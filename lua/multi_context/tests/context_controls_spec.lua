local controls = require('multi_context.context_controls')
local config = require('multi_context.config')
local api = vim.api

describe("Fase 26 - Passo 1: Expansão do Motor Virtual e IAM", function()
    before_each(function()
        package.loaded['multi_context.context_controls'] = nil
        controls = require('multi_context.context_controls')
        controls.reset_state()
        
        -- Mock for APIs and Agents
        config.load_api_config = function()
            return { fallback_mode = true, default_api = "api_A", apis = { { name = "api_A" } } }
        end
        package.loaded['multi_context.agents'] = {
            load_agents = function() return { tech_lead = { skills = {"run_shell"} } } end
        }
        package.loaded['multi_context.skills_manager'] = {
            load_skills = function() end,
            get_skills = function() return { minha_skill = {} } end
        }
    end)

    it("Deve inicializar as novas sessoes e carregar agentes e skills na memoria", function()
        controls.init_state()
        assert.are.same(6, #controls.state.sections, "Devem existir 6 sessoes no painel agora")
        assert.is_not_nil(controls.state.agents["tech_lead"], "Os agentes devem ser carregados no estado")
        assert.is_not_nil(controls.state.all_skills["minha_skill"], "Skills customizadas devem aparecer")
        assert.is_not_nil(controls.state.all_skills["apply_diff"], "Skills nativas injetadas devem aparecer")
    end)

    it("Deve renderizar os botoes de criar Agente e Skill ao expandir as seções", function()
        controls.init_state()
        
        controls.toggle_section(5) -- Gatekeeper
        controls.toggle_section(6) -- Skills
        
        local lines = controls.render()
        local found_new_agent = false
        local found_new_skill = false
        local found_tech_lead = false
        
        for _, line in ipairs(lines) do
            if line:match("%+ Criar Novo Agente") then found_new_agent = true end
            if line:match("%+ Criar Nova Skill") then found_new_skill = true end
            if line:match("▶ tech_lead") then found_tech_lead = true end
        end
        
        assert.is_true(found_new_agent, "O botão virtual de novo agente deve ser renderizado")
        assert.is_true(found_new_skill, "O botão virtual de nova skill deve ser renderizado")
        assert.is_true(found_tech_lead, "O agente existente deve aparecer listado")
    end)
    
    it("Deve permitir Drill-down (Expandir um Agente) revelando a arvore de skills", function()
        controls.init_state()
        controls.toggle_section(5)
        
        -- Simulando que o usuario apertou <CR> em cima do tech_lead
        controls.state.expanded_agents["tech_lead"] = true
        
        local lines = controls.render()
        local found_run_shell = false
        
        for _, line in ipairs(lines) do
            if line:match("├─ run_shell") and line:match("●") then found_run_shell = true end
        end
        
        assert.is_true(found_run_shell, "Ao expandir, deve listar as skills e marcar com um dot as que o agente possui")
    end)
end)

describe("Fase 26.1 - Interatividade e Mutação (Toggles e Edição)", function()
    local controls = require('multi_context.context_controls')

    before_each(function()
        controls.reset_state()
        controls.init_state()
        
        -- Estado base simulado para o teste
        controls.state.agents = {
            coder = { skills = {"read_file"}, abstraction_level = "high" }
        }
        controls.state.all_skills = {
            read_file = { name = "read_file", is_native = true },
            run_shell = { name = "run_shell", is_native = true }
        }
    end)

    it("Deve ligar e desligar uma skill do agente ao usar o espaco (handle_space)", function()
        -- Simulando a renderizacao virtual em duas linhas do painel
        controls.line_map = {
            [1] = { type = "agent_skill_toggle", agent = "coder", skill = "run_shell" },
            [2] = { type = "agent_skill_toggle", agent = "coder", skill = "read_file" }
        }
        
        local orig_cursor = vim.api.nvim_win_get_cursor
        
        -- Mock: Usuário está na linha 1
        vim.api.nvim_win_get_cursor = function() return {1, 0} end
        controls.handle_space() -- Pressionou espaço!
        
        local has_run_shell = false
        for _, s in ipairs(controls.state.agents["coder"].skills) do
            if s == "run_shell" then has_run_shell = true end
        end
        assert.is_true(has_run_shell, "A skill run_shell deve ter sido adicionada a matriz de permissoes")
        
        -- Mock: Usuário está na linha 2 (A skill read_file ja existe pro coder)
        vim.api.nvim_win_get_cursor = function() return {2, 0} end
        controls.handle_space() -- Pressionou espaço!
        
        local has_read_file = false
        for _, s in ipairs(controls.state.agents["coder"].skills) do
            if s == "read_file" then has_read_file = true end
        end
        assert.is_false(has_read_file, "A skill read_file deve ter sido removida da matriz de permissoes")
        
        -- Cleanup
        vim.api.nvim_win_get_cursor = orig_cursor
    end)
    
    it("Deve alterar a Identidade e Limites com a tecla c (handle_edit)", function()
        controls.line_map = {[1] = { type = "limit_identity" },
            [2] = { type = "limit_loops" }
        }
        
        local orig_cursor = vim.api.nvim_win_get_cursor
        local orig_input = vim.ui.input
        
        -- Simulando o usuário editando a Identidade
        vim.api.nvim_win_get_cursor = function() return {1, 0} end
        vim.ui.input = function(opts, cb) cb("DevMaster") end
        
        controls.handle_edit()
        assert.are.same("DevMaster", controls.state.identity)
        
        -- Simulando o usuário editando o limite de loops ReAct
        vim.api.nvim_win_get_cursor = function() return {2, 0} end
        vim.ui.input = function(opts, cb) cb("42") end
        
        controls.handle_edit()
        assert.are.same(42, controls.state.max_loops)
        
        -- Cleanup
        vim.api.nvim_win_get_cursor = orig_cursor
        vim.ui.input = orig_input
    end)
end)

describe("Fase 26.2 - Modo de Criacao e Atalhos", function()
    local controls = require('multi_context.context_controls')

    before_each(function()
        controls.reset_state()
        controls.init_state()
    end)

    it("Deve criar um novo agente via handle_cr no painel", function()
        controls.line_map = {
            [1] = { type = "create_agent" }
        }
        
        local orig_cursor = vim.api.nvim_win_get_cursor
        local orig_input = vim.ui.input
        local orig_save = controls.save_config
        
        -- Mocks
        vim.api.nvim_win_get_cursor = function() return {1, 0} end
        vim.ui.input = function(opts, cb) cb("arquiteto_teste") end
        controls.save_config = function() end -- Nao sobrescreve o json real durante o teste
        
        controls.handle_cr() -- Pressionou enter sobre a opcao [+ Criar Novo Agente]
        
        assert.is_not_nil(controls.state.agents["arquiteto_teste"], "A nova persona deve ser adicionada no estado em memoria")
        assert.are.same("high", controls.state.agents["arquiteto_teste"].abstraction_level, "O default deve ser high")
        
        -- Cleanup
        vim.api.nvim_win_get_cursor = orig_cursor
        vim.ui.input = orig_input
        controls.save_config = orig_save
    end)
end)
